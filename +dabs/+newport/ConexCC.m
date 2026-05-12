%% ConexCC, an async driver for single stage Newport Conex-CC motor controller
% Author: Nelson Downs

classdef ConexCC < dabs.resources.devices.MotorController & dynamicprops ...
        & dabs.resources.configuration.HasConfigPage & most.HasMachineDataFile
    %% ABSTRACT PROPERTY REALIZATIONS
    % most.HasMachineDataFile
    properties (Constant, Hidden)
        %Value-Required properties
        mdfClassName = mfilename('class');
        mdfHeading = 'ConexCC Linear Stage Driver';
        
        %Value-Optional properties
        mdfDependsOnClasses; %#ok<MCCPI>
        mdfDirectProp;       %#ok<MCCPI>
        mdfPropPrefix;       %#ok<MCCPI>
        
        mdfDefault = defaultMdfSection();
    end
    
    % HasConfigPage & HasWidget
    properties (SetAccess=protected)
        % WidgetClass = 'dabs.resources.widget.widgets.ConexCCWidget';
        ConfigPageClass = 'dabs.resources.configuration.resourcePages.ConexCCPage';
    end
    
    % HasConfigPage
    methods (Static, Hidden)
        function names = getDescriptiveNames()
            names = {'Motor Controller\ConexCC Linear Stage Driver' 'Newport\ConexCC Linear Stage Driver'};
        end
    end

    %% Motor Controller Properties
    properties (SetObservable, SetAccess=protected, AbortSet)
        lastKnownPosition = 0;  % [numeric] [1 x numAxes] sized vector with the last known position of all motors
        isMoving = false;       % [logical] Scalar that is TRUE only if a move initiated by obj.move OR obj.moveAsync has not finished
        isHomed = true;         % [logical] Scalar that is TRUE if the motor's absolute position is known relative to its home position
    end
    
    properties (SetAccess=protected, SetObservable)
        numAxes = 1;               % [numeric] Scalar integer describing the number of axes of the MotorController
        autoPositionUpdate = true; % [logical] indicates if lastKnownPosition automatically updates when position of motor changes
    end

    % communication configuration
    properties
        hCOM = dabs.resources.SerialPort.empty(0,1);  % com port
    end
    
    properties (Hidden)
        % serial configuration, applied on reinit
        baudRate = 921600;
        dataBits = 8;
        stopBits = 1;
        terminator = 'CR/LF';
        flowControl = 'hardware';
        parity = 'none';

        % serial port and timeout
        hSerialPort;
        serialTimeout_s = 0.5;
        
        % controller address configuration
        controllerAddress = 1;

        % polling query timers
        hStatusTimer;
        hMoveCompletionTimer;
    end

    % advanced controller properties
    properties (Dependent)
        % NOTE: the controller opcodes and most properties
        %       are defined in the commandInfoMap, see initCommandMap
        %       at the bottom of this file

        controllerState;  % state of controller
        softwarePositionLimits;
    end
    
    properties
        motorCurrentLimits = [];
    end

    properties (SetAccess=protected, Hidden)
        % error code map
        errorCodes;

        % performance index maps (each 1 x numOpcodes)
        % (note: containers.Map is slow, hence not using it)
        opcodes;
        commandNames;
        commandNames_asyncData;
        commandParameters;
        numCallbacksProcessed;
        numBrokenQueries = 0;

        % debounce state query response
        lastTimeStateQueryIssued_s = [];

        % debounce moving time & counter
        lastMovingTime_s;
        stoppedMovingCount;

        % async returned data properties that have setters
        controllerState_asyncData;
        currentMotorPosition_asyncData;
    end

    properties (Constant,Hidden)
        % timer settings
        STATUS_POLLING_PERIOD_S = 0.3;
        MOVE_COMPLETE_POLLING_PERIOD_S = 0.1;
        MOVE_COMPLETE_POLLING_DELAY_S = 0.1;

        % drop state data processing if this late since last query
        STATE_QUERY_DROP_LATE_SET_LIMIT_S = 0.1;

        % stopped moving debounce counters
        STABLE_MOVING_STOP_S = 0.25;
        MINIMUM_STABLE_MOVING_STOP_COUNT = 3;

        % command parsing indices from query data return
        COMMAND_ADDRESS_INDEX = 1;
        COMMAND_OPCODE_INDICES = 2:3;
    end

    properties (SetAccess=protected)
        % current errors on the controller, parsed from state query data
        controllerErrors;
    end

    %% Lifecycle
    methods
        % ConexCC(name)
        % - An async motor controller for the Newport Conex Single Axis Stage
        %   product line.
        % - Uses ASCII serial communication for commands.
        % - Has all Set/Get properties defined in section 2.4
        %   of ConexCC Controller Documentation ("Command Set" section)
        %   (created dynamically from initCommandMap defined at bottom of file)
        function obj = ConexCC(name)
            obj@dabs.resources.devices.MotorController(name);
            obj = obj@most.HasMachineDataFile(true);

            % initialize error codes
            obj.errorCodes = initErrorCodeMap();

            % initialize opcode parameter maps
            commandInfoMap = initCommandMap();
            obj.commandNames = fieldnames(commandInfoMap);
            numOpcodes = numel(obj.commandNames);
            obj.commandNames_asyncData = cellfun(@(c){[c '_asyncData']},obj.commandNames);
            obj.opcodes = repelem({''},numOpcodes);
            initFalse   = repelem({false},numOpcodes);
            obj.commandParameters = struct('method',initFalse, ...
                'NoSet',initFalse,...
                'NoGet',initFalse,...
                'string',initFalse);
            obj.numCallbacksProcessed = uint64(zeros(1,numOpcodes));

            % add controller Set/Get commands as properties 
            % (see initCommandMap at bottom of file)
            for i = 1:numel(obj.commandNames)
                commandName = obj.commandNames{i};
                parameters = commandInfoMap.(commandName);
                obj.opcodes{i} = parameters.opcode;

                % get parameters from initial map
                method = isfield(parameters,'method') && parameters.method;
                noSet = method || isfield(parameters,'NoSet') && parameters.NoSet;
                noGet = method || isfield(parameters,'NoGet') && parameters.NoGet;
                str = isfield(parameters,'string') && parameters.string;

                % set up commandParameters map
                obj.commandParameters(i).method = method;
                obj.commandParameters(i).NoSet = noSet;
                obj.commandParameters(i).NoGet = noGet;
                obj.commandParameters(i).string = str;

                % add async property for data return (some methods need this)
                propName_asyncData = obj.commandNames_asyncData{i};
                if ~isprop(obj,propName_asyncData)
                    propName_asyncData = obj.addprop(propName_asyncData);
                    propName_asyncData.SetAccess = 'protected';
                    propName_asyncData.SetObservable = true;
                    propName_asyncData.AbortSet = true;
                    propName_asyncData.Transient = true;
                    propName_asyncData.Hidden = true;
                end

                % skip if opcode is a method (no sync property)
                if method
                    continue;
                end

                % add sync property
                propName_sync = commandName;
                if isprop(obj,propName_sync)
                    continue; % don't add if already implemented
                end

                % add default processing to property from command-to-opcode map
                property_sync = obj.addprop(propName_sync);
                property_sync.Dependent = true;

                % create setter
                if ~noSet
                    property_sync.SetMethod = @(o,v)o.issueCommand(parameters.opcode,v);
                else
                    property_sync.SetMethod = @(o,v)abortSet(propName_sync);
                end

                % create getter
                if ~noGet
                    property_sync.GetMethod = @(o)o.issueQuery_sync(parameters.opcode);
                else
                    property_sync.GetMethod = @(o)abortGet(propName_sync);
                end
            end

            obj.deinit();
            obj.loadMdf();
            obj.reinit();

            function abortSet(propname)
                error('Cannot set property %s',propname);
            end

            function v = abortGet(propname)
                v = [];
                error('Cannot get property %s',propname);
            end
        end

        %% RESOURCE METHODS
        % deinit()
        % - Deinitializes communication with motor controller
        % - Stops all polling timers
        % - Unreserves serial port resource
        function deinit(obj)
            try
                obj.stop();
            catch ME
                most.ErrorHandler.logError(ME);
            end
            
            most.idioms.safeDeleteObj(obj.hMoveCompletionTimer);
            most.idioms.safeDeleteObj(obj.hStatusTimer);
            most.idioms.safeDeleteObj(obj.hSerialPort);

            obj.hCOM.unreserve(obj);

            obj.errorMsg = 'deinitialized';
        end

        % reinit()
        % - Reinitializes the communication interface to the motor
        %   controller. Never throws
        % - Instead set errorMsg if reinit fails
        function reinit(obj)
            obj.deinit();
            obj.errorMsg = '';

            try
                % assert MATLAB version is sufficient
                assert(~verLessThan('MATLAB', '9.7'),'MATLAB R2019b or newer is required for ConexCC Serial Connection');

                obj.reinitSerialCommunication();

                obj.hStatusTimer = timer('Name',[obj.name ' ConexCC state query timer'],...
                    'ExecutionMode','fixedRate',...
                    'Period',obj.STATUS_POLLING_PERIOD_S,...
                    'TimerFcn',@(varargin)obj.controllerState_pollingTimerFcn());

                obj.hMoveCompletionTimer = timer('Name',[obj.name ' ConexCC isMoving polling callback timer'],...
                    'ExecutionMode','fixedSpacing','Period',obj.MOVE_COMPLETE_POLLING_PERIOD_S);
                
                start(obj.hStatusTimer);

                obj.numBrokenQueries = 0;

                % reset homed state (will also query for controller errors)
                obj.isHomed = obj.controllerState == dabs.newport.private.ConexCCState.Ready;
            catch ME
                obj.deinit();
                most.ErrorHandler.logAndReportError(ME,'Error during %s initialization:\n%s',obj.name,ME.message);
                obj.errorMsg = ME.message;
            end
        end

        % reinitSerialCommunication()
        % - Reinitializes communication with the selected serial port
        function reinitSerialCommunication(obj)
            % deinit the serial port
            most.idioms.safeDeleteObj(obj.hSerialPort);
            
            % validate all serial attributes
            assert(most.idioms.isValidObj(obj.hCOM),'No serial port is specified');
            validateattributes(obj.baudRate,{'numeric'},{'nonnegative'},'reinit','baudRate');
            if isnumeric(obj.terminator)
                assert(ismember(obj.terminator,0:255), 'Invalid numeric terminator (must be 0 to 255)');
            else
                assert(ismember(obj.terminator,{'CR' 'LF' 'CR/LF'}), ...
                    'Invalid character terminator (must be "CR", "LF", or "CR/LF")');
            end
            assert(ismember(obj.flowControl,{'none' 'hardware' 'software'}),'FlowControl must be "none", "hardware" or "software"');
            assert(ismember(obj.dataBits,5:8),'DataBits must be 5, 6, 7, or 8');
            assert(ismember(obj.stopBits,1:0.5:2),'StopBits must be 1, 1.5, or 2');
            assert(ismember(obj.parity,{'none' 'even' 'odd'}),'Parity must be "none", "even", or "odd"');

            % reserve COM port resource
            obj.hCOM.reserve(obj);

            % initialize and validate serialport object
            obj.hSerialPort = serialport(obj.hCOM.name,obj.baudRate);
            assert(most.idioms.isValidObj(obj.hSerialPort),'Serial port could not be opened');

            % configure and validate serialport to match configuration
            configureTerminator(obj.hSerialPort,obj.terminator);
            obj.hSerialPort.FlowControl = obj.flowControl;
            obj.hSerialPort.DataBits = obj.dataBits;
            obj.hSerialPort.StopBits = obj.stopBits;
            obj.hSerialPort.Parity = obj.parity;
            obj.hSerialPort.Timeout = obj.serialTimeout_s;
            assert(most.idioms.isValidObj(obj.hSerialPort),'Serial port not valid afer configuration');

            % configure and validate callback for asynchronous serial response data
            configureCallback(obj.hSerialPort,'terminator',@obj.processQueryResult_asyncSerialCallback);
            assert(most.idioms.isValidObj(obj.hSerialPort),'Serial port not valid afer setting callback');
        end

        %% MDF METHODS
        % loadMdf()
        % - Loads saved configuration data from the MDF
        function loadMdf(obj)
            success = true;
            success = success & obj.safeSetPropFromMdf('hCOM', 'ComPort');
            success = success & obj.safeSetPropFromMdf('controllerAddress', 'ControllerAddress');
            success = success & obj.safeSetPropFromMdf('baudRate', 'BaudRate');
            success = success & obj.safeSetPropFromMdf('dataBits', 'DataBits');
            success = success & obj.safeSetPropFromMdf('stopBits', 'StopBits');
            success = success & obj.safeSetPropFromMdf('terminator', 'Terminator');
            success = success & obj.safeSetPropFromMdf('flowControl', 'FlowControl');
            success = success & obj.safeSetPropFromMdf('parity', 'Parity');
            
            if ~success
                obj.errorMsg = 'Error loading config';
            end
        end
        
        % saveMdf()
        % - Saves configuration data to the MDF
        function saveMdf(obj)
            obj.safeWriteVarToHeading('ComPort', obj.hCOM);
            obj.safeWriteVarToHeading('ControllerAddress', obj.controllerAddress);
            obj.safeWriteVarToHeading('BaudRate', obj.baudRate);
            obj.safeWriteVarToHeading('DataBits', obj.dataBits);
            obj.safeWriteVarToHeading('StopBits', obj.stopBits);
            obj.safeWriteVarToHeading('Terminator', obj.terminator);
            obj.safeWriteVarToHeading('FlowControl', obj.flowControl);
            obj.safeWriteVarToHeading('Parity', obj.parity);
        end
    end

    %% Motor Controller Implementation
    methods
        % queryMoving()
        % - Queries the controller. if any motor axis is moving, returns true.
        %   if all axes are idle, returns false. Also updates isMoving
        %
        % returns
        % - moving: [logical scalar] TRUE moving, FALSE if idle
        function moving = queryMoving(obj)
            moving = obj.controllerState == dabs.newport.private.ConexCCState.Moving;
            obj.isMoving = obj.debounceMoving(moving);
        end

        % checkMoving_async()
        % - Does not issue a query, instead just checks the async state, which
        %   should be mostly up to date since it is polled via hStatusTimer
        % - This is also done in the controllerState_asyncData setter, which is
        %   invoked each time a status query responds (i.e. each hStatusTimer tick)
        %
        % returns
        % - moving: [logical scalar] TRUE if moving, FALSE if idle
        function moving = checkMoving_async(obj)
            moving = obj.controllerState_asyncData == dabs.newport.private.ConexCCState.Moving;
            obj.isMoving = obj.debounceMoving(moving);
        end

        % debounceMoving(movingState)
        % - Debounces the current moving status to avoid stopping early
        % - This is necessary because MATLAB can be busy during stack movements,
        %   and serial buffer can build up with old state data
        % - When the serial buffer gets read, all the lines will be processed
        %   almost immediately, so debounceMoving has a time debounce component
        %   (i.e. ignore non-moving data if it appears to come too fast)
        % - However sometimes when MATLAB gets busy, it will take time to process
        %   so debounceMoving also has a minimum count criteria
        %
        % parameters
        % - movingState: [logical scalar] current state read from the device
        %
        % returns
        % - moving: [logical scalar] whether the stage is moving (true) or is in stable stop (false)
        function moving = debounceMoving(obj,movingState)
            if movingState || isempty(obj.lastMovingTime_s) || isempty(obj.stoppedMovingCount)
                obj.lastMovingTime_s = tic();
                obj.stoppedMovingCount = 0;
            else
                obj.stoppedMovingCount = obj.stoppedMovingCount + 1;
            end
            
            moving = movingState ...
                || obj.stoppedMovingCount < obj.MINIMUM_STABLE_MOVING_STOP_COUNT ...
                || toc(obj.lastMovingTime_s) < obj.STABLE_MOVING_STOP_S;
        end
        
        % queryPosition()
        % - Synchronously queries all axis positions and returns a [1 x numAxes] containing
        %   the axes positions. Also updates lastKnownPosition
        %
        % returns
        % - position: [1 x numAxes] sized numeric vector containing the
        %             current positions of all axes
        function position = queryPosition(obj)
            position = obj.currentMotorPosition;
            obj.lastKnownPosition = position;  % note: this is auto set on async callback
        end

        % queryPosition_async()
        % - Issues an asynchronous position update, which will be handled in the SerialPort
        %   callback. When the currentMotorPosition_asyncData setter is invoked,
        %   lastKnownPosition will be updated
        function queryPosition_async(obj)
            opcode = obj.commandToOpcode('currentMotorPosition');
            obj.issueQuery_async(opcode);
        end

        % queryStatus_async()
        % - Issues an async status update, which will be handled in the SerialPort
        %   callback. When the controllerState_asyncData setter is invoked,
        %   isMoving will be updated
        function queryStatus_async(obj)
            opcode = obj.commandToOpcode('controllerState');
            obj.issueQuery_async(opcode);
            obj.lastTimeStateQueryIssued_s = tic();
        end
        
        % move(position,timeout_s)
        % - Moves the axes to the specified position. blocks until the move
        %   is completed. Interruptible by UI callbacks for stopping.
        % - Throws if a move is already in progress
        %
        % parameters
        % - position: [1 x numAxes] sized numeric vector containing the target
        %             positions for all axes. Vector can contain NaNs to
        %             indicate axes that shall not be moved
        % - timeout_s: [numeric,scalar] (optional) if not specified, the default timeout should be used
        function move(obj,position,timeout_s)
            if nargin < 3 || isempty(timeout_s)
                magnitude = abs(position - obj.lastKnownPosition);
                estimatedTime = obj.motionTimeForRelativeMove(magnitude) + 0.5;
                timeout_s = max([5 estimatedTime]);
            end

            obj.moveAsync(position);
            obj.moveWaitForFinish(timeout_s);
        end
        
        % moveAsync(position,callback)
        % - Initiates a move but returns immediately, not waiting for the 
        %   move to complete, but calling "callback" after it completes
        % - Throws if a move is already in progress
        %
        % parameters
        % - position: a [1 x numAxes] sized vector containing the target
        %             positions for all axes. Vector can contain NaNs to
        %             indicate axes that shall not be moved
        % - callback: [function handle] function to be called when the
        %             move completes
        function moveAsync(obj,position,callback)
            if nargin < 3
                callback = [];
            end

            if obj.isMoving
                return;
            end
            
            obj.moveToPositionAbsolute(position);
            obj.startMoveCompletionTimer(callback);
        end

        % startMoveCompletionTimer(callback)
        % - Starts a polling timer which checks the isMoving state
        %   and calls "callback" after the controller has stopped moving
        %
        % parameters
        % - callback: [function_handle] callback to call on move completion
        function startMoveCompletionTimer(obj,callback)
            stop(obj.hMoveCompletionTimer);
            obj.hMoveCompletionTimer.TimerFcn = @poll;
            obj.hMoveCompletionTimer.StartDelay = obj.MOVE_COMPLETE_POLLING_DELAY_S; % give stage sufficient time to start moving
            start(obj.hMoveCompletionTimer);
            stop(obj.hStatusTimer);

            function poll(varargin)
                try
                    obj.controllerState_pollingTimerFcn();

                    if ~obj.isMoving
                        stop(obj.hMoveCompletionTimer);
                        start(obj.hStatusTimer);
                        
                        if ~isempty(callback)
                            callback();
                        end
                    end
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
        end
        
        % moveWaitForFinish(timeout_s)
        % - Blocks and waits until isMoving == false
        % - Note: GUI updates and callbacks can occur during "pause",
        %         so this will not block all MATLAB execution. It just
        %         doesn't async return, it will wait then return.
        %
        % parameters
        % - timeout_s: [numeric,scalar] (optional) if not specified, the default timeout should be used
        %              after the timeout expires, stop() is called
        function moveWaitForFinish(obj,timeout_s)
            if nargin < 2 || isempty(timeout_s)
                timeout_s = obj.defaultTimeout_s;
            end

            t = tic();
            pauseTime = max([timeout_s/100 0.05]);
            while obj.isMoving && toc(t) < timeout_s
                pause(pauseTime);
            end
        end
        
        % stop()
        % - Stops the movement of all axes
        function stop(obj)
            obj.stopMotion();
        end
        
        % startHoming()
        % - Starts the motor's homing routine. Blocks until the homing
        %   routine completes. 
        % - Throws if motor does not support homing or error occurs
        function startHoming(obj)
            obj.resetController();
            obj.executeHomeSearch();

            homeTimeout = max([obj.homeSearchTimeout 5]);
            pauseTime   = max([homeTimeout/100 0.05]);
            t = tic();
            while obj.controllerState == dabs.newport.private.ConexCCState.Homing && toc(t) < homeTimeout
                pause(pauseTime);
            end

            obj.isHomed = obj.controllerState == dabs.newport.private.ConexCCState.Ready;
        end
    end

    %% High Level Device API Methods
    methods
        % resetController:
        % - Sets controller state to "Reset" mode
        % - In Reset mode, the controller can be homed via executeHomeSearch
        %   to go to Ready mode.
        % - Only in Reset mode can the controller can be set to Configuration
        %   mode, which can allow setting properties like "motorCurrentLimits"
        function resetController(obj)
            obj.issueCommand();  % issue reset command (auto determine opcode)
        end

        % hardResetController:
        % - Resets the controller and the controller address to "1"
        function hardResetController(obj)
            obj.issueCommand();  % issue hard reset command (auto determine opcode)

            % reset our controller address now that it has been reset on the device
            obj.controllerAddress = 1;
            obj.saveMdf();
        end

        % executeHomeSearch:
        % - Executes a home search which homes the device and puts it in "Ready" state
        function executeHomeSearch(obj)
            obj.assertNoError();
            obj.issueCommand();  % issue home search command (auto determine opcode)
        end

        % checkReadyToMove
        % - Throws when not ready to move, otherwise sets state for move
        function checkReadyToMove(obj)
            obj.assertNoError();

            if obj.controllerState_asyncData == dabs.newport.private.ConexCCState.Moving
                obj.stop(); % stop so user can rapidly move to different location by double clicking
                % also errs on the safe side, e.g. maybe they accidentally clicked high power

                % don't error because it shows up in message box to the user when moving via widget
                % error('Could not move %s:\nController is already moving',obj.name);
            elseif obj.controllerState_asyncData ~= dabs.newport.private.ConexCCState.Ready
                error('Could not move %s:\nController is not ready to move, state: %s',obj.name,char(obj.controllerState_asyncData));
            end

            % set the state async data so that waitForFinish doesn't exit prematurely
            obj.controllerState_asyncData = dabs.newport.private.ConexCCState.Moving;
            obj.lastMovingTime_s = tic();
            obj.stoppedMovingCount = 0;
        end

        % moveToPositionAbsolute
        % - Moves to an absolute stage position
        %
        % parameters
        % - position: [double scalar] position to move to
        function moveToPositionAbsolute(obj,position)
            obj.checkReadyToMove();
            
            % issue move command (auto determine opcode)
            obj.issueCommand([], position);
        end

        % moveToPositionRelative
        % - Moves to an relative stage position
        %
        % parameters
        % - position: [double scalar] relative magnitude to move
        function moveToPositionRelative(obj,position)
            obj.checkReadyToMove();
            
            % issue move command (auto determine opcode)
            obj.issueCommand([], position);
        end

        % motionTimeForRelativeMove
        % - Uses the built in controller functionality to estimate
        %   the time it would take for a relative move
        %
        % parameters
        % - position: [double scalar] relative magnitude to estimate
        %
        % returns
        % - estimate: [double scalar] estimated time (s) for relative move
        function estimate = motionTimeForRelativeMove(obj,position)
            % issue estimate motion time command (auto determine opcode)
            estimate = obj.writeReadCommand_sync([], position);
        end

        % stopMotion
        % - Issues the command for the controller to stop moving ASAP
        function stopMotion(obj)
            obj.issueCommand();
        end

        % controllerState_pollingTimerFcn
        % - Safe timer function for issuing async position and state updates
        % - On error, this function reports the first error but suppresses
        %   consecutive errors since it can flood the terminal with a period
        %   of 0.3 seconds.
        function controllerState_pollingTimerFcn(obj)
            % prevent timer state errors (possible in certain MATLAB edge cases)
            if ~most.idioms.isValidObj(obj) || ~most.idioms.isValidObj(obj.hStatusTimer)
                return
            end

            % error state flag to prevent flooding user with errors on timer function failure
            persistent inErrorState;
            if isempty(inErrorState)
                inErrorState = false;
            end

            try
                obj.queryPosition_async();
                obj.queryStatus_async();
                inErrorState = false;
            catch ME
                if ~inErrorState
                    % prevent consecutive errors from flooding the user
                    most.ErrorHandler.logAndReportError(ME,'%s status timer failed (consecutive errors will be suppressed)',obj.name);
                end
                inErrorState = true;
            end
        end

        % parseControllerState
        % - Parses the controller state from the coded state response string
        %
        % parameters
        % - rawState: [char 1x6] coded state response string
        %
        % returns
        % - state: [enum ConexCCState] parsed controller state
        function state = parseControllerState(obj,rawState)
            assert(ischar(rawState) && numel(rawState) == 6, 'Could not parse error data from raw controller state code');

            % parse state enum value from codes
            stateString = rawState(5:6);
            switch stateString
            case {'0A' '0B' '0C' '0D' '0E' '0F'}
                state = dabs.newport.private.ConexCCState.Reset;
            case '14'
                state = dabs.newport.private.ConexCCState.Configuration;
            case '1E'
                state = dabs.newport.private.ConexCCState.Homing;
            case '28'
                state = dabs.newport.private.ConexCCState.Moving;
            case {'32' '33' '34'}
                state = dabs.newport.private.ConexCCState.Ready;
            case {'36' '37' '38'}
                state = dabs.newport.private.ConexCCState.Ready_Tracking;
            case {'3C' '3D' '3E' '3F'}
                state = dabs.newport.private.ConexCCState.Disable;
            case {'46' '47'}
                state = dabs.newport.private.ConexCCState.Tracking;
            end
        end

        % parseErrorData
        % - Parses the controller errors from the coded state response string
        %
        % parameters
        % - rawState: [char 1x6] coded state response string
        %
        % returns
        % - errors: [cell 1xNumErrors] parsed controller errors
        function errors = parseErrorData(obj,rawState)
            assert(ischar(rawState) && numel(rawState) == 6, 'Could not parse error data from raw controller state code');
            
            % parse error bit flags
            errorString = rawState(1:4);
            errorData = uint16(hex2dec(errorString));
            errorMask = arrayfun(@(i)logical(bitget(errorData,i)),1:16);
            errors = obj.errorCodes(errorMask);
        end

        % opcodeToCommand
        % - Maps a given opcode to it's respective command name
        %
        % parameters
        % - opcode: [char 1x2] opcode for mapping
        %
        % returns
        % - command: [char array] opcode's command name
        function command = opcodeToCommand(obj,opcode)
            mask = strcmp(opcode,obj.opcodes);
            assert(sum(mask)==1, 'Could not find command for opcode %s', opcode);
            command = obj.commandNames{mask};
        end

        % commandToOpcode
        % - Maps a given command name to it's respective opcode
        %
        % parameters
        % - command: [char array] command name for mapping
        %
        % returns
        % - opcode: [char 1x2] command's opcode
        function opcode = commandToOpcode(obj,command)
            mask = strcmp(command,obj.commandNames);
            assert(sum(mask)==1, 'Could not find opcode for command %s', command);
            opcode = obj.opcodes{mask};
        end

        % processQueryResult_asyncSerialCallback(serialPort)
        % - Reads and processes the response from the serial port which is a response
        %   from an issued query.
        % - Expects the callbacks to be configured to fire each time line terminator
        %   is encountered (i.e. 
        %   configureCallbacks(serialPort,"terminator",@processQueryResult_asyncSerialCallback))
        % - Stores the processed query data in the "_asyncData" property that corresponds
        %   to the command (invokes the "_asyncData" Setter and any Pre/Post-Set listeners).
        % - Increments the "numCallbacksProcessed" index that corresponds to the command
        %   processed. This can be used to determine when an update occurs, e.g. waiting for
        %   the obj.numCallbacksProcessed(commandIndex) to change.
        %
        % IMPLEMENTATION NOTE:
        %   I found it was more efficient and easier to have a single SerialPort
        %   callback process all possible responses. This is because changing the
        %   callback between issuing queries can get very convoluted when timers are
        %   issuing queries asynchronously. By not having to change the callback,
        %   it now doesn't matter if issued queries collide, as long as we end up
        %   getting all query responses eventually in the callback.
        %
        % parameters
        % - serialPort: [scalar,MATLAB serialport object] serialPort object issuing callback
        % - varargin:   unused, instead we read lines at a time
        function processQueryResult_asyncSerialCallback(obj,serialPort,varargin)
            % return if in invalid state for callback
            if ~most.idioms.isValidObj(obj) || ~most.idioms.isValidObj(serialPort)
                return
            end

            try
                % read query response from serial port
                queryResults = readline(serialPort);
                if isstring(queryResults) % change to char array
                    queryResults = char(queryResults);
                end

                % parse query response data
                [data,opcode,address] = obj.parseQueryResults(queryResults);

                mask = strcmp(opcode,obj.opcodes);
                if sum(mask) ~= 1
                    % broken, could not find opcode, must be incorrect format
                    obj.numBrokenQueries = obj.numBrokenQueries + 1;
                    most.ErrorHandler.logError('%s: could not parse query response "%s"',obj.name,queryResults);
                    return;
                end

                % convert non-string parameters
                commandParams = obj.commandParameters(mask);
                convertedData = str2double(data);
                if ~commandParams.string && ~isnan(convertedData)
                    data = convertedData;
                end
                
                % set object async property data
                propName_asyncData = obj.commandNames_asyncData{mask};
                obj.(propName_asyncData) = data;

                % process callback
                obj.numCallbacksProcessed(mask) = obj.numCallbacksProcessed(mask) + 1;
            catch ME
                most.ErrorHandler.logAndReportError(ME,'Error on Conex CC callback: %s', ME.message);
            end
        end
    end

    %% Low Level Device API Methods
    methods
        % getOpcodeFromStack(stackPosition)
        % - Automatically determines the command opcode from the current MATLAB callstack
        % - Figures out the opcode by checking the function name at the specified callstack position
        % - E.g. with a stackPosition of 2, this checks the function name of the second function
        %   in the MATLAB stack (the calling function of "getOpcodeFromStack"), and tries to map
        %   the function name to an opcode. 
        % - Useful for automatically determining the command opcode for "Get/Set" property methods
        %
        % parameters
        % - stackPosition: [numeric int] The function position in the stack that has the proper
        %                  command name, by default is 2 (the calling function of this function)
        %
        % returns
        % - opcode: [char 1x2] opcode for the command from the stack function name
        function opcode = getOpcodeFromStack(obj,stackPosition)
            if nargin < 2 || isempty(stackPosition)
                % by default, assume Getter call is up 2 functions in the stack
                stackPosition = 2;
            end

            try
                s = dbstack();
                functionName = s(stackPosition).name;
                propName = replace(functionName,{[mfilename '.'] 'set.' 'get.'},'');
                opcode = obj.commandToOpcode(propName);
            catch ME
                most.ErrorHandler.logAndReportError(ME,'Could not get opcode for desired command:\n%s',ME.message);
                rethrow(ME);
            end
        end

        % asciiCommand(opcode,data)
        % - Constructs an ASCII command for the controller given an opcode
        %   and data
        % - Follows the ASCII convention laid out in Conex CC Controller
        %   Documentation section 2.4 ("Command Set")
        % - Example Command:  "1AC500" <- sets acceleration of controller
        %                                 address 1 to 500.0
        %
        % parameters
        % - opcode: [char 1x2] opcode for the command
        % - data:   [numeric scalar] (optional) data to send with the command
        %
        % returns
        % - strCommand: [char array] ASCII command to send via serial port
        function strCommand = asciiCommand(obj,opcode,data)
            if nargin < 3 || isempty(data)
                dataStr = '';
            else
                dataStr = sprintf('%g',data);
            end
            strCommand = sprintf('%d%s%s',obj.controllerAddress,opcode,dataStr);
        end

        % asciiQuery(opcode)
        % - Constructs an ASCII query for the controller given an opcode
        % - Follows the ASCII convention laid out in Conex CC Controller
        %   Documentation section 2.4 ("Command Set")
        % - Example Query:    "1AC?"   <- queries acceleration of controller address 1
        % - Example Response: "1AC500" <- acceleration response of 500.0
        %
        % parameters
        % - opcode: [char 1x2] opcode for the query
        %
        % returns
        % - strQuery: [char array] ASCII query to send via serial port
        function strQuery = asciiQuery(obj,opcode)
            strQuery = sprintf('%d%s?',obj.controllerAddress,opcode);
        end

        % issueCommand(opcode,data)
        % - Uses asciiCommand to construct a command from opcode and data, then
        %   issues it via the connected serial port. Throws if disconnected, or
        %   on COM error with issuing the command, or if opcode could not be
        %   identified.
        % - Example: obj.issueCommand('AC',500.0) -> writeline('1AC500')
        %            -> sets device acceleration to 500.0
        %
        % parameters
        % - opcode: [char 1x2] two-letter command opcode
        % - data:   [numeric scalar] data to send with the command
        function issueCommand(obj,opcode,data)
            if ~most.idioms.isValidObj(obj.hSerialPort)
                error('ConexCC serial port disconnected');
            end

            if nargin < 2 || isempty(opcode)
                opcode = obj.getOpcodeFromStack(3);
            end

            if nargin < 3
                data = [];
            end

            command = obj.asciiCommand(opcode,data);
            writeline(obj.hSerialPort,command);
        end

        % issueQuery_async(opcode)
        % - Uses asciiQuery to construct a query given the opcode, then
        %   issues it via the connected serial port. Returns immediately
        %   afterwards (doesn't wait for response).
        % - Response is expected to be processed in serial port callback,
        %   obj.processQueryResult_asyncSerialCallback()
        %
        % parameters
        % - opcode: [char 1x2] two-letter query opcode
        function issueQuery_async(obj,opcode)
            if ~most.idioms.isValidObj(obj.hSerialPort)
                error('ConexCC serial port disconnected');
            end

            if nargin < 2 || isempty(opcode)
                opcode = obj.getOpcodeFromStack(3);
            end

            query = obj.asciiQuery(opcode);
            writeline(obj.hSerialPort,query);
            % return should be processed asyncrhonously
        end

        % issueQuery_sync(opcode,timeout_s)
        % - Uses issueQuery_async to issue an asynchronous query
        %   that returns immediately, but then waits for the query
        %   to be processed in processQueryResult_asyncSerialCallback().
        % - After waiting and getting the response, returns
        %   the latest data that was received in the async callback.
        % - If no response was received by the timeout, quietly logs
        %   the error and returns the last good data received.
        %
        % parameters
        % - opcode:    [char 1x2] two-letter query opcode
        % - timeout_s: [numeric scalar] timeout to wait before returning
        %
        % returns
        % - data: [numeric scalar or char array] data returned from
        %         the query (if the timeout was exceeded, then
        %         returns the last good data and quietly logs error)
        function data = issueQuery_sync(obj,opcode,timeout_s)
            if nargin < 2 || isempty(opcode)
                opcode = obj.getOpcodeFromStack(3);
            end
            if nargin < 4 || isempty(timeout_s)
                timeout_s = obj.serialTimeout_s;
            end
            
            if ~most.idioms.isValidObj(obj.hSerialPort)
                error('ConexCC serial port disconnected');
            end

            % initialize variables and issue asynchronous query
            mask = strcmp(opcode,obj.opcodes);
            assert(sum(mask) == 1, 'Could not find opcode %s', opcode);
            numProcessed = obj.numCallbacksProcessed(mask);
            obj.issueQuery_async(opcode);
            t = tic();

            % wait for async query to complete
            while obj.numCallbacksProcessed(mask) == numProcessed && toc(t) < timeout_s
                pause(0.001);
            end

            % warn in error log if no data was returned from device
            if obj.numCallbacksProcessed(mask) == numProcessed
                most.ErrorHandler.logAndReportError('%s: ConexCC query was not answered in %d seconds, returning last value',obj.name,timeout_s);
            end

            propName_asyncData = obj.commandNames_asyncData{mask};
            data = obj.(propName_asyncData);
        end

        % writeReadCommand_sync
        % - Writes data to an opcode using issueCommand(), then issues
        %   an asynchronous query using issueQuery_async() which returns
        %   immediately (doesn't wait for a response).
        % - Response is expected to be processed in serial port callback,
        %   obj.processQueryResult_asyncSerialCallback()
        %
        % parameters
        % - opcode: [char 1x2] two-letter command opcode
        % - data:   [numeric scalar] data to send with the command
        function writeReadCommand_async(obj,opcode,data)
            if isempty(opcode)
                opcode = obj.getOpcodeFromStack(3);
            end

            obj.issueCommand(opcode,data);
            obj.issueQuery_async(opcode);
        end

        % writeReadCommand_sync
        % - Writes data to an opcode using issueCommand(), then reads
        %   the data back using issueQuery_sync()
        %
        % parameters
        % - opcode:    [char 1x2] two-letter query opcode
        % - data:      [numeric scalar] data to send with the command
        % - timeout_s: [numeric scalar] timeout to wait before returning
        %
        % returns
        % - response: [numeric scalar or char array] data returned from
        %             the synchronous query, or last good data if timeout
        %             exceeded (quietly logs error in this case)
        function response = writeReadCommand_sync(obj,opcode,data,timeout_s)
            if nargin < 4 || isempty(timeout_s)
                timeout_s = obj.serialTimeout_s;
            end
            if isempty(opcode)
                opcode = obj.getOpcodeFromStack(3);
            end

            obj.issueCommand(opcode,data);
            response = obj.issueQuery_sync(opcode,timeout_s);
        end

        % parseQueryResults
        % - Parses the data from a response received from the controller
        % - E.g. user issues query for acceleration: '1AC?',
        %   device responds '1AC500' which should be parsed into
        %   {'address': 1, 'opcode': 'AC', 'data': '500'}
        %
        % parameters
        % - queryResults: [char array] formatted response from controller
        %
        % returns
        % - data:    [char array] data string portion of the query results
        % - opcode:  [char 1x2] two-letter opcode portion of the query results
        % - address: [numeric scalar] address of the controller from query results
        function [data,opcode,address] = parseQueryResults(obj,queryResults)
            if isstring(queryResults)
                queryResults = char(queryResults);
            end

            assert(numel(queryResults) > obj.COMMAND_OPCODE_INDICES(end), 'Invalid query response received, not enough chars');

            address = str2double(queryResults(obj.COMMAND_ADDRESS_INDEX));
            opcode = queryResults(obj.COMMAND_OPCODE_INDICES);
            assert(all(isletter(opcode)), 'Invalid query response received, opcode non-alphabetic');
            data = queryResults(obj.COMMAND_OPCODE_INDICES(end)+1:end);
        end
    end

    %% Property Methods
    methods
        % hCOM: resource for the serial port
        function set.hCOM(obj,val)
            if isnumeric(val) && ~isempty(val)
                val = sprintf('COM%d',val);
            end

            val = obj.hResourceStore.filterByName(val);

            if ~isequal(val,obj.hCOM)
                if most.idioms.isValidObj(val)
                    validateattributes(val,{'dabs.resources.SerialPort'},{'scalar'});
                end

                obj.deinit();
                obj.hCOM.unregisterUser(obj);
                obj.hCOM = val;
                obj.hCOM.registerUser(obj,'COM Port');
            end
        end

        %% SYNCHRONOUS PROPERTY METHODS
        % controllerState: allows setting the state to Reset, Disable, and Ready
        function set.controllerState(obj,v)
            switch v
            case dabs.newport.private.ConexCCState.Reset
                obj.enableResetState = 1;
            case dabs.newport.private.ConexCCState.Disable
                if obj.controllerState == dabs.newport.private.ConexCCState.Ready
                    obj.enabledState = 0;
                end
            case dabs.newport.private.ConexCCState.Ready
                if obj.controllerState == dabs.newport.private.ConexCCState.Disable
                    obj.enabledState = 1;
                end

            % Future addition possibility: other state transitions
            end
        end

        function v = get.controllerState(obj)
            v = obj.issueQuery_sync();  % issue synchronous controllerState query
        end

        % controllerErrors: list of current errors parsed from the controller state
        function errors = get.controllerErrors(obj)
            opcode = obj.commandToOpcode('controllerState');
            obj.issueQuery_sync(opcode);  % issue synchronous controllerState query
            errors = obj.controllerErrors;
        end

        % softwarePositionLimits: the current limits programmed onto the device for movement
        function v = get.softwarePositionLimits(obj)
            v = [obj.softwarePositionLimits_Low obj.softwarePositionLimits_High];
        end

        function set.softwarePositionLimits(obj,v)
            validateattributes(v,{'numeric'},{'vector','increasing','numel',2});
            obj.softwarePositionLimits_Low  = v(1);
            obj.softwarePositionLimits_High = v(2);
        end
        
        % motorCurrentLimits: motor current driver properties, can't access unless in Configuration
        function v = get.motorCurrentLimits(obj)
            if obj.controllerState == dabs.newport.private.ConexCCState.Configuration
                v = obj.issueQuery_sync();
            else
                v = obj.motorCurrentLimits_async;
            end
        end
        
        % motorCurrentLimits: motor current driver properties, can't access unless in Configuration
        function set.motorCurrentLimits(obj,v)
            error('Can''t currently set the motorCurrentLimits, it can damage the motor');
            % if obj.controllerState == dabs.newport.private.ConexCCState.Configuration
            %     obj.issueCommand(obj,v);
            % end
        end

        %% ASYNC DATA SETTER METHODS
        % (processed on processQueryResult_asyncSerialCallback callbacks)

        % controllerState_asyncData: data returned from state query
        function set.controllerState_asyncData(obj,rawState)
            if ischar(rawState) && numel(rawState) == 6
                % don't process if the last query is so long ago
                % (indicates late callback processing, and can trick checkMoving)
                if ~isempty(obj.lastTimeStateQueryIssued_s) ...
                        && toc(obj.lastTimeStateQueryIssued_s) > obj.STATE_QUERY_DROP_LATE_SET_LIMIT_S
                    return
                end

                obj.controllerState_asyncData = obj.parseControllerState(rawState);
                errors = obj.parseErrorData(rawState);
                if numel(errors) > 0
                    obj.errorMsg = sprintf('Errors: %s',strjoin(errors,','));
                end

                obj.controllerErrors = errors;
            elseif isa(rawState,'dabs.newport.private.ConexCCState')
                obj.controllerState_asyncData = rawState;
            else
                % bad parse, no state response available
                if ~ischar(rawState)
                    rawState = num2str(rawState);
                end
                most.ErrorHandler.logError('%s: Could not parse controller state: %s',obj.name,rawState);
                obj.numBrokenQueries = obj.numBrokenQueries + 1;
            end

            obj.checkMoving_async();
        end

        % currentMotorPosition_asyncData: data returned from position query
        function set.currentMotorPosition_asyncData(obj,positionData)
            obj.currentMotorPosition_asyncData = positionData;
            obj.lastKnownPosition = positionData;
        end
    end
end

%% Device Command Property to Opcode Map
% - Creates a mapping of all possible opcodes to their respective ConexCC MATLAB property
% - Opcodes are defined in ConexCC Controller Documentation section 2.4 ("Command Set")
% - Many opcodes defined in the ConexCC documentation are "Set/Get" properties (e.g. 
%   "velocity").
% - For opcodes that are methods (e.g. moveToAbsolutePosition), or opcodes that do not
%   allow setters (e.g. currentMotorPosition, getter only) or getters (e.g. enabledState, 
%   setter only) there are fields which can be added to handle those situations:
%     method: if true, the command is a method which can take data and return data, but
%             is not a property that has stateful data in it.
%     NoSet:  if true, the command cannot be set (e.g. currentMotorPosition which is getter only).
%     NoGet:  if true, the command cannot be get (e.g. enabledState which is setter only).
%     string: if true, the command outputs string data, not numeric data converted from string.
% - See the ConexCC constructor for how these properties are parsed and added to the class.
% Note: the structure field names must match their respective
%       property or method names, otherwise they won't be connected in the constructor
function s = initCommandMap()
    s.controllerState = struct('opcode','TS','string',true);  % state of controller
    s.stageIdentifier = struct('opcode','ID');
    s.controllerRevisionInfo = struct('opcode','VE');

    % (unused since all parameters are quried separately)
    % s.queryAllAxisParameters = struct('opcode','ZT','method',true);

    % controller parameters and methods
    s.acceleration = struct('opcode','AC');
    s.velocity = struct('opcode','VA');
    s.backlashCompensation = struct('opcode','BA');
    s.hysteresisCompensation = struct('opcode','BH');
    s.driverVoltage = struct('opcode','DV');
    s.lowPassFilterForKd = struct('opcode','FD');
    s.followingErrorLimit = struct('opcode','FE');
    s.frictionCompensation = struct('opcode','FF');
    s.jerkTime = struct('opcode','JR');
    s.velocityFeedForward = struct('opcode','KV');
    s.motorCurrentLimits = struct('opcode','QI');
    s.softwarePositionLimits_High = struct('opcode','SR');
    s.softwarePositionLimits_Low = struct('opcode','SL');
    s.currentMotorPosition = struct('opcode','TP','NoSet',true);
    s.currentSetPointPosition = struct('opcode','TH','NoSet',true);
    s.moveToPositionAbsolute = struct('opcode','PA','method',true);
    s.moveToPositionRelative = struct('opcode','PR','method',true);
    s.motionTimeForRelativeMove = struct('opcode','PT','method',true);
    s.stopMotion = struct('opcode','ST','method',true);

    % feedback
    s.commandErrorString = struct('opcode','TB','NoSet',true);
    s.lastCommandError = struct('opcode','TE','NoSet',true);

    % state enter transitions
    s.resetController = struct('opcode','RS','method',true);
    s.hardResetController = struct('opcode','RS##','method',true);
    s.executeHomeSearch = struct('opcode','OR','method',true);

    % state enter/leave transitions
    s.enabledState = struct('opcode','MM','NoGet',true);
    s.enableConfigurationState = struct('opcode','PW','NoGet',true);
    s.enableTrackingState = struct('opcode','TK','NoGet',true);

    % misc
    s.rs485Address = struct('opcode','SA');
    s.controlLoopState = struct('opcode','SC');
    s.encoderIncrementValue = struct('opcode','SU');
    s.executeSimultaneousStartedMove = struct('opcode','SE');

    % homing
    s.homeSearchType = struct('opcode','HT');
    s.homeSearchTimeout = struct('opcode','OT');
    s.homeSearchVelocity = struct('opcode','OH');

    % PID properties
    s.derivativeGain = struct('opcode','KD');
    s.integralGain = struct('opcode','KI');
    s.proportionalGain = struct('opcode','KP');
end

function errors = initErrorCodeMap()
% 16 possible error flags defined in ConexCC manual
errors = {...
    'Negative end of run', ...
    'Positive end of run', ...
    'Peak current limit', ...
    'RMS current limit', ...
    'Short circuit detection', ...
    'Following error', ...
    'Homing time out', ...
    'Wrong ESP stage', ...
    'DC voltage too low', ...
    '80 W output power exceeded', ...
    'Not used', 'Not used', 'Not used', ...
    'Not used', 'Not used', 'Not used', ...
};
end

function s = defaultMdfSection()
s = [...
    most.HasMachineDataFile.makeEntry('ComPort','','Serial COM port connected to ConexCC controller')...
    most.HasMachineDataFile.makeEntry('ControllerAddress',1,'ConexCC controller address')...
    most.HasMachineDataFile.makeEntry()... % blank line
    most.HasMachineDataFile.makeEntry('ConexCC Serial Port Configuration (specified in ConexCC manual "USB Communication Settings")')...
    most.HasMachineDataFile.makeEntry('BaudRate', 921600, 'COM Port Baud Rate (bits/s)')...
    most.HasMachineDataFile.makeEntry('DataBits', 8, 'COM Port Data Bits')...
    most.HasMachineDataFile.makeEntry('StopBits', 1, 'COM Port Stop Bits')...
    most.HasMachineDataFile.makeEntry('Terminator', 'CR/LF', 'COM Port Command Terminator')...
    most.HasMachineDataFile.makeEntry('FlowControl', 'hardware', 'COM Port Flow Control (for Xon/Xoff use ''hardware'')')...
    most.HasMachineDataFile.makeEntry('Parity', 'none', '')...
];
end

% ---------------------------------------------------------------------------
% Copyright (C) 2025 MBF Bioscience
% 
% ScanImage (R) 2025 is software to be used under the purchased terms
% Code may be modified, but not redistributed without the permission
% of MBF Bioscience
% 
% MBF BIOSCIENCE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, WITH
% RESPECT TO THIS PRODUCT, AND EXPRESSLY DISCLAIMS ANY WARRANTY OF
% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
% IN NO CASE SHALL MBF BIOSCIENCE BE LIABLE TO ANYONE FOR ANY
% CONSEQUENTIAL OR INCIDENTAL DAMAGES, EXPRESS OR IMPLIED, OR UPON ANY OTHER
% BASIS OF LIABILITY WHATSOEVER, EVEN IF THE LOSS OR DAMAGE IS CAUSED BY
% MBF BIOSCIENCE'S OWN NEGLIGENCE OR FAULT.
% CONSEQUENTLY, MBF BIOSCIENCE SHALL HAVE NO LIABILITY FOR ANY
% PERSONAL INJURY, PROPERTY DAMAGE OR OTHER LOSS BASED ON THE USE OF THE
% PRODUCT IN COMBINATION WITH OR INTEGRATED INTO ANY OTHER INSTRUMENT OR
% DEVICE.  HOWEVER, IF MBF BIOSCIENCE IS HELD LIABLE, WHETHER
% DIRECTLY OR INDIRECTLY, FOR ANY LOSS OR DAMAGE ARISING, REGARDLESS OF CAUSE
% OR ORIGIN, MBF BIOSCIENCE MAXIMUM LIABILITY SHALL NOT IN ANY
% CASE EXCEED THE PURCHASE PRICE OF THE PRODUCT WHICH SHALL BE THE COMPLETE
% AND EXCLUSIVE REMEDY AGAINST MBF BIOSCIENCE.
% ---------------------------------------------------------------------------

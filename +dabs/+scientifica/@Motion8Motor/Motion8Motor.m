classdef Motion8Motor < dabs.resources.devices.MotorController ...
        & dabs.resources.configuration.HasConfigPage ...
        & most.HasMachineDataFile
    
    properties (SetAccess=protected, Hidden) %% dabs.resources.configuration.HasConfigPage
        ConfigPageClass = 'dabs.resources.configuration.resourcePages.Motion8Page';
    end
    
    properties (SetObservable, SetAccess=protected, AbortSet) %% dabs.resources.devices.MotorController
        lastKnownPosition;      % [numeric] [1 x numAxes] sized vector with the last known position of all motors
        isMoving = false;       % [logical] Scalar that is TRUE only if a move initiated by obj.move OR obj.moveAsync has not finished
        isHomed = true;        % [logical] Scalar that is TRUE if the motor's absolute position is known relative to its home position
    end
    
    properties (SetAccess=protected, SetObservable) %% dabs.resources.devices.MotorController
        numAxes = 3;
        autoPositionUpdate = true; % [logical] indicates if lastKnownPosition automatically updates when position of motor changes
    end
    
    properties (Constant, Hidden) %% most.HasMachineDataFile
        % Required properties
        mdfClassName = mfilename('class');
        mdfHeading = 'Scientifica Motion8';
        
        % Optional properties
        mdfDependsOnClasses; %#ok<MCCPI>
        mdfDirectProp; %#ok<MCCPI>
        mdfPropPrefix; %#ok<MCCPI>
        
        mdfDefault = defaultMdfSection();
    end
    
    properties (SetAccess = { ...
            ?dabs.resources.configuration.resourcePages.Motion8Page ...
            , ?most.HasMachineDataFile ...
            }) %% Motion8Page Interface
        selectedRackId string; % UID for Motion8Rack
        selectedDeviceIndex; % 1 or 2
    end
    
    properties (SetAccess = private)
        rackUids(:,1) string;
    end
    
    properties (SetAccess = private)
        AvailableRacks; % array of Motion8Rack objects.
        SelectedDevice = dabs.scientifica.motion8.Device.empty();
        positionListener(:,1) event.listener;
        positionTimerTag string;
    end
    
    methods (Static) %% dabs.resources.configuration.HasConfigPage
        function names = getDescriptiveNames()
            names = { ...
                'Motor Controller\Scientifica Motion 8 Controller' ...
                , 'Scientifica\Scientifica Motion 8 Controller' ...
                };
        end
    end
    
    methods %% Lifecycle
        function obj = Motion8Motor(name)
            obj = obj@dabs.resources.devices.MotorController(name);
            obj = obj@most.HasMachineDataFile(true);
            
            if ~dabs.scientifica.motion8.isAssemblyLoaded()
                dabs.scientifica.motion8.loadAssembly();
            end
            obj.initTimer();
            obj.deinit();
            obj.loadMdf();
            obj.reinit();
        end
        
        function delete(obj)
            obj.deinit();
            most.idioms.safeDeleteObj(obj.positionListener);
            most.idioms.safeDeleteObj(obj.getTimer());
        end
    end
    
    methods %% most.HasMachineDataFile
        function loadMdf(obj)
            assert(most.idioms.isValidObj(obj), 'obj was deleted');
            assert(isscalar(obj), 'obj must be scalar');
            obj.safeSetPropFromMdf('selectedRackId', 'rackID');
            obj.safeSetPropFromMdf('selectedDeviceIndex', 'deviceNumber');
        end
        
        function saveMdf(obj)
            assert(most.idioms.isValidObj(obj), 'obj was deleted');
            assert(isscalar(obj), 'obj must be scalar');
            obj.safeWriteVarToHeading('rackID', convertStringsToChars(obj.selectedRackId));
            obj.safeWriteVarToHeading('deviceNumber', obj.selectedDeviceIndex);
        end
    end
    
    methods %% dabs.resouces.Resources
        %    <- From dabs.resources.resources.Device
        %    <- From dabs.resources.devices.MotorController
        
        function deinit(obj)
            try
                obj.stop();
                stop(obj.getTimer());
                obj.SelectedDevice = dabs.scientifica.motion8.Device.empty();
            catch
            end
            
            obj.errorMsg = 'uninitialized';
        end
        
        function reinit(obj)
            import dabs.scientifica.motion8.Axis;
            obj.deinit();
            
            try
                obj.errorMsg = '';
                obj.AvailableRacks = dabs.scientifica.motion8.Rack.getAll();
                obj.rackUids = strings(length(obj.AvailableRacks), 1);
                for iRack = 1:length(obj.AvailableRacks)
                    obj.rackUids(iRack) = obj.AvailableRacks(iRack).Uid;
                end
                assert(~isempty(obj.selectedRackId) && 0 < strlength(obj.selectedRackId) ...
                    , 'No Rack ID selected');
                assert(~isempty(obj.selectedDeviceIndex), 'No Device index provided');
                isRackSelected = obj.selectedRackId == obj.rackUids;
                assert(any(isRackSelected), 'Rack UID %s not found', obj.selectedRackId);
                obj.SelectedDevice = obj.getSelectedDevice();
                controllableAxes = [Axis.X, Axis.Y, Axis.Z];
                obj.numAxes = sum(ismember(obj.SelectedDevice.AvailableAxes, controllableAxes));
                start(obj.getTimer());
            catch ME
                obj.deinit();
                obj.errorMsg = sprintf('%s: initialization error: %s',obj.name,ME.message);
                most.ErrorHandler.logError(ME,obj.errorMsg);
            end
        end
    end
    
    methods %% dabs.resources.devices.MotorController
        function tf = queryMoving(obj)
            assert(most.idioms.isValidObj(obj), 'obj was used after deletion');
            assert(isscalar(obj), 'obj must be scalar');
            Device = obj.SelectedDevice;
            tf = Device.isMoving() || Device.isWaitingOnMove;
            obj.isMoving = tf;
        end
        
        function v = queryPosition(obj)
            import dabs.scientifica.motion8.Axis;
            assert(most.idioms.isValidObj(obj), 'obj was used after deletion');
            assert(isscalar(obj), 'obj must be scalar');
            Device = obj.SelectedDevice;
            LastPos = Device.getLastPosition();
            v = nan(1, obj.numAxes);
            Axes = [Axis.X, Axis.Y, Axis.Z];
            iV = 1;
            for iA = 1:length(Axes)
                name = char(Axes(iA));
                if isfield(LastPos, name)
                    v(iV) = LastPos.(name);
                    iV = iV + 1;
                end
            end
            obj.lastKnownPosition = v;
        end
        
        function move(obj, position, timeout_s)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            if nargin < 3 || isempty(timeout_s)
                timeout_s = obj.defaultTimeout_s;
            end
            
            obj.moveAsync(position);
            obj.moveWaitForFinish(timeout_s);
        end
        
        function moveAsync(obj, position, callback)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            if nargin < 3 || isempty(callback)
                callback = [];
            end
            
            assert(~obj.queryMoving(), 'Scientifica Motion8: Move is already in progress');
            D = obj.SelectedDevice;
            Axes = D.AvailableAxes;
            Arguments = struct('Callback', callback);
            for iA = 1:length(Axes)
                switch (Axes(iA))
                    case dabs.scientifica.motion8.Axis.X
                        if length(position) >= 1 && ~isnan(position(1))
                            Arguments.X = position(1);
                        end
                    case dabs.scientifica.motion8.Axis.Y
                        if length(position) >= 2 && ~isnan(position(2))
                            Arguments.Y = position(2);
                        end
                    case dabs.scientifica.motion8.Axis.Z
                        if length(position) >= 3 && ~isnan(position(3))
                            Arguments.Z = position(3);
                        end
                end
            end
            D.goToAsync(Arguments);
        end
        
        function moveWaitForFinish(obj,timeout_s)
            assert(most.idioms.isValidObj(obj), 'obj was deleted before use.');
            assert(isscalar(obj), 'obj must be scalar');
            if nargin < 2 || isempty(timeout_s)
                timeout_s = obj.defaultTimeout_s;
            end
            ticVal = tic();
            hasTimedOut = true;
            while toc(ticVal) <= timeout_s
                if ~obj.queryMoving()
                    hasTimedOut = false;
                    break;
                end
                pause(0.1);
            end
            if hasTimedOut
                obj.stop();
            end
            assert(~hasTimedOut, 'Motor %s: Move timed out.\n', obj.name);
        end
        
        function stop(obj)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            obj.SelectedDevice.stop();
            obj.isMoving = false;
        end
        
        function startHoming(~)
            % No Op
        end
    end
    
    methods (Access = ?dabs.resources.configuration.resourcePages.Motion8Page)
        function Summary = getDeviceSummary(obj)
            Summary = struct();
            if isempty(obj.selectedDeviceIndex) || isempty(obj.selectedRackId)
                return;
            end
            R = obj.getSelectedRack();
            D = obj.SelectedDevice;
            RackSummary = R.summarize();
            rackFields = fieldnames(RackSummary);
            for iField = 1:length(rackFields)
                name = rackFields{iField};
                Summary.(name) = RackSummary.(name);
            end
            DeviceSummary = D.summarize();
            devFields = fieldnames(DeviceSummary);
            for iField = 1:length(devFields)
                name = devFields{iField};
                assert(~isfield(Summary, name) ...
                    , 'duplicate field name "%s" for Motion8 Rack Device', name);
                Summary.(name) = DeviceSummary.(name);
            end
        end
    end
    
    methods (Access = private)
        function R = getSelectedRack(obj)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            R = obj.AvailableRacks(obj.selectedRackId == obj.rackUids);
            assert(isscalar(R));
        end
        
        function D = getSelectedDevice(obj)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            R = obj.getSelectedRack();
            Devices = R.getDevices();
            D = Devices(obj.selectedDeviceIndex);
        end
        
        initTimer(obj);
        
        function Timer = getTimer(obj)
            assert(isscalar(obj), 'obj must be scalar');
            Timer = timerfindall('Tag', obj.positionTimerTag);
            assert(isvalid(Timer), 'failed to find timer: timer was invalid');
            assert(isscalar(Timer), 'failed to find timer: multiple timers found');
        end
    end
end

function s = defaultMdfSection()
    s = [...
        most.HasMachineDataFile.makeEntry('rackID','','Unique ID for this motor') ...
        most.HasMachineDataFile.makeEntry('deviceNumber', [], 'Device Index for this Rack') ...
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

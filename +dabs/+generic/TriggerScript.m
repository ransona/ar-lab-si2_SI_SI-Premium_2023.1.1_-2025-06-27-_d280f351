classdef TriggerScript < dabs.resources.Device & dabs.resources.configuration.HasConfigPage & most.HasMachineDataFile & dabs.resources.widget.HasWidget
    properties (SetAccess=protected)
        ConfigPageClass = 'dabs.resources.configuration.resourcePages.TriggerScriptPage';
    end

    methods (Static)
        function names = getDescriptiveNames()
            names = {'Externally Triggerable Scripts'};
        end
    end

    %%% ABSTRACT PROPERTY REALIZATIONS (most.HasMachineDataFile)
    properties (Constant, Hidden)
        %Value-Required properties
        mdfClassName = mfilename('class');
        mdfHeading = 'Triggerable Script';

        %Value-Optional properties
        mdfDependsOnClasses; %#ok<MCCPI>
        mdfDirectProp;       %#ok<MCCPI>
        mdfPropPrefix;       %#ok<MCCPI>

        mdfDefault = defaultMdfSection();
    end

    %% Has Widget
    properties (SetObservable, SetAccess=protected)
        WidgetClass = 'dabs.resources.widget.widgets.TriggerScriptWidget';
    end

    properties (SetObservable)
        hDITriggerport = {dabs.resources.Resource.empty();dabs.resources.Resource.empty();dabs.resources.Resource.empty();dabs.resources.Resource.empty();dabs.resources.Resource.empty()};
        hDITriggeredge = [true, true, true, true, true];
        scripts = {''; ''; ''; ''; ''};
        trigEnabled = [false; false; false; false; false];
        scriptruntime = [0; 0; 0; 0; 0];
        knownScriptsTakingTooLong;
    end

    properties (SetAccess=private, GetAccess=private)
        hIOListeners = event.listener.empty(0,1);
    end

    %% FRIEND PROPS
    methods
        function obj = TriggerScript(name)
            obj@dabs.resources.Device(name);
            obj = obj@most.HasMachineDataFile(true);

            obj.deinit();
            obj.loadMdf();
            obj.reinit();
        end

        function delete(obj)
            try
                obj.deinit();
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end
        end

        function deinit(obj)
            try
                delete(obj.hIOListeners);
                obj.hIOListeners = event.listener.empty(0,1);
                for idx=1:5
                    if most.idioms.isValidObj(obj.hDITriggerport{idx})
                        obj.hDITriggerport{idx}.unreserve(obj);
                    end
                end
                obj.errorMsg = 'uninitialized';
            catch ME
                most.ErrorHandler.logAndReportError(ME);
                obj.errorMsg = sprintf('Error deinitializing: %s',ME.message);
            end
        end

        function reinit(obj)
            obj.deinit();

            try
                obj.validateScripts();

                for idx=1:5
                    if isempty(obj.scripts{idx}) && (obj.trigEnabled(idx) || ~isempty(obj.hDITriggerport{idx}))
                        warnTxt = sprintf('%s: Script not defined for trigger ports that are defined and/or enabled.',obj.name);
                        most.idioms.warn(warnTxt);
                    end

                    if most.idioms.isValidObj(obj.hDITriggerport{idx})
                        obj.hDITriggerport{idx}.reserve(obj);
                        obj.hDITriggerport{idx}.tristate();
                        obj.hIOListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hDITriggerport{idx},'lastKnownValueChanged',@(src,evt)obj.hardwareTriggerScript(src,evt));
                    end
                end
                obj.errorMsg = '';
            catch ME
                obj.deinit();
                obj.errorMsg = sprintf('%s: initialization error: %s',obj.name,ME.message);
                most.ErrorHandler.logError(ME,obj.errorMsg);
            end
        end
    end

    %% MDF methods
    methods
        function loadMdf(obj)
            success = true;
            success = success & obj.safeSetPropFromMdf('scripts', 'scripts_s');
            success = success & obj.safeSetPropFromMdf('hDITriggerport', 'DITriggerport');
            success = success & obj.safeSetPropFromMdf('hDITriggeredge', 'DITriggeredge');
            success = success & obj.safeSetPropFromMdf('trigEnabled', 'trigEnabled');
            if ~success
                obj.errorMsg = 'Error loading config';
            end
        end

        function saveMdf(obj)
            portNames = {'';'';'';'';''};
            for idx = 1:5
                hport = obj.hDITriggerport{idx};
                if most.idioms.isValidObj(hport)
                    portNames{idx} = hport.name;
                else
                    portNames{idx} = '';
                end
            end
            
            obj.safeWriteVarToHeading('DITriggerport', portNames);
            obj.safeWriteVarToHeading('DITriggeredge', obj.hDITriggeredge);
            obj.safeWriteVarToHeading('scripts_s', obj.scripts);
            obj.safeWriteVarToHeading('trigEnabled', obj.trigEnabled);
        end
    end

    methods
        function hardwareTriggerScript(obj,src,evt)
            if ~isempty(obj.errorMsg)
                return;
            end

            idx = cellfun(@(c)most.idioms.ifthenelse(most.idioms.isValidObj(c),c==src,false),obj.hDITriggerport);
            scriptFile = obj.scripts{idx};
            [~,file,~] = fileparts(scriptFile);
            onPath = ~isempty(which(scriptFile));

            if obj.hDITriggerport{idx}.lastKnownValue == obj.hDITriggeredge(idx) && obj.trigEnabled(idx)
                try
                tstart = tic;
                if onPath
                    eval(file);
                else
                    run(obj.scripts{idx});
                end
                tend = toc(tstart);
                obj.scriptruntime(idx) = tend*1000;
                catch ME
                    obj.deinit();
                    most.ErrorHandler.logAndReportError(false,ME);
                    obj.errorMsg = sprintf('Triggered script %s errored during execution.',obj.scripts{idx});
                end
            end
        end 
    
        function softwareTriggerScript(obj,scriptIdx)
            if ~isempty(obj.errorMsg)
                return;
            end

            scriptFile = obj.scripts{scriptIdx};
            [~,file,~] = fileparts(scriptFile);
            onPath = ~isempty(which(scriptFile));

            try
                tstart = tic();

                if onPath
                    eval(file);
                else
                    run(scriptFile);
                end

                tend = toc(tstart);
                obj.scriptruntime(scriptIdx) = tend*1000;

            catch ME
                most.ErrorHandler.logAndReportError(ME);
                msg = sprintf('Error executing function %s\n\n%s',scriptFile,ME.message);
                hFig_ = errordlg(msg,char(obj.scripts{scriptIdx}));
                most.gui.centerOnScreen(hFig_);
                obj.deinit();
                obj.errorMsg = msg;
            end
        end
    end

    %% Property Setter/Getter
    methods
        function set.hDITriggerport(obj,val)
            val = obj.hResourceStore.filterByName(val);
            obj.deinit();

            cellfun(@(port)port.unregisterUser(obj),obj.hDITriggerport);

            validMask = cellfun(@(v)most.idioms.isValidObj(v),val) & ...
                cellfun(@(s)~isempty(s),obj.scripts) & ...
                (cellfun(@(v)isa(v,'dabs.resources.ios.DI'),val) | ...
                cellfun(@(v)isa(v,'dabs.resources.ios.PFI'),val));

            for idx = find(~validMask)'
                val{idx} = dabs.resources.Resource.empty(1,0);
            end

            obj.hDITriggerport = val;


            validIndices = find(validMask);
            for idx = validIndices'
                [~,UserDescription,~] = fileparts(obj.scripts{idx});
                if ~isempty(UserDescription)
                    obj.hDITriggerport{idx}.registerUser(obj,UserDescription);
                end
            end
        end

        function set.scripts(obj, val)
            validateattributes(val,{'cell'},{});
            cellfun(@(c)validateattributes(c,{'char'},{'scalartext'}),val);
            obj.scripts = val;
        end

        function validateScripts(obj)
            %make sure this is an .m file of a script or function with no
            %input arguments or just varargin as an input argument.

            scripts_ = obj.scripts;
            for ids=1:numel(scripts_)
                if isfile(scripts_{ids})
                    funcStr = scripts_{ids};
                    [FILEPATH,NAME,EXT] = fileparts(funcStr);
                    assert(strcmpi(EXT,'.m'),'Specified file is not a .m file');
                    %make sure it is a valid .m file that can be run
                    builtin('_mcheck', funcStr);
                    %If function make sure it requires no input arguments
                    ID = local_isfunction(funcStr);
                    if ID > 0
                        numArgs = nargin(funcStr);
                        errStr = sprintf(['triggerScript functions must take no arguments or only varargin'...
                            '\nProblematic file: %s'],funcStr);
                        if numArgs < 0 %varargin specified as an input argument
                            assert(abs(numArgs) == 1,errStr);
                        else
                            assert(~numArgs,errStr);
                        end
                    end

                    charMask = FILEPATH == '+';
                    firstplus = find(charMask);
                    if ~isempty(firstplus)
                        ext = FILEPATH(firstplus(1)+1:end);
                        newStr = strrep(ext,'\+','.');
                        NAME = sprintf('%s.%s', newStr, NAME);
                    end
                else
                    funcStr = scripts_{ids};
                end
                
                scripts_{ids} = funcStr;
            end
            
            if isrow(scripts_)
                scripts_ = scripts_';
            end
            obj.scripts = scripts_;

            function ID = local_isfunction(FUNNAME)
                try
                    nargin(FUNNAME) ; % nargin errors when FUNNAME is not a function
                    ID = 1  + isa(FUNNAME, 'function_handle') ; % 1 for m-file, 2 for handle
                catch ME
                    % catch the error of nargin
                    switch (ME.identifier)
                        case 'MATLAB:nargin:isScript'
                            ID = -1 ; % script
                        case 'MATLAB:narginout:notValidMfile'
                            ID = -2 ; % probably another type of file, or it does not exist
                        case 'MATLAB:narginout:functionDoesnotExist'
                            ID = -3 ; % probably a handle, but not to a function
                        case 'MATLAB:narginout:BadInput'
                            ID = -4 ; % probably a variable or an array
                        otherwise
                            ID = 0 ; % unknown cause for error
                    end
                end
            end
        end

        function set.trigEnabled(obj,val)
            validateattributes(val,{'logical'},{'vector','numel',5});
            obj.trigEnabled = val;
        end

        function set.scriptruntime(obj,val)
            tooLongMask = val > 300;
            scriptsTakingTooLong = obj.scripts(tooLongMask);
            newScriptsTakingTooLongMask = cellfun(@(s)~any(strcmpi(s,obj.knownScriptsTakingTooLong)),scriptsTakingTooLong);

            if any(newScriptsTakingTooLongMask)
                obj.knownScriptsTakingTooLong = [obj.knownScriptsTakingTooLong, scriptsTakingTooLong(newScriptsTakingTooLongMask)];
                most.idioms.warn('The following scripts take longer than 300 ms to execute, which can cause issues during acquisition');
                disp(obj.knownScriptsTakingTooLong);
            end
            
            obj.scriptruntime = val;
        end
    end
end

function s = defaultMdfSection()
s = [...
    most.HasMachineDataFile.makeEntry('DITriggerport',{{'';'';'';'';''}},'resource name of the digital input channel that receives the TTL signal (e.g. /vDAQ0/D0.1)')...
    most.HasMachineDataFile.makeEntry('DITriggeredge',[true, true, true, true, true],'resource name of the digital input channel edge to trigger at (e.g. rising)')...
    most.HasMachineDataFile.makeEntry('scripts_s',{{'';'';'';'';''}},'name of function or script to trigger')...
    most.HasMachineDataFile.makeEntry('trigEnabled',[false,false,false,false,false],'Whether to enable a function for external triggering.')...
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

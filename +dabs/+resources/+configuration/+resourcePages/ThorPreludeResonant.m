classdef ThorPreludeResonant < dabs.resources.configuration.ResourcePage
    properties
        AmplitudeCalibrationButton;
        SyncInputDropdown;
        SettleTimeEdit;
        AngularRangeEdit;
    end
    
    methods
        function calibrateAndRedraw(obj, scanner, button)
            try
                answer = questdlg(['This command will require control of the Prelude''s resonant axis. ' ...
                    'Please ensure that mirror is powered and there are no obstructions that would ' ...
                    'impact amplitude changes. Beginning calibration will also commit the settings ' ...
                    'below for calibration.'] ...
                    , 'WARNING: HARDWARE TURNING ON', 'Begin Calibration', 'Cancel', 'Begin Calibration');
                if isempty(answer) || strcmp(answer, 'Cancel')
                    return;
                end
                obj.apply();
                scanner.calibrateAmplitude();
                button.BackgroundColor = [0.94, 0.94, 0.94];
            catch ME
                button.BackgroundColor = most.constants.Colors.lightRed;
                rethrow(ME);
            end
        end
    end
    
    methods (Static, Access = private)
        function validateNumberInput(edit, suffix)
            assert(isgraphics(edit) && strcmp(edit.Type, 'uicontrol') && strcmp(edit.Style, 'edit'));
            if contains(edit.String, suffix)
                str = strip(extractBefore(string(edit.String), suffix));
            else
                str = strip(string(edit.String));
            end
            try
                num = eval(str);
            catch
                edit.String = edit.UserData.Previous;
                return;
            end
            if isnumeric(num) && isscalar(num) && isreal(num) && ~isnan(num)
                formatted = sprintf('%g%s', num, suffix);
                edit.String = formatted;
                edit.UserData.Previous = formatted;
                edit.UserData.Value = num;
            else
                edit.String = edit.UserData.Previous;
            end
        end
    end
    
    %% impl ResourcePage
    methods
        function makePanel(obj, hParent)
            assert(isgraphics(hParent), 'expected hParent to be a valid graphics parent.');
            topdown = uiflowcontainer('v0', Parent = hParent, FlowDirection = 'TopDown');
            
            left2right = uiflowcontainer('v0', Parent = topdown, FlowDirection = 'LeftToRight' ...
                , Units = 'pixels');
            set(left2right, HeightLimits = [50, 100]);
            pane = uipanel(left2right);
            scanner = obj.hResource;
            obj.AmplitudeCalibrationButton = uicontrol(Parent = pane ...
                , Style = 'pushbutton' ...
                , String = 'Calibrate Amplitude I/O' ...
                , Units = 'normalized', Position = [0.3, 0.1, 0.4, 0.8] ...
                , Callback = @(button,~)obj.calibrateAndRedraw(scanner, button));
            
            left2right = uiflowcontainer('v0', Parent = topdown, FlowDirection = 'LeftToRight' ...
                , Units = 'pixels');
            set(left2right, HeightLimits = [70, 70]);
            grid = uigridcontainer('v0', Parent = left2right);
            set(grid, GridSize = [3, 2], HorizontalWeight = [1.5, 3]);
            
            % sync input
            uicontrol(Parent = grid ...
                , Style = 'text', String = 'Sync Signal Input:' ...
                , HorizontalAlignment = 'right', FontWeight = 'bold');
            obj.SyncInputDropdown = uicontrol(Parent = grid ...
                , Style = 'popupmenu' ...
                , String = {' '});
            
            % settle time
            uicontrol(Parent = grid ...
                , Style = 'text', String = 'Settle Time:' ...
                , HorizontalAlignment = 'right', FontWeight = 'bold');
            obj.SettleTimeEdit = uicontrol(Parent = grid ...
                , Style = 'edit' ...
                , String = '0 sec' ...
                , Callback = @(edit, ~)obj.validateNumberInput(edit, ' sec') ...
                , UserData = struct(Previous = ''), Value = 0);
            
            % angular range
            uicontrol(Parent = grid ...
                , Style = 'text', String = 'Angular Range:' ...
                ,  HorizontalAlignment = 'right', FontWeight = 'bold');
            degsymbol = char(0xB0);
            obj.AngularRangeEdit = uicontrol(Parent = grid ...
                , Style = 'edit' ...
                , String = ['0' degsymbol] ...
                , Callback = @(edit, ~)obj.validateNumberInput(edit, degsymbol) ...
                , UserData = struct(Previous = '', Value = 0));
        end
        
        function redraw(obj)
            scanner = obj.hResource;
            digitalinputs = obj.hResourceStore.filterByClass(?dabs.resources.ios.DI);
            if isempty(digitalinputs)
                obj.SyncInputDropdown.String = {' '};
            else
                if iscell(digitalinputs)
                    for iIn = 1:length(digitalinputs)
                        inputobj = digitalinputs{iIn};
                        digitalinputs{iIn} = inputobj.name;
                    end
                    names = digitalinputs;
                else
                    names = {digitalinputs.name};
                end
                obj.SyncInputDropdown.String = [{' '}, names];
            end
            if most.idioms.isValidObj(scanner.hDISync)
                lIsDevice = strcmp(obj.SyncInputDropdown.String, scanner.hDISync.name);
                iSelection = find(lIsDevice, 1);
                if isempty(iSelection)
                    iSelection = 1;
                end
            else
                iSelection = 1;
            end
            obj.SyncInputDropdown.Value = iSelection;
            if 1 == iSelection
                dropdownColor = most.constants.Colors.lightRed;
            else
                dropdownColor = [0.94, 0.94, 0.94];
            end
            obj.SyncInputDropdown.BackgroundColor = dropdownColor;
            obj.SettleTimeEdit.String = sprintf('%g sec', scanner.settleTime_s);
            obj.SettleTimeEdit.UserData.Value = scanner.settleTime_s;
            obj.AngularRangeEdit.String = sprintf('%g%s', scanner.angularRange_deg, char(0xB0));
            obj.AngularRangeEdit.UserData.Value = scanner.angularRange_deg;
            
            if scanner.IsCalibrated
                buttonColor = [0.94, 0.94, 0.94];
            else
                buttonColor = most.constants.Colors.lightRed;
            end
            set(obj.AmplitudeCalibrationButton, BackgroundColor = buttonColor);
        end
        
        function apply(obj)
            scanner = obj.hResource;
            dropdownPair = get(obj.SyncInputDropdown, {'String', 'Value'});
            syncport = obj.hResourceStore.filterByName(dropdownPair{1}{dropdownPair{2}});
            scanner.hDISync = syncport;
            scanner.angularRange_deg = obj.AngularRangeEdit.UserData.Value;
            scanner.settleTime_s = obj.SettleTimeEdit.UserData.Value;
            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end
        
        function remove(obj)
            obj.hResource.deleteAndRemoveMdfHeading();
        end
    end
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

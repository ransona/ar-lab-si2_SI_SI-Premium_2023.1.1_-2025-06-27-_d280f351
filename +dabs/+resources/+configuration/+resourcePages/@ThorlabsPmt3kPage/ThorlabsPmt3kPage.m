classdef ThorlabsPmt3kPage < dabs.resources.configuration.ResourcePage
    %% PROPERTIES
    
    properties
        DeviceDropdown;
        WavelengthEdit;
        WavelengthColorPanel;
        DetectorLabel;
        AutoOnCheckbox;
        
        % persistently on listeners. These listeners are not tied to device
        % lifetime and can be left on.
        WavelengthListener(:,1) event.listener;
        AutoOnListener(:,1) event.listener;
    end
    
    %% METHODS
    methods
        function obj = ThorlabsPmt3kPage(ResourceModel, GuiParent)
            assert(isa(ResourceModel, 'dabs.thorlabs.Pmt3k'));
            obj@dabs.resources.configuration.ResourcePage(ResourceModel, GuiParent);
            obj.bindToModel();
        end
        
        function delete(obj)
            delete(obj.WavelengthListener);
            delete(obj.AutoOnListener);
        end
        
        % dabs.resources.configuration.ResourcePage
        makePanel(obj, GuiParent);
        
        function redraw(obj)
            import dabs.thorlabs.pmt3k.getNumDevices;
            import dabs.thorlabs.pmt3k.getSerialNumber;
            import dabs.thorlabs.pmt3k.getDetectorType;
            
            numDevices = double(getNumDevices());
            serialNumbers = strings(numDevices, 1);

            if isempty(serialNumbers)
                % this can rarely occur but only if ScanImage was freshly started
                % without any PMT connected.
                obj.DeviceDropdown.BackgroundColor = 'r';
                return;
            end

            for iDevice = 1:numDevices
                serialNumbers(iDevice) = sprintf('(%d): %s', iDevice, getSerialNumber(iDevice));
            end
            
            obj.DeviceDropdown.String = [""; serialNumbers];
            Model = obj.hResource;
            Dropdown = obj.DeviceDropdown;
            if isempty(Model.Index)
                set(Dropdown, 'Value', 1, 'BackgroundColor', 'y');
                obj.DeviceDropdown.Value = 1; % empty
                obj.DetectorLabel.String = "N/A";
            else
                set(Dropdown, 'Value', 1 + Model.Index, 'BackgroundColor', [.94, .94, .94]);
                obj.DetectorLabel.String = string(getDetectorType(Model.Index));
            end
        end
        
        function apply(obj)
            % propagate to model
            % We do this backwards so setting the power value is last in case of
            % weirdness after unpowering the PMT.
            
            Model = obj.hResource;
            Model.wavelength_nm = obj.WavelengthEdit.Value;
            Model.autoOn = obj.AutoOnCheckbox.Value == obj.AutoOnCheckbox.Max;
            
            %% Device Selection
            % recall that the indices are off by one due to the empty option at index 1
            % hence, selection 2 is actually device index 1
            index = obj.DeviceDropdown.Value - 1;
            if 0 == index
                Model.Index = [];
            else
                Model.Index = index;
            end
            Model.reinit();
            Model.saveMdf();
        end
        
        function remove(obj)
            obj.hResource.deleteAndRemoveMdfHeading(); % from HasMachineDataFile.
        end
    end
    
    methods (Access = private)
        function bindToModel(obj)
            Pmt = obj.hResource;
            
            %% sync with model
            obj.updateWavelength(Pmt.wavelength_nm);
            obj.updateAutoOnState(Pmt.autoOn);
            
            %% listeners
            addPropertyListener = @(propertyName, callback)most.ErrorHandler.addCatchingListener(...
                Pmt, propertyName, 'PostSet' ...
                , @(~,Event)callback(Event.AffectedObject.(propertyName)) ...
                );
            obj.WavelengthListener = addPropertyListener('wavelength_nm', @obj.updateWavelength);
            obj.AutoOnListener = addPropertyListener('autoOn', @obj.updateAutoOnState);
        end
        
        function updateAutoOnState(obj, isAutoOnModeEnabled)
            obj.hResource.autoOn = isAutoOnModeEnabled;
            if isAutoOnModeEnabled
                obj.AutoOnCheckbox.Value = obj.AutoOnCheckbox.Max;
            else
                obj.AutoOnCheckbox.Value = obj.AutoOnCheckbox.Min;
            end
        end
        
        function updateWavelength(obj, lambdaNm)
            obj.WavelengthColorPanel.BackgroundColor = most.idioms.wavelengthToRGB(lambdaNm);
            set(obj.WavelengthEdit ...
                , 'Value', lambdaNm ...
                , 'String', sprintf(obj.WavelengthEdit.UserData.DisplayFormat, lambdaNm));
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

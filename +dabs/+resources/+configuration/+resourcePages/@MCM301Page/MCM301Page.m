classdef MCM301Page < dabs.resources.configuration.ResourcePage
    properties
        ComDropdown matlab.ui.control.UIControl;
        HardwareInfoLabel matlab.ui.control.UIControl;
        AxisPanels matlab.ui.container.Panel;
        EnabledCheckboxes matlab.ui.control.UIControl;
        JoystickBlinkButtons matlab.ui.control.UIControl;
        AxisLabels matlab.ui.control.UIControl;
        StatusLabels matlab.ui.control.UIControl;
    end
    
    %% ResourcePage
    methods
        makePanel(obj, parent);
        
        redraw(obj);
        
        function apply(obj)
            index = obj.ComDropdown.Value - 1;
            if 0 == index
                newCom = dabs.resources.SerialPort.empty();
            else
                newCom = obj.ComDropdown.UserData.Ports{index};
            end
            if ~isequal(obj.hResource.Com, newCom)
                obj.hResource.Com = newCom;
                obj.hResource.saveMdf();
                obj.hResource.reinit();
                obj.redraw();
                return;
            end
            
            if isempty(newCom)
                return;
            end
            
            mcm = obj.hResource.Controller;
            enabledCheckboxValue = [obj.EnabledCheckboxes.Max];
            checkboxValue = [obj.EnabledCheckboxes.Value];
            isEnabled = enabledCheckboxValue == checkboxValue;
            isChanged = xor(isEnabled, obj.hResource.IsAxisEnabled);
            mcm.enableMotor(find(isChanged & isEnabled));
            mcm.disableMotor(find(isChanged & ~isEnabled));
            
            obj.hResource.reinit();
            obj.redraw();
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

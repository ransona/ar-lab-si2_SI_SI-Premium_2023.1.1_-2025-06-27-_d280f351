function redrawPowerBoxPane(obj)
    obj.etPowerBoxName.String = obj.selectedPowerBox.name;
    obj.pmPowerBoxType.Value = 1 + obj.selectedPowerBox.useSampleAbsolute;
    obj.etPowerBoxPower.bindings = {obj.selectedPowerBox,'powers','value',[],'scaling',100};
    obj.pmPowerBoxLocked.Value = obj.selectedPowerBox.locked;
    obj.pmPowerBoxLocation.Enable = most.gui.OnOff(...
        obj.selectedPowerBox.useSampleAbsolute && ~obj.pmPowerBoxLocked.Value);

    obj.pmPowerBoxMaskEnable.Enable = 'on';
    obj.pmPowerBoxMaskEnable.Value = ~isempty(obj.selectedPowerBox.mask);
    obj.setPowerBoxEnableMask();
    [yRes, xRes] = size(obj.selectedPowerBox.mask);
    obj.etPowerBoxMaskResX.String = num2str(xRes);
    obj.etPowerBoxMaskResY.String = num2str(yRes);
    obj.pmPowerBoxMaskBackground.Value = 2 - isnan(obj.selectedPowerBoxDisplay.background);
    obj.setPowerBoxBackground();

    hPowerBoxDisplay = obj.selectedPowerBoxDisplay;
    obj.etPowerBoxBrushValue.bindings = {hPowerBoxDisplay,'brushValue','value'};
    obj.slPowerBoxBrushValue.bindings = {hPowerBoxDisplay,'brushValue',1};
    obj.etPowerBoxBrushSize.bindings = {hPowerBoxDisplay,'brushSize','value'};
    obj.slPowerBoxBrushSize.bindings = {hPowerBoxDisplay,'brushSize',1};
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

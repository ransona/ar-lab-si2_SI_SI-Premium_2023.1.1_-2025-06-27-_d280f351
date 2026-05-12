function finishPowerBoxEdit(obj,varargin)
    obj.hSamplePowerBoxFlow.Visible = 'off';
    obj.roiTable.Visible = 'on';
    set([obj.pbNew, obj.pbDel, ...
        obj.pbMoveBottom, obj.pbMoveDown, obj.pbMoveUp, obj.pbMoveTop, ...
        obj.hButtonFlow, obj.hNameFlow], 'Visible', 'on');

    obj.setEditorGroupAndMode(obj.editingGroup,obj.scannerSet,obj.editorMode);
    obj.selectedPowerBox = scanimage.components.beams.PowerBox.empty(1,0);

    obj.etPowerBoxPower.bindings = {};
    obj.etPowerBoxBrushValue.bindings = {};
    obj.slPowerBoxBrushValue.bindings = {};
    obj.etPowerBoxBrushSize.bindings = {};
    obj.slPowerBoxBrushSize.bindings = {};
    obj.pmSelectedPowerBox.pmValue = '';

    if most.idioms.isValidObj(obj.selectedPowerBoxDisplay)
        obj.selectedPowerBoxDisplay.enableBrush = false;

        obj.hFig.Pointer = 'arrow';
        obj.hFig.WindowButtonMotionFcn = [];
        obj.selectedPowerBoxDisplay.hBrushPreview.Visible = 'off';
    end
    obj.selectedPowerBoxDisplay = scanimage.guis.roigroupeditor.powerbox.SamplePowerBox.empty(1,0);

    obj.cbPowerBoxBrushEnable.Value = false;
    obj.hPowerBoxDisplayManager.setAllVisibility(obj.showPowerBoxes);
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

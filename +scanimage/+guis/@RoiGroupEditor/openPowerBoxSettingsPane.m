function openPowerBoxSettingsPane(obj, hPowerBox, hPowerBoxDisplay)
    obj.selectedPowerBox = hPowerBox;
    obj.selectedPowerBoxDisplay = hPowerBoxDisplay;

    obj.changeSelection();
    obj.fixTableCheck()

    %% Swap Pane
    set([obj.hBlankPanel, obj.hNewImagingRoiPanel, obj.hNewStimRoiPanel, obj.hNewAnalysisRoiPanel, ...
        obj.hImagingRoiPropsPanel, obj.hGlobalImagingSfPropsPanel, obj.hImagingSfPropsPanel, ...
        obj.hStimRoiPropsPanel, obj.hAnalysisRoiPropsPanel, obj.hAnalysisSfPropsPanel, ...
        obj.hStimOptimizationPanel, obj.hStimQuickAddPanel, obj.hSlmPropsPanel], 'Visible', 'off');
    most.idioms.safeDeleteObj(obj.hSelectedObjectListeners);
    obj.roiTable.Visible = 'off';

    roiNames = arrayfun(@(roi)roi.name,obj.editingGroup.rois,'UniformOutput',false);
    contextImageOptions = arrayfun(@(ci)ci.name,obj.hContextImages,'UniformOutput',false);
    obj.pmPowerBoxContextImage.String = [{''} contextImageOptions{:}];
    obj.pmPowerBoxLocation.String = [{''} roiNames{:} contextImageOptions{:}];

    obj.hSamplePowerBoxFlow.Visible = 'on';
    set([obj.pbNew, obj.pbDel], 'Visible', 'off');
    obj.roiTable.Visible = 'off';
    obj.pbBitmapBrushEnable = false;

    set([obj.pbMoveBottom, obj.pbMoveDown, obj.pbMoveUp, obj.pbMoveTop, ...
        obj.hButtonFlow, obj.hNameFlow, obj.hCopyButtonFlow,obj.hSlmPatternTypeFlow,...
        obj.hSlmBitmapFlow], 'Visible', 'off');

    %% Redraw
    obj.redrawPowerBoxPane();
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

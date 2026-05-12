function updateGlobalPanel(obj)
    if ~obj.isGuiLoaded ...
            || ~obj.editorModeIsImaging ...
            || ~strcmp(obj.hGlobalImagingSfPropsPanel.Visible, 'on')
        return;
    end

    if isempty(obj.editingGroup.rois) || isempty([obj.editingGroup.rois.scanfields])
        cellfun(@(x)set(x,'Enable','off'),obj.hGlobalImagingSfPropsPanelCtls.all);
        cellfun(@(x)set(x,'String',''),obj.hGlobalImagingSfPropsPanelCtls.allFields);
        return;
    end

    allSfs = [obj.editingGroup.rois.scanfields];
    N = numel(allSfs);

    for i = N:-1:1
        centerPoints(i,:) = allSfs(i).centerXY;
        sizes(i,:) = allSfs(i).sizeXY;
        rotations(i) = allSfs(i).rotation;
        resolutions(i,:) = allSfs(i).pixelResolutionXY;
        ratios(i,:) = resolutions(i,:) ./ sizes(i,:);
    end

    tolerance = 0.0000000001;
    hPanelControls = obj.hGlobalImagingSfPropsPanelCtls;
    fuzzyEq = @(A, B)most.floatingpoint.fuzzyEquals(A, B);
    set([hPanelControls.etCenterX, hPanelControls.etCenterY, ...
        hPanelControls.etWidth, hPanelControls.etHeight, ...
        hPanelControls.etRotation, ...
        hPanelControls.etPixCountX, hPanelControls.etPixCountY, ...
        hPanelControls.etPixRatioX, hPanelControls.etPixRatioY], 'String', 'Various');

    if all(fuzzyEq(centerPoints(1,1), centerPoints(:,1)))
        hPanelControls.etCenterX.String = num2str(centerPoints(1,1) * obj.xyUnitFactor + obj.xyUnitOffset(1));
    end

    if all(fuzzyEq(centerPoints(1,2), centerPoints(:,2)))
        hPanelControls.etCenterY.String = num2str(centerPoints(1,2) * obj.xyUnitFactor + obj.xyUnitOffset(2));
    end

    if all(fuzzyEq(sizes(1,1), sizes(:,1)))
        hPanelControls.etWidth.String = num2str(sizes(1,1) * obj.xyUnitFactor);
    end

    if all(fuzzyEq(sizes(1,2), sizes(:,2)))
        hPanelControls.etHeight.String = num2str(sizes(1,2) * obj.xyUnitFactor);
    end

    if all(fuzzyEq(rotations(1), rotations))
        hPanelControls.etRotation.String = num2str(rotations(1));
    end

    if all(fuzzyEq(resolutions(1,1), resolutions(:,1)))
        hPanelControls.etPixCountX.String = num2str(resolutions(1,1));
    end

    if all(fuzzyEq(resolutions(1,2), resolutions(:,2)))
        hPanelControls.etPixCountY.String = num2str(resolutions(1,2));
    end

    if all(fuzzyEq(ratios(1,1), ratios(:,1)))
        hPanelControls.etPixRatioX.String = num2str(ratios(1,1) / obj.xyUnitFactor);
    end

    if all(fuzzyEq(ratios(1,2), ratios(:,2)))
        hPanelControls.etPixRatioY.String = num2str(ratios(1,2) / obj.xyUnitFactor);
    end

    cellfun(@(x)set(x,'Enable','on'),obj.hGlobalImagingSfPropsPanelCtls.all);
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

function scrollWheelFcn(obj, ~, eventData)
    currentKeyModifiers = get(obj.hFig, 'currentModifier');
    isShiftPressed = ismember('shift', currentKeyModifiers);
    scrollCount = eventData.VerticalScrollCount;

    if strcmp(obj.viewMode, '3D') && most.gui.isMouseInAxes(obj.h3DViewMouseFindAxes)
        zoomSpeedFactor = 1.1;
        cameraAngle = obj.h3DViewAxes.CameraViewAngle;
        scroll = zoomSpeedFactor ^ double(scrollCount);
        cameraAngle = cameraAngle * scroll;
        obj.h3DViewAxes.CameraViewAngle = cameraAngle;
        return;
    end

    if most.gui.isMouseInAxes(obj.h2DMainViewAxes)
        if isShiftPressed
            traverseZ(-scrollCount);
        else
            originalLocation = most.gui.getPointerLocation(obj.h2DMainViewAxes);
            obj.mainViewFov = obj.mainViewFov * 1.5^scrollCount;
            newLocation = most.gui.getPointerLocation(obj.h2DMainViewAxes);
            obj.mainViewPosition = obj.mainViewPosition...
                + originalLocation - newLocation;
        end
    elseif most.gui.isMouseInAxes(obj.h2DProjectionViewAxes)
        if isShiftPressed
            traverseZ(scrollCount * 2);
        else
            originalLocation = most.gui.getPointerLocation(obj.h2DProjectionViewAxes);
            projectionDistance = obj.zProjectionRange(2) - obj.zProjectionRange(1);
            rangeCenter = sum(obj.zProjectionRange) / 2;
            newDistance = projectionDistance * 1.5^scrollCount;
            newZRange = rangeCenter + [-newDistance newDistance] / 2;
            obj.zProjectionRange = newZRange;
            newLocation = most.gui.getPointerLocation(obj.h2DProjectionViewAxes);
            obj.zProjectionRange = obj.zProjectionRange + originalLocation(2) - newLocation(2);
        end
    elseif most.gui.isMouseInAxes(obj.h2DZScrollAxes)
        increment = scrollCount * diff(obj.zProjectionRange) / 10;
        traverseZ(floor(increment * 100) / 100);
    end

    function traverseZ(increment)
        newZ = obj.editorZ + increment;

        shouldSnap = (increment < 0 && obj.editorZ > obj.minInterestingZ)...
            || (increment >= 0 && obj.editorZ < obj.maxInterestingZ);
        if ~shouldSnap
            obj.editorZ = newZ;
            return;
        end

        if increment < 0
            nextZIdx = find(obj.interestingZs < obj.editorZ, 1, 'last');
            obj.editorZ = max(obj.interestingZs(nextZIdx), newZ);
        else
            nextZIdx = find(obj.interestingZs > obj.editorZ, 1, 'first');
            obj.editorZ = min(obj.interestingZs(nextZIdx), newZ);
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

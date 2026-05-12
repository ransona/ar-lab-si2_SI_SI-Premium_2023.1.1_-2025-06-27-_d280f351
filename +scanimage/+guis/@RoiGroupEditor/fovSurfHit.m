function fovSurfHit(obj,src,evt)
    persistent lastPt;
    persistent obluem;

    if strcmp(evt.EventName, 'Hit')
        lastPt = obj.h2DMainViewAxes.CurrentPoint(1,1:2);
        set(obj.hFig,'WindowButtonMotionFcn',@obj.fovSurfHit,'WindowButtonUpFcn',@obj.fovSurfHit);

        if obj.slmBitmapBrushEnable
            obluem = double(obj.h2DScannerFovSurf.CData(:,:,3))/255;
            slmPt = evt.IntersectionPoint([1 2]) - obj.slmPatternSfParent.centerXY;
            applyBrush(slmPt);
        end
    elseif strcmp(evt.EventName, 'WindowMouseMotion')
        if obj.slmBitmapBrushEnable
            slmPt = obj.h2DMainViewAxes.CurrentPoint(1,1:2) - obj.slmPatternSfParent.centerXY;
            applyBrush(slmPt);
        else
            cp = obj.h2DMainViewAxes.CurrentPoint(1,1:2);
            ctr = obj.slmPatternSfParent.centerXY;

            obj.enableListeners = false;

            obj.slmPatternSfParent.centerXY = ctr + cp - lastPt;

            % apply constraints
            obj.satisfyConstraints(obj.slmPatternSfParent);
            d = obj.slmPatternSfParent.centerXY - ctr;

            % move slm pattern?
            % if it is a point array and shift is held OR if it is a bitmap
            if ismember('shift', get(obj.hFig, 'currentModifier')) || obj.slmPatternTypeIsBitmap
                for roi = obj.editingGroup.rois
                    roi.scanfields(1).centerXY = roi.scanfields(1).centerXY + d;
                end
                obj.updateScanPathCache();
                obj.updateDisplay();
            end

            obj.enableListeners = true;

            % update fov
            obj.updateFovLines()

            lastPt = cp;
        end
    else
        if obj.slmBitmapBrushEnable
            obj.hFig.WindowButtonMotionFcn = @obj.brushHover;
            obj.slmPatternSfParent.slmPattern = double(obj.h2DScannerFovSurf.CData(:,:,3))/255;
        else
            obj.hFig.WindowButtonMotionFcn = [];
        end
        obj.hFig.WindowButtonUpFcn = [];
        obj.updateTable();
    end

    function applyBrush(pt)
        % identify region affected
        [ptis, rs] = findBrushAffectedInds(obj,pt);

        % cache vals
        ocdat = obj.h2DScannerFovSurf.CData;
        ocdatbm = double(ocdat(:,:,3));
        sep = obj.slmBitmapBrushSoftEdgePct;

        % determine blue map values with soft edge
        % in order to prevent the soft edge from getting darkened
        % as the brush moves, we do a gradient from a cached
        % version of the bitmap from before this stroke started
        ovws = min(1,max(0,(sep - (1-rs)) / sep)); % old val weights
        bvs = (1-ovws) * obj.slmBitmapBrushValue + ovws.*obluem(ptis);

        % decide whether the new value is better
        omap = ocdatbm(ptis)/255;
        diffso = abs(obluem(ptis) - omap);
        diffsn = abs(obluem(ptis) - bvs);
        msk = diffsn < diffso;
        bvs(msk) = omap(msk);

        % apply new blue mask
        ocdatbm(ptis) = bvs * 255;
        ocdat(:,:,3) = uint8(ocdatbm);

        % calc and apply red mask
        rm = zeros(size(ocdatbm),'uint8');
        rvs = (1-ovws);
        rm(ptis) = uint8(min(rvs*255,ocdatbm(ptis)));
        ocdat(:,:,1) = rm;

        % determine green map values with soft edge
        ovws = min(1,max(0,(sep - (1-rs)) / sep)); % old val weights
        gvs = (1-ovws) + ovws.*ocdatbm(ptis)/255;

        % apply new green mask
        ocdatbm(ptis) = gvs * 255;
        ocdat(:,:,2) = uint8(ocdatbm);

        obj.h2DScannerFovSurf.CData = ocdat;
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

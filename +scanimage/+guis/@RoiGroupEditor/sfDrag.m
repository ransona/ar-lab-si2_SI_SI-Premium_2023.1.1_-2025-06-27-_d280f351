function sfDrag(obj,stop)
    persistent ppt;
    persistent snapZs;

    if nargin < 2
        if obj.editorModeIsStim && isa(obj.scannerSet,'scanimage.mroi.scannerset.SLM')
            % slm patterns can't move. do nothing
            return;
        end

        ppt = most.gui.getPointerLocation(obj.h2DProjectionViewAxes);
        snapZs = obj.interestingZs;
        set(obj.hFig,'WindowButtonMotionFcn',@(varargin)obj.sfDrag(false),'WindowButtonUpFcn',@(varargin)obj.sfDrag(true));
        waitfor(obj.hFig,'WindowButtonMotionFcn',[]);
    elseif stop
        set(obj.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
        obj.updateTable();
        obj.setZProjectionLimits();
        obj.satisfyConstraints(obj.selectedObj);
    else
        nwpt = most.gui.getPointerLocation(obj.h2DProjectionViewAxes);
        delta = nwpt - ppt;
        ppt = nwpt;

        %                 nwctr = obj.selectedObj.centerXY(obj.projectionDim)+delta(1);
        nwz = nwpt(2);

        % snap to interesting zs
        [dist,i] = min(abs(nwz-snapZs));
        if dist < diff(obj.zProjectionRange)/100
            nwz = snapZs(i);
        else
            nwz = floor(nwz*100)/100;
        end

        obj.enableListeners = false;
        id = find(obj.selectedObjParent.scanfields == obj.selectedObj);
        [tf,idx] = ismember(nwz,obj.selectedObjParent.zs);
        if tf && (idx ~= id)
            nwz = nwz + 0.0000001;
        end
        obj.selectedObjParent.moveSfById(id,nwz);
        %                 obj.selectedObj.centerXY(obj.projectionDim) = nwctr;
        obj.updateScanPathCache();
        obj.enableListeners = true;

        obj.editorZ = nwz;

        if nwz < obj.zProjectionRange(1)
            obj.zProjectionRange(1) = nwz;
        elseif nwz > obj.zProjectionRange(2)
            obj.zProjectionRange(2) = nwz;
        end

        obj.selectedObjChanged();
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

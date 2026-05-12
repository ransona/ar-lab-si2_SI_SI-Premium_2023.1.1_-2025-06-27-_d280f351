function updateFovLines(obj)
    offset = [0 0];
    ss = obj.scannerSet;
    if obj.editorModeIsSlm && isa(ss,'scanimage.mroi.scannerset.GalvoGalvo')
        offset = obj.slmPatternSfParent.centerXY;
        offset = offset - scanimage.mroi.util.xformPoints([0 0],ss.slm.scannerToRefTransform);
        ss = ss.slm;

        % we are editing an slm pattern for a galvo-galvo-slm set.
        % the fov is movable
        obj.h2DScannerFovSurf.HitTest = 'on';
        obj.h2DScannerFovHandles.Visible = 'on';
    else
        obj.h2DScannerFovSurf.HitTest = 'off';
        obj.h2DScannerFovHandles.Visible = 'off';
        obj.h2DScannerFovSurf.CData = [];
    end

    if isa(ss,'scanimage.mroi.scannerset.SLM') && ss.zeroOrderBlockRadius
        ctr = ss.fovCenterPoint + offset;

        theta = linspace(0,2*pi,20)';
        pts = [ss.zeroOrderBlockRadius*cos(theta) ss.zeroOrderBlockRadius*sin(theta)];
        T = ss.scannerToRefTransform;
        T([7 8]) = 0;
        pts = scanimage.mroi.util.xformPoints(pts,T) + repmat(ctr,20,1);

        obj.h2DScannerFovZeroOrder.XData = pts(:,1);
        obj.h2DScannerFovZeroOrder.YData = pts(:,2);
        obj.h2DScannerFovZeroOrder.Visible = 'on';
    else
        obj.h2DScannerFovZeroOrder.Visible = 'off';
    end

    cps = ss.fovCornerPoints + repmat(offset,4,1);
    obj.fovGridxx = [cps([1 4],1) cps([2 3],1)];
    obj.fovGridyy = [cps([1 4],2) cps([2 3],2)];

    obj.h2DScannerFovSurf.XData = obj.fovGridxx;
    obj.h2DScannerFovSurf.YData = obj.fovGridyy;

    obj.h2DScannerFovHandles.XData(1:2:7) = cps(:,1);
    obj.h2DScannerFovHandles.YData(1:2:7) = cps(:,2);

    switch obj.projectionMode
        case 'XZ'
            obj.h2DScannerFovLines(1).XData = min(obj.fovGridxx(:))*ones(1,2);
            obj.h2DScannerFovLines(2).XData = max(obj.fovGridxx(:))*ones(1,2);
        case 'YZ'
            obj.h2DScannerFovLines(1).XData = min(obj.fovGridyy(:))*ones(1,2);
            obj.h2DScannerFovLines(2).XData = max(obj.fovGridyy(:))*ones(1,2);
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

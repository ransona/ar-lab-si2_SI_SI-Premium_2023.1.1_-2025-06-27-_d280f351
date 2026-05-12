function xCenterInRange(roigroup,scannerset,sf)
    if isempty(sf)
        for roi=roigroup.rois
            for s=roi.scanfields
                constr(s);
            end
        end
    else
        constr(sf);
    end

    function constr(sc)        
        if isa(scannerset, 'scanimage.mroi.scannerset.ResonantGalvoGalvo') && ~isempty(scannerset.scanners{2})
            scanimage.mroi.util.asserttype(scannerset.scanners{2},'scanimage.mroi.scanners.Galvo');
            xGalvoRg = scannerset.scanners{2}.hDevice.travelRange + scannerset.fovCenterPoint(1);
            
            if sc.centerXY(1) - xGalvoRg(2) > 0.000001
                sc.centerXY(1) = xGalvoRg(2);
            elseif sc.centerXY(1) - xGalvoRg(1) < 0.000001
                sc.centerXY(1) = xGalvoRg(1);
            end
        end
        
        xSorted = sort(scannerset.fovCornerPoints(:,1));
        ssLeft = mean(xSorted(1:2));
        ssRight = mean(xSorted(3:4));
        
        if isa(sc, 'scanimage.mroi.scanfield.fields.StimulusField') && sc.isPoint
            hsz = 0;
        else
            hsz = sc.sizeXY(1)/2;
        end
        
        lft = sc.centerXY(1)-hsz;
        rgt = sc.centerXY(1)+hsz;
        
        if min([lft rgt]) < ssLeft
            sc.centerXY(1) = ssLeft + hsz;
        elseif max([lft rgt]) > ssRight
            sc.centerXY(1) = ssRight - hsz;
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

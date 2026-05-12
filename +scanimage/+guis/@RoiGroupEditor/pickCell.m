function pickCell(obj,cpSurf,hitPt)
    imSurf = cpSurf.UserData;
    aff = imSurf.UserData;
    sz = size(imSurf.CData);
    ptXY = floor(scanimage.mroi.util.xformPoints(hitPt,inv(aff)) .* sz([1,2])) + 1;

    % did user click on an already picked cell?
    [tf, iSurf] = ismember(cpSurf, obj.cellPickSurfs);
    if tf
        clkId = obj.cellPickSurfsIdMap{iSurf}(ptXY(1),ptXY(2));
        if clkId
            obj.cellPickSelectedCellIdx = clkId;
            obj.redrawCellPickSurfs();
            return;
        end
    end

    wkngIm = double(max(imSurf.CData,[],3));
    pts = obj.cellPickFunc('pick', wkngIm, ptXY);

    if ~isempty(pts)
        c.pts = pts;
        c.aff = aff;
        c.imSz = sz([1,2]);
        [~, c.surfIdx] = ismember(cpSurf, obj.cellPickSurfs);

        [tf, i] = ismember(obj.editorZ, obj.cellPickZs);
        if tf
            obj.cellPickCellsAtZ{i}(end+1) = c;
            obj.cellPickSelectedCellIdx = numel(obj.cellPickCellsAtZ{i});
        else
            obj.cellPickZs(end+1) = obj.editorZ;
            obj.cellPickCellsAtZ{end+1}= c;
            obj.cellPickSelectedCellIdx = 1;
        end

        obj.updateCellPickButtons();
        obj.redrawCellPickSurfs();
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

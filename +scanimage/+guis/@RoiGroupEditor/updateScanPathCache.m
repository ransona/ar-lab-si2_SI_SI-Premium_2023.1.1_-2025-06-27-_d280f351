function updateScanPathCache(obj,roiIdx)
    if nargin < 2 || isempty(roiIdx) || ~obj.editorModeIsStim
        obj.scanPathCache = [];
        obj.scanPathCacheIds = [];
    elseif isa(obj.scannerSet,'scanimage.mroi.scannerset.SLM')
        % no op; slm patterns cant move
    else
        % selective update of one roi
        if ~isempty(obj.editingGroup.rois(roiIdx).scanfields) && ~obj.editingGroup.rois(roiIdx).scanfields(1).isPause
            sf = obj.editingGroup.rois(roiIdx).scanfields(1);
            ptIds = obj.scanPathCacheIds(roiIdx,:);
            N = ptIds(2)-ptIds(1)+1;

            [stimPts,~] = obj.scannerSet.scanPathStimulusFOV(sf,0,obj.editingGroup.rois(roiIdx).zs(1),0,true,false,N);

            if size(stimPts.G,1) ~= N
                datInds = floor(linspace(1,size(stimPts.G,1),N));
                stimPts.G = stimPts.G(datInds,:);
            end

            if isfield(stimPts,'Z')
                if size(stimPts.Z,1) ~= N
                    datInds = floor(linspace(1,size(stimPts.Z,1),N));
                    stimPts.Z = stimPts.Z(datInds,:);
                end
            else
                stimPts.Z = zeros(N,1);
            end

            obj.scanPathCache.G(ptIds(1):ptIds(2),:) = stimPts.G;
            obj.scanPathCache.Z(ptIds(1):ptIds(2),:) = stimPts.Z;

            % if prev or next are pauses, reinterpolate them
            prev = roiIdx - 1;
            nxt = roiIdx + 1;

            numRoi = numel(obj.editingGroup.rois);
            prev = prev + numRoi*(prev < 1);
            nxt = nxt - numRoi*(nxt > numRoi);

            pausenan(prev);
            pausenan(nxt);

            obj.scanPathCache = obj.scannerSet.interpolateTransits(obj.scanPathCache,false);
        end
    end

    function pausenan(idx)
        if ~isempty(obj.editingGroup.rois(idx).scanfields) && obj.editingGroup.rois(idx).scanfields(1).isPause
            ptIdxs = obj.scanPathCacheIds(idx,:);
            obj.scanPathCache.G(ptIdxs(1):ptIdxs(2),:) = nan;
            obj.scanPathCache.Z(ptIdxs(1):ptIdxs(2),:) = nan;
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

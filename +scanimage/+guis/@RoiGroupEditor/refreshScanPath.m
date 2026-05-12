function refreshScanPath(obj)
    if ~(obj.editorModeIsStim || obj.editorModeIsSlm) || obj.editingGroup.getNumNonPause() <= 0
        obj.updateScanPathCache();
        return;
    end

    if isa(obj.scannerSet,'scanimage.mroi.scannerset.GalvoGalvo')
        % ensure uniform sample rate for all scanners
        sampleRate = obj.scannerSet.scanners{1}.sampleRateHz;
        obj.scannerSet.scanners{2}.sampleRateHz = sampleRate;
        if obj.scannerSet.hasBeams
            obj.scannerSet.beams(1).sampleRateHz = sampleRate;
        end
        if obj.scannerSet.hasFastZ
            obj.scannerSet.fastz(1).sampleRateHz = sampleRate;
        end

        %determine best limit for stim function length to optimize gui speed
        maxp = ceil(10000/numel(obj.editingGroup.rois));
        maxp = max(100,min(maxp,obj.stimpathRenderMaxPoints));

        % get scan path
        [obj.scanPathCache,~,~] = obj.editingGroup.scanStackFOV(obj.scannerSet,0,0,'',0,[],[],[],maxp,~obj.editorModeIsSlm,obj.editorModeIsSlm);
        N = size(obj.scanPathCache.G,1);

        % ensure presence of 'Z' data
        if ~isfield(obj.scanPathCache,'Z')
            obj.scanPathCache.Z = zeros(N,1);
        else
            Z = obj.scanPathCache.Z(:);
            Z = scanimage.mroi.coordinates.Points(obj.scannerSet.hCSReference,[zeros(numel(Z),2) obj.scanPathCache.Z(:)]);
            Z = Z.transform(obj.scannerSet.hCSSampleRelative);
            Z = reshape(Z.points(:,3),size(obj.scanPathCache.Z));
            obj.scanPathCache.Z = Z;
        end

        %compute the start and end indices for each roi
        Nr = numel(obj.editingGroup.rois);
        obj.scanPathCacheIds = ones(Nr,2);
        j = 1;
        for i = 1:Nr
            if ~isempty(obj.editingGroup.rois(i).scanfields)
                T = obj.scannerSet.scanTime(obj.editingGroup.rois(i).scanfields(1),true);
                jdur = min(maxp,obj.scannerSet.nsamples(obj.scannerSet.scanners{1},T));
                obj.scanPathCacheIds(i,:) = [j max(j,j+jdur-1)];
                j = j+jdur;
            end
        end
        obj.scanPathCacheIds(end,end) = N;
        obj.scanPathCacheIds = min(N,max(1,floor(obj.scanPathCacheIds)));
    else
        % for SLM just show points
        obj.scanPathCache = struct('G',{[]},'Z',{[]});
        obj.scanPathCacheIds = [];

        Nr = numel(obj.editingGroup.rois);
        for i = 1:numel(obj.editingGroup.rois)
            if isempty(obj.editingGroup.rois(i).scanfields)
                obj.scanPathCache.G(end+1,:) = nan(1,2);
                obj.scanPathCache.Z(end+1,:) = nan;
            else
                obj.scanPathCache.G(end+1,:) = obj.editingGroup.rois(i).scanfields(1).centerXY;
                obj.scanPathCache.Z(end+1,:) = obj.editingGroup.rois(i).zs;
            end
            obj.scanPathCacheIds(end+1,:) = [i i];
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

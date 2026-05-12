function renderWithVtk(obj, hSurf)
    hRoi = hSurf.UserData.roi;

    assert(3 == exist('mexVtkInterface', 'file'),...
        ['Debug Environment Error. There should be a mexVtkInterface.mexw64 '...
        'somewhere on your path.']);

    % assert rectangular roi
    assert(isscalar(hRoi), 'Cannot render multiple ROIs.');

    set(gcf, 'Pointer', 'watch'); % change gui cursor to hourglass
    drawnow();

    try
        [renderResolution, refToRenderAffine] = getRenderSpace(hRoi);
        pixelsPerDegree = [refToRenderAffine(1,1), refToRenderAffine(2,2)];

        %% Process Volume Data
        renderVolume = repmat(-Inf, [renderResolution, length(obj.zs)]);
        ResampleInterpolant = getResampleInterpolant(hRoi, obj.zs);
        for iz = 1:length(obj.zs)
            pixelToRefAffine = squeeze(ResampleInterpolant(obj.zs(iz)));
            pixelToRenderAffine = refToRenderAffine * pixelToRefAffine;
            zSurface = obj.zSurfs{iz};
            renderVolume(:,:,iz) = resampleImage(zSurface.CData, pixelToRenderAffine, renderResolution);
        end
        renderVolume = int16(flip(flip(renderVolume, 3), 2)); % type and render formatting conversion.

        %% Calculate Voxel Ratio
        micronsPerPixel = obj.hSI.objectiveResolution ./ pixelsPerDegree;
        xySizeUm = (renderResolution .* micronsPerPixel) ./ renderResolution;
        voxelSizeUm = [xySizeUm, getZSizeUm(obj.zs)];
        voxelRatio = voxelSizeUm ./ min(voxelSizeUm);

        %% Render VTK Window
        renderVtkWindow(voxelRatio, renderVolume);
    catch ME
        set(gcf, 'Pointer', 'arrow');
        drawnow();
        rethrow(ME);
    end

    set(gcf, 'Pointer', 'arrow');
    drawnow();
end

function [renderResolution, refToRenderAffine] = getRenderSpace(hRoi)
    % get lowest pixels/degree for performance reasons.
    pixelPerDegree = min(cat(1, hRoi.scanfields.pixelRatio), [], 1);

    minCoord = [Inf, Inf];
    maxCoord = [-Inf, -Inf];
    for iSf = 1:length(hRoi.scanfields)
        Sf = hRoi.scanfields(iSf);
        sfCorners = Sf.cornerpoints();
        minCoord = min([minCoord; sfCorners], [], 1);
        maxCoord = max([maxCoord; sfCorners], [], 1);
    end
    [cornerX, cornerY] = meshgrid([minCoord(1), maxCoord(1)], [minCoord(2), maxCoord(2)]);
    refBoundingBox = [cornerX(:), cornerY(:)];

    renderRefSize = diff([min(refBoundingBox, [], 1);max(refBoundingBox, [], 1)]);
    renderResolution = ceil(pixelPerDegree .* renderRefSize);
    refToRenderAffine = eye(3);
    refToRenderAffine(1:2,3) = (-min(refBoundingBox, [], 1)) .* pixelPerDegree;
    refToRenderAffine(1,1) = pixelPerDegree(1);
    refToRenderAffine(2,2) = pixelPerDegree(2);
end

function renderVtkWindow(voxelRatio, volumeData)
    id = mexVtkInterface('addwindow');

    validateattributes(voxelRatio, {'numeric'}, {'vector', 'numel', 3}, 'renderVtkWindow', 'xyzRatio');
    xyzRatioArguments = num2cell(voxelRatio);
    mexVtkInterface('changescale', id, xyzRatioArguments{:});

    validateattributes(volumeData, {'int16'}, {'3d'}, 'renderVtkWindow', 'volumeData')
    mexVtkInterface('updateImage', id, volumeData);
    
    validVolumeData = double(volumeData(volumeData ~= intmin('int16')));
    meanPixelValue = mean(validVolumeData(:));
    deviation = std(validVolumeData(:));
    lut = meanPixelValue + 3 * [-deviation, deviation];
    mexVtkInterface('changelut', id, lut(1), lut(2));
    
    mexVtkInterface('showwindow', id);
end

function zSizeUmOption = getZSizeUm(zsUm)
    if isscalar(zsUm)
        zSizeUmOption = [];
        return;
    end

    [zUniqueSizesUm, ~, diffedIndices] = unique(round(diff(zsUm), 2));
    % find most common unique size and use that one.
    numUniqueSizes = zeros(size(zUniqueSizesUm));
    for iInd = 1:length(zUniqueSizesUm)
        numUniqueSizes(iInd) = sum(diffedIndices == iInd);
    end
    [~, mostCommonSizeInd] = max(numUniqueSizes);
    mostCommonSize = zUniqueSizesUm(mostCommonSizeInd);
    if ~isscalar(zUniqueSizesUm)
        warning(['VTK volume may not be representative of captured data. ' ...
            'Slice distance is not necessarily uniform. ' ...
            'Assumed most common step size %d'], mostCommonSize);
    end
    zSizeUmOption = mostCommonSize;
end

function SliceInterp = getResampleInterpolant(hRoi, zsUm)
    if isscalar(hRoi.scanfields) % not mroi
        pixToRefAffine = hRoi.scanfields.pixelToRefTransform();
        pixToRefAffineStack = repmat(reshape(pixToRefAffine, [1, 3, 3]), 2, 1);
        zPoints = [zsUm(1), zsUm(end)];
    else
        pixToRefAffineStack = zeros(length(hRoi.scanfields), 3, 3);
        for iScanfield = 1:length(hRoi.scanfields)
            pixToRefAffine = hRoi.scanfields(iScanfield).pixelToRefTransform();
            pixToRefAffineStack(iScanfield,:,:) = pixToRefAffine;
        end
        zPoints = hRoi.zs;
    end

    if verLessThan('matlab', '9.10')
        SliceInterp = most.interp.ParallelInterpolant(zPoints, pixToRefAffineStack);
    else
        SliceInterp = griddedInterpolant(zPoints, pixToRefAffineStack);
    end
end

function resampledImage = resampleImage(imageData, T, newResolution)
    [indexX, indexY] = meshgrid(1:size(imageData, 1), 1:size(imageData,2));

    indexMatrix = cat(3, indexX, indexY, ones(size(indexX)));
    srcPoints = reshape(permute(indexMatrix, [3, 1, 2]), [3, numel(imageData)]);
    destPoints = ceil(T*srcPoints);

    resampledImage = zeros(newResolution);
    resampleCount = zeros(newResolution);
    for iPixel = 1:numel(imageData)
        srcCoord = srcPoints(:,iPixel);
        sx = srcCoord(1);
        sy = srcCoord(2);
        destCoord = destPoints(:,iPixel);
        dx = destCoord(1);
        dy = destCoord(2);
        new = double(imageData(sx,sy));
        prev = resampledImage(dx,dy);
        
        resampleCount(dx,dy) = resampleCount(dx,dy) + 1;
        N = resampleCount(dx,dy);
        resampledImage(dx,dy) = prev + ((new - prev) / N);
    end
    resampledImage(0 == resampleCount) = -Inf;
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

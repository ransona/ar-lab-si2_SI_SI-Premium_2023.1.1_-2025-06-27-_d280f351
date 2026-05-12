function inds = cellDetSemiautoGradient(centerPoint,imData,params)
    % jitter loop -- try nearby points
    jitter = [0, 0;params.jitter];
    for ctr=1:size(jitter,1)
        inds = cellDetGradient(imData, centerPoint+jitter(ctr,:), params);
        if isempty(inds)
            break;
        end
    end
end

function [inds, params] = cellDetGradient(imData, centerPoint, params)
    %% --- detection
    inds = [];

    % now generate angular profile of luminance
    fullRad = round(2*params.radiusRange(2));
    nSamples = 2*fullRad; % oversample by factor of ~2 samp/pixel
    thetas = linspace(0,2*pi,90);

    linProfile=zeros(nSamples,length(thetas));
    for i=1:length(thetas)
        X = [centerPoint(2),centerPoint(2)+fullRad*cos(thetas(i))];
        Y = [centerPoint(1),centerPoint(1)+fullRad*sin(thetas(i))];
        f=most.mimics.improfile(imData,X,Y,nSamples,'bilinear')';
        linProfile(:,i)=f;
    end

    % get the diff matrix ...
    dlp = diff(linProfile);

    % minima/maxima along diff -- that is our initial guess
    if (params.edgeSign == 1)
        [~, edgeIdx] = max(dlp);
    else
        [~, edgeIdx] = min(dlp);
    end

    % now smooth this to eliminate further outliers - start at 0, 1/5, 2/5,
    % 3/5, 4/5 of span, the average these 5 -- in case ends were screwy.
    mEdgeIdx = zeros(5,length(thetas));
    idx = 1:length(thetas);
    mEdgeIdx(1,:) = most.mimics.medfilt1(edgeIdx(idx), round(length(thetas)/10));
    for i=2:5
        sp = round(length(idx)/5);
        idx = [idx(sp+1:end) idx(1:sp)]; % shift indexing
        mEdgeIdx(i,idx) = most.mimics.medfilt1(edgeIdx(idx), round(length(thetas)/10));
    end
    sEdgeIdx = median(mEdgeIdx);

    % eliminate outliers via applying strict size range from settings, interpolating missing
    %  again with sliding window
    inval = find(sEdgeIdx/2 < params.radiusRange(1) | sEdgeIdx/2 > params.radiusRange(2));
    if (length(inval) > 0.5*length(sEdgeIdx))
        disp('roiGenSemiautoGradient::more than half of points exceed your radius tolerance; not detecting.');
        return;
    end
    if ~isempty(inval)
        sEdgeIdx = interpMissing(inval, thetas, sEdgeIdx);
    end

    %% --- setup indices and border indices

    % convert edgeIdx to x, y and actual radius
    fEdgeRad = round(sEdgeIdx)/2;
    X = centerPoint(2) + fEdgeRad.*cos(thetas);
    Y = centerPoint(1) + fEdgeRad.*sin(thetas);
    borderXY = [X ; Y]; % temporary ...
    indices = [];

    % now fill in border -- i.e., return indices
    % so you can fillToBorder ...

    % build tmp new roi, generating corners from border
    if (numel(borderXY) > 0)
        imBounds = size(imData);
        YMat = repmat(1:imBounds(1), imBounds(2),1)';
        XMat = repmat(1:imBounds(2), imBounds(1),1);
        xv = borderXY(1,:);
        xv = [xv xv(1)]';
        yv = borderXY(2,:);
        yv = [yv yv(1)]';
        in = inpolygon(XMat, YMat, xv, yv);
        indices = find(in == 1);
    end
    %% --- run post-steps and assign final output

    % dilate
    if 0 < params.postDilateBy
        if 1 > params.postDilateBy % fractional
            params.postDilateBy = ceil(params.postDilateBy * mean(fEdgeRad));
        end
        indices = scanimage.guis.roigroupeditor.cellpick.dilateRoiIndices(indices, params.postDilateBy, size(imData));
    end

    % remove center
    if (params.postFracRemove > 0)
        lumVals = imData(indices);
        [~, sIdx] = sort(lumVals, 'ascend');
        nR = round(params.postFracRemove*length(indices));
        indices = indices(sIdx(nR:end));
    end

    % final output
    inds = round(indices);
end

function sEdgeIdx  = interpMissing(inval, thetas, sEdgeIdx)
    val = setdiff(1:length(thetas),inval);
    mEdgeIdx = zeros(5,length(thetas));
    mEdgeIdx(1,inval) = interp1(val,sEdgeIdx(val), inval, 'linear', 'extrap');
    mEdgeIdx(:,val) = repmat(sEdgeIdx(val),5,1);
    idx = 1:length(thetas);
    for i=2:5
        sp = round(length(idx)/5);
        idx = [idx(sp+1:end) idx(1:sp)]; % shift indexing
        mEdgeIdx(i,inval) = interp1(idx(val),sEdgeIdx(val), idx(inval), 'linear', 'extrap');
    end
    sEdgeIdx = median(mEdgeIdx);
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

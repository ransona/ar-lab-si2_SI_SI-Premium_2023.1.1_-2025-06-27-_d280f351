function resaveTiff(fileName, AoutImdata, newFileName, customHdr)
%When doing Motion Correction, users may want to clean up reference images and then load them.
%This function takes metadata from an original ScanImage tiff with file name fileName and 
%pairs it with image datae AoutImdata to be saved under a new file name newFileName.
    if nargin < 4 || isempty(customHdr)
       customHdr = []; 
    end
    
    hTif = scanimage.util.ScanImageTiffReader(fileName);
    [fileHeaderStr,frameDescs] = getHeaderDataFromScanImageTiffObj(hTif);
    hTif.close();
    
    [header,~,~,~] = scanimage.util.opentif(fileName);
    [hMroiRoiGroup,~,~] = scanimage.util.readTiffRoiData(fileName);
    
%     v = extractBetween(fileHeaderStr, 'framesPerSlice', sprintf('\n'));
%     val = ['SI.hStackManager.framesPerSlice' v{1} sprintf('\n')];
%     
%     [startIndex,endIndex] = regexp(fileHeaderStr, val);
%     
%     b4 = fileHeaderStr(1:startIndex-1);
%     after = fileHeaderStr(endIndex:end);
% 
%     new = [b4 sprintf('SI.hStackManager.framesPerSlice = %d', size(AoutImdata,4)) after];
    
    %%
    [startIdx, ~] = regexp(fileHeaderStr, 'SI.hStackManager.framesPerSlice');
    b4 = fileHeaderStr(1:startIdx-1);
    endIdx = regexp(fileHeaderStr, 'SI.hStackManager.name');
    after = fileHeaderStr(endIdx:end);
    
    new = [b4 sprintf('SI.hStackManager.framesPerSlice = %d\n', size(AoutImdata,4)) after];
    
    fileHeaderStr = new;
    
    [startIdx, ~] = regexp(fileHeaderStr, 'SI.hStackManager.numSlices');
    b4 = fileHeaderStr(1:startIdx-1);
    endIdx = regexp(fileHeaderStr, 'SI.hStackManager.numVolumes');
    after = fileHeaderStr(endIdx:end);
    
    new = [b4 sprintf('SI.hStackManager.numSlices = %d\n', size(AoutImdata,5)) after];
    
    fileHeaderStr = new;
    
    [startIdx, ~] = regexp(fileHeaderStr, 'SI.hStackManager.numVolumes');
    b4 = fileHeaderStr(1:startIdx-1);
    endIdx = regexp(fileHeaderStr, 'SI.hStackManager.reserverInfo');
    after = fileHeaderStr(endIdx:end);
    
    new = [b4 sprintf('SI.hStackManager.numVolumes = %d\n', size(AoutImdata,6)) after];
    
    fileHeaderStr = [customHdr new];
    
    %%
    
    hdrSplit = strsplit(fileHeaderStr, '\n\n');
    
    hdrBuf = [uint8(hdrSplit{1}) 0];
    hdrBufLen = length(hdrBuf);
    
    hdrBuf = [hdrBuf uint8([sprintf('\n') hdrSplit{2}]) 0];
    
    pfix = [1 3 3 7 typecast(uint32(4),'uint8') typecast(uint32(hdrBufLen),'uint8') typecast(uint32(length(hdrBuf)-hdrBufLen),'uint8')];
    
    tifHeaderData = [pfix hdrBuf]';
    tifHeaderStringOffset = length(pfix);
    tifRoiDataStringOffset = length(pfix) + hdrBufLen;
    
    
    dataSigned    = true;
    bitsPerSample = 16;
    
    numChannelSave = numel(header.SI.hChannels.channelSave);
    pixelsPerLine = header.SI.hRoiManager.pixelsPerLine;
    linesPerFrame = header.SI.hRoiManager.linesPerFrame;
    
    blankFrameDescription = repmat(' ',1,2000);
    
    imageSize = pixelsPerLine * linesPerFrame * (bitsPerSample/8);
    
    flybackPeriods = ceil(header.SI.hScan2D.flybackTimePerFrame * header.SI.hScan2D.scannerFrequency);
    flybackLinesPerFrame = round((flybackPeriods * 2^header.SI.hScan2D.bidirectional)/2)*2;
    
    rois = hMroiRoiGroup.rois;
    
    zs = header.SI.hStackManager.zs;
    
    scanFields = arrayfun(@(z)hMroiRoiGroup.scanFieldsAtZ(z),...
                    zs,'UniformOutput',false);
                
    cumPixelResolutionAtZ = zeros(0,2);
    mRoiLogging = false;
    for zidx = 1:length(scanFields)
        sfs = scanFields{zidx};
        pxRes = zeros(0,2);
        for sfidx = 1:length(sfs)
            sf = sfs{sfidx};
            pxRes(end+1,:) = sf.pixelResolution(:)';
        end
        mRoiLogging = mRoiLogging || size(pxRes,1) > 1;
        cumPixelResolutionAtZ(end+1,:) = [max(pxRes(:,1)),sum(pxRes(:,2))+((size(pxRes,1)-1)*flybackLinesPerFrame)];
    end
    
    mRoiLogging = mRoiLogging || any(cumPixelResolutionAtZ(1,1) ~= cumPixelResolutionAtZ(:,1));
    mRoiLogging = mRoiLogging || any(cumPixelResolutionAtZ(1,2) ~= cumPixelResolutionAtZ(:,2));
    linesPerFrame = max(cumPixelResolutionAtZ(:,2));
    pixelsPerLine = max(cumPixelResolutionAtZ(:,1));
    
    sf = scanFields{1}{1};
    resDenoms = 2^30 ./ (1e4 * sf.pixelResolutionXY ./ (sf.sizeXY * header.SI.objectiveResolution));
    
    xResolutionNumerator = 2^30;
    xResolutionDenominator = resDenoms(1);
    yResolutionNumerator = 2^30;
    yResolutionDenominator = resDenoms(2);
                
    imageSize = pixelsPerLine * linesPerFrame * (bitsPerSample/8);
    
    hNewTif = scanimage.components.scan2d.TiffStream;
    
     assert(hNewTif.open([pwd '\' newFileName],tifHeaderData,tifHeaderStringOffset,tifRoiDataStringOffset), 'Failed to create log file.');
                    hNewTif.configureImage(pixelsPerLine, linesPerFrame, (bitsPerSample/8), numChannelSave, dataSigned, blankFrameDescription,...
                        xResolutionNumerator, xResolutionDenominator, yResolutionNumerator, yResolutionDenominator);
                    
    frameStream = {};
    
    %�Aout� is specified, a matrix of the size M x N x C x F x S x V is
    % created, where: - C spans the channel indices, - F spans the frame
    % indicies, - S spans the slice indices, and - V the volume indices.
    
    numChans = size(AoutImdata,3);
    numFrames = size(AoutImdata,4);
    numSlices = size(AoutImdata,5);
    numVolumes = size(AoutImdata,6);
    
    for vols = 1:numVolumes
        for slice = 1:numSlices
            for frames = 1:numFrames
                for chan = 1:numChans
                    frameStream{end+1} = AoutImdata(:,:,chan, frames, slice, vols)';
                end
            end
        end
    end
    
    
    for idx = 1:numel(frameStream)
        
        hNewTif.replaceImageDescription(frameDescs{idx});
        
        if mRoiLogging
            line = 1;
            for roiIdx = 1:length(rois)
                imdata = frameStream{idx};
                dims = size(imdata);
                tempbuf(1:dims(1),line:line+dims(2)-1) = imdata;
                line = line + dims(2);
            end
            hNewTif.appendFrame(int16(tempbuf), imageSize);
        else
            hNewTif.appendFrame(int16(frameStream{idx}), imageSize);
        end
    end
    
    hNewTif.close();
    hNewTif.cleanUp();                
    
    function [fileHeaderStr,frameDescs] = getHeaderDataFromScanImageTiffObj(tifObj)
        frameDescs = tifObj.descriptions();
        isemptyMask = cellfun(@(d)isempty(d),frameDescs);
        frameDescs(isemptyMask) = [];
        
        fileHeaderStr = tifObj.metadata();
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

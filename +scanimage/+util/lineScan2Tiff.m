function hTiff = lineScan2Tiff(file)
    hTiff = [];
    [filename, pathname] = uigetfile('*.dat', 'Select Line Scan Data File');
    basename = regexp(fullfile(pathname, filename), '\.', 'split');
    basename = basename{1};
    
    [header, pmtData, scannerPosData, roiGroup] = scanimage.util.readLineScanDataFiles(fullfile(pathname, filename));
    
    fovCornerPts = header.SI.hScan2D.fovCornerPoints;
    fovXMinMax = [fovCornerPts(1,1) fovCornerPts(2,1)];
    fovYMinMax = [fovCornerPts(1,2) fovCornerPts(4,2)];
    
    prompt = {sprintf('What was the Pixel resolution of the reference image for this line scan?\n\nPixels Per Line:'),'Lines Per Frame:'};
    dlgtitle = 'Image Resolution';
    dims = [1 35];
    definput = {'512', '512'};
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    
    if isempty(answer)
        return
    else
        assert(all(cellfun(@(x) all(ismember(x, '0123456789+-.eEdD')), answer)), 'Invalid inputs: All inputs must be whole numbers');
        resolution = str2num(cell2mat(answer))';
    end
    
    ss = scanimage.mroi.scannerset.GalvoGalvo.default;
    Fsc = header.SI.hScan2D.sampleRateCtl;
    
    ss.scanners{1}.sampleRateHz = Fsc;
    ss.scanners{2}.sampleRateHz = Fsc;
    ss.beams.sampleRateHz = Fsc;
    ss.fastz.sampleRateHz = Fsc;
    
    [scanPath,~,~] = roiGroup.scanStackFOV(ss,0,0,'',0,'',[],false);
    
    N = numel(scanPath.G(:,1));
    Nt = header.samplesPerFrame;
    scanPath.G = [interp1(linspace(0,1,N),scanPath.G(:,1),linspace(0,1,Nt)')...
        interp1(linspace(0,1,N),scanPath.G(:,2),linspace(0,1,Nt)')];
    scanPath.Z = interp1(linspace(0,1,N),scanPath.Z,linspace(0,1,Nt)');
    scanPathN = Nt;
    
    xPosNominal = scannerPosData.G(:,1);
    xPosResamp = scanPath.G(:,1);
    yPosNominal = scannerPosData.G(:,2);
    yPosResamp = scanPath.G(:,2);
    
    angle2PixX = arrayfun(@(x) interp1(fovXMinMax,[1 resolution(1)],x, 'linear'), xPosResamp);
    angle2PixY = arrayfun(@(x) interp1(fovYMinMax,[1 resolution(2)],x, 'linear'), yPosResamp);
    
    inds = sub2ind(resolution, (round(angle2PixY)), (round(angle2PixX)));
    
    [data, chans, frames] = size(pmtData);
    
    tifImg = zeros(resolution(1),resolution(2),chans,1,frames,'int16');
    
    for ch = 1:chans
        for fs = 1:frames
            newImg = zeros(resolution, 'int16');
            newImg(inds) = pmtData(:,ch,fs);
            tifImg(:,:,ch,1,fs) = newImg;
        end
    end
    
    fiji_descr = ['ImageJ=1.52p' newline ...
            'images=' num2str(chans*frames) newline... 
            'channels=' num2str(chans) newline...
            'slices=0' newline...
            'frames=' num2str(frames) newline... 
            'hyperstack=true' newline...
            'mode=grayscale' newline...  
            'loop=false' newline...  
            'min=-32768' newline...      
            'max=32767'];
    
    
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.ImageLength = resolution(1);
    tagstruct.ImageWidth = resolution(2);
    tagstruct.RowsPerStrip = resolution(2);
    tagstruct.BitsPerSample = 16;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.Compression = Tiff.Compression.None;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';
    tagstruct.SampleFormat = Tiff.SampleFormat.Int;
    tagstruct.Orientation = Tiff.Orientation.TopLeft;
    tagstruct.ImageDescription = fiji_descr;
    
    meta = [basename '.meta.txt'];
    
    softwareTag = [];
    artistTag = [];
    
    fid = fopen(meta,'r');
    
    textLine = fgetl(fid);
    lineCounter = 1;
    while ischar(textLine)
        if isempty(softwareTag)
            softwareTag = textLine;
        else
            softwareTag = sprintf([softwareTag '\n' textLine]);
        end
        % Read the next line.
        textLine = fgetl(fid);
        if length(textLine) == 0
            break;
        end
        lineCounter = lineCounter + 1;
    end
    
    textLine = fgetl(fid);
    
    while ischar(textLine)
        if isempty(artistTag)
            artistTag = textLine;
        else
            artistTag = sprintf([artistTag '\n' textLine]);
        end
        % Read the next line.
        textLine = fgetl(fid);
        if length(textLine) == 0
            break;
        end
        lineCounter = lineCounter + 1;
    end
    
    tagstruct.Software = softwareTag;
    tagstruct.Artist = artistTag;
    
    hTiff = Tiff([basename '.tif'], 'w8');
    
    for frs = 1:frames
        for chs = 1:chans
            setTag(hTiff,tagstruct);
            hTiff.write(tifImg(:,:,chs,1,frs));
            hTiff.writeDirectory();
        end
    end
    
    hTiff.close();
    
%     figure();
%     imshow(blankImg, []);
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

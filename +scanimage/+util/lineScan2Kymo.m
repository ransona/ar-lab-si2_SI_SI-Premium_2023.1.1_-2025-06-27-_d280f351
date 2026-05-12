function lineScan2Kymo(file)
%     hTiff = [];
    if nargin<1 || isempty(file)
        [filename, pathname] = uigetfile('*.dat', 'Select Line Scan Data File');
    else
        [pathname, filename, ext] = fileparts(file);
        filename = [filename, ext];
    end
    
    if isempty(filename)||~ischar(filename)
        return;
    end
    
    basename = regexp(filename, '\.', 'split');
    basename = basename{1};

    [header, pmtData, ~, ~] = scanimage.util.readLineScanDataFiles(fullfile(pathname, filename));
    
    [r,c,p] = size(pmtData);
    
    cycleData = {};
    for ch = 1:c
        data = reshape(pmtData(:,ch,:), r,p)';
        cycleData{ch} = data;
    end
    
    pmtData = [];
    
    res = [size(cycleData{1},1) size(cycleData{1},2)];
    
    tifImg = zeros(res(1),res(2),c,1,1,'int16');
    
    for ch = 1:c
        tifImg(:,:,ch,1,1) = cycleData{ch};
    end
    
    cycleData = [];
    
    fiji_descr = ['ImageJ=1.52p' newline ...
            'images=' num2str(c*1) newline... 
            'channels=' num2str(c) newline...
            'slices=0' newline...
            'frames=1' newline... 
            'hyperstack=true' newline...
            'mode=grayscale' newline...  
            'loop=false' newline...  
            'min=-32768' newline...      
            'max=32767'];
        
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.ImageLength = res(1);
    tagstruct.ImageWidth = res(2);
    tagstruct.RowsPerStrip = res(2);
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
    
    for frs = 1
        for chs = 1:c
            setTag(hTiff,tagstruct);
            hTiff.write(tifImg(:,:,chs,1,frs));
            hTiff.writeDirectory();
        end
    end
    
    hTiff.close();
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

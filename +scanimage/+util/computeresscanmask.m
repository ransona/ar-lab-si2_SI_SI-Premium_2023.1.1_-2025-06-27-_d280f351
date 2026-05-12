function mask = computeresscanmask(scanFreq, sampleRate, fillFractionSpatial, pixelsPerLine)
%COMPUTERESSCANMASK Computes the line mask for resonant scanning
%   The mask indicates the number of samples acquired per pixel in a line
%   based on the given parameters    

    assert(fillFractionSpatial>0 && fillFractionSpatial<1,'fillFractionSpatial needs to be smaller than 1');

    pixelBoundaries = linspace(-fillFractionSpatial,fillFractionSpatial,pixelsPerLine+1)';
    pixelBoundariesTime = asin(pixelBoundaries) / (2*pi*scanFreq);
    pixelBoundariesSamples = pixelBoundariesTime * sampleRate;
    pixelBoundariesSamples = round(pixelBoundariesSamples); % quantize
    mask = diff(pixelBoundariesSamples);

%     assert(all(mask>0),'Mask contains zero values, which will result in incorrect FPGA behavior');
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

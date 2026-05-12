function lightness = luminance2perceived(luminance)
    %LUMINANCE2PERCEIVED Converts Luminance scalar to perceived lightness
    % (L*) in documentation. 0.5 indicates middle gray.
    % Graciously stolen from https://stackoverflow.com/a/56678483

    validateattributes(luminance, {'numeric'}, {'finite', 'nonnan', '<=', 1, '>=', 0}, ...
        'most.gui.luminance2perceived', 'luminance');
    luminanceVector = luminance(:);
    lightnessVector = luminanceVector;
    cieLuminanceThreshold = 216 / 24389;
    cieLightnessScale = 24389 / 27;

    iAboveThreshold = luminanceVector <= cieLuminanceThreshold;
    lightnessVector(iAboveThreshold) = luminanceVector(iAboveThreshold) .* cieLightnessScale;
    lightnessVector(~iAboveThreshold) = (luminanceVector(~iAboveThreshold) .^ (1/3)) .* 116 - 6;
    lightnessVector = lightnessVector ./ 100;
    lightness = reshape(lightnessVector, size(luminance));
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

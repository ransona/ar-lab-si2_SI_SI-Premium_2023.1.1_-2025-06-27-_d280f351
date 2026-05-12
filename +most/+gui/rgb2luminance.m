function luminance = rgb2luminance(rgb)
    %RGB2LUMINANCE Converts rgb triad or color name to its equivalent
    %luminannce value.
    % Algorithm stolen wholesale from https://stackoverflow.com/a/56678483

    if ischar(rgb) || isstring(rgb)
        rgb = most.gui.color2rgb(rgb);
    else
        validateattributes(rgb, {'numeric'}, ...
            {'row', 'vector', 'numel', 3, '<=', 1, '>=', 0, 'finite', 'nonnan'}, ...
            'most.gui.rgb2luminance', 'rgb');
    end

    % linearize RGB
    linearThreshold = 0.04045;
    linearRgb = rgb;
    iBelowThreshold = rgb <= linearThreshold;
    linearRgb(iBelowThreshold) = rgb(iBelowThreshold) ./ 12.92;
    linearRgb(~iBelowThreshold) = ((rgb(~iBelowThreshold) + 0.055) ./ 1.055) .^ 2.4;

    luminance = sum(linearRgb .* [0.2126, 0.7152, 0.0722]);
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

function [str,prefix,exponent] = engineersStyle(x,unit,format,unitPrefix)
    % based on http://www.mathworks.com/matlabcentral/answers/892-engineering-notation-printed-into-files
    % credits to Jan Simon
    
    if nargin < 2 || isempty(unit)
        unit = '';
    end
    
    if nargin < 3 || isempty(format)
        format = '%.1f';
    end
    
    if nargin < 4 || isempty(unitPrefix)
        unitPrefix = '';
    end
    
    if isempty(x)
        str = '';
        return
    end
    
    if x==0
        str = sprintf('%d%s',x,unit);
        prefix = '';
        exponent = 0;
        return
    end
    
    exponent = 3 * floor(log10(x) / 3);
    y = x / (10 ^ exponent);
    expValue = [24,21,18,15,12,9,6,3,0,-3,-6,-9,-12,-15,-18,-21,-24];
    expName = {'Y','Z','E','P','T','G','M','k','','m','u','n','p','f','a','z','y'};
    expIndex = (exponent == expValue);
    if any(expIndex)  % Found in the list:
        str = sprintf([format '%s%s%s'],y,unitPrefix,expName{expIndex},unit);
        prefix = expName{expIndex};
    else
        str = sprintf('%fe%+04d%s%s',y,exponent,unitPrefix,unit);
        prefix = '';
        exponent = 0;
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

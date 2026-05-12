function valid = str2validName(propname, prefix)
% CONVERT2VALIDNAME
% Converts the property name into a valid matlab property name.
% propname: the offending propery name
% prefix: optional prefix to use instead of the ambiguous "dyn"
valid = propname;
if isvarname(valid) && ~iskeyword(valid)
    return;
end

if nargin < 2 || isempty(prefix)
    prefix = 'dyn_';
else
    if ~isvarname(prefix)
        warning('Prefix contains invalid variable characters.  Reverting to "dyn"');
        prefix = 'dyn_';
    end
end

% general regex /[a-zA-Z]\w*/

%find all alphanumeric and '_' characters
valididx = isstrprop(valid, 'alphanum');
valididx(strfind(valid, '_')) = true;

% replace all invalid characters with '_' for now
valid(~valididx) = '_';

if isempty(valid) || ~isstrprop(valid(1), 'alpha') || iskeyword(valid)
    valid = [prefix valid];
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

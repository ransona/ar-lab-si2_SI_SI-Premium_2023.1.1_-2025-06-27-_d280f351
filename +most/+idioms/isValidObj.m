function tf = isValidObj(obj)
    %ISVALIDOBJ Determines is the argument is an object handle and if the handle actually
    % points to a valid object (isobject does not actually tell you this)

    % isvalid errors if the object is not a subclass of handle so we must
    % check for that first as well.

    % furthermore, non-graphics/Java objects and non-MATLAB class objects should also return
    % false (char arrays, other primitive types, strings, etc.)
    
    % note: a handle is always an object, but an object might not be a
    % handle
    % - because of this, there isn't a true need to check if its a handle
    % - since a handle will be an object, it will pass the isObject check
    % - NOTE: the isvalid check must be at the end of the short circuit
    %   because it will ERROR when passed a numeric value, not return false
    %   thus the other checks will prevent a numeric value from ever being
    %   supplied to the isvalid check
    tf = ~isempty(obj)     ...
        && isobject(obj)   ...
        && ~isnumeric(obj) ...
        && ~isenum(obj)    ...
        && all(isvalid(obj));
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

function data = loadjsonobj(fname,varargin)
data = most.json.loadjson(fname,varargin{:});

data = fieldToObj(data);
end

function data = fieldToObj(data,currentfieldnames)
    if nargin < 2 || isempty(currentfieldnames)
        currentfieldnames = {};
        s = data;
    else
        s = getfield(data,currentfieldnames{:});
    end
    
    if isa(s,'struct')
        if isfield(s,'classname')
            obj = eval([s.classname '.loadobj(s)']);
            if isempty(currentfieldnames)
                data = obj;
            else
                data = setfield(data,currentfieldnames{:},obj);
            end                
        else
            fnames = fieldnames(s);
            for idx = 1:length(fnames)
                data = fieldToObj(data,[currentfieldnames fnames{idx}]);
            end
        end
    elseif isa(s,'cell')
        for idx = 1:length(s)
            s{idx} = fieldToObj(s{idx});
            data = setfield(data,currentfieldnames{:},s);
        end
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

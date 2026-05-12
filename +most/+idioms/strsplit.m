%% sadly, pre-2013 matlab does not have strsplit and strjoin
% code copied off of the matlab file exchange and modified for brevity
function terms = strsplit(s, delimiter)
if nargin < 2
    by_space = true;
else
    d = delimiter;
    d = strtrim(d);
    by_space = isempty(d);
end
s = strtrim(s);

if by_space
    w = isspace(s);
    if any(w)
        % decide the positions of terms
        dw = diff(w);
        sp = [1, find(dw == -1) + 1];     % start positions of terms
        ep = [find(dw == 1), length(s)];  % end positions of terms
        
        % extract the terms
        nt = numel(sp);
        terms = cell(1, nt);
        for i = 1 : nt
            terms{i} = s(sp(i):ep(i));
        end
    else
        terms = {s};
    end
    
else
    p = strfind(s, d);
    if ~isempty(p)
        % extract the terms
        nt = numel(p) + 1;
        terms = cell(1, nt);
        sp = 1;
        dl = length(delimiter);
        for i = 1 : nt-1
            terms{i} = strtrim(s(sp:p(i)-1));
            sp = p(i) + dl;
        end
        terms{nt} = strtrim(s(sp:end));
    else
        terms = {s};
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

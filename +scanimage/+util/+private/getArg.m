function arg = getArg(vararguments, flag, flags, flagIndices)
    [tf,loc] = ismember(flag,flags); %Use this approach, instead of intersect, to allow detection of flag duplication
    if length(find(tf)) > 1
        error(['Flag ''' flag ''' appears more than once, which is not allowed']);
    else %Extract location of specified flag amongst flags
        loc(~loc) = [];
    end
    flagIndex = flagIndices(loc);
    if length(vararguments) <= flagIndex
        arg = [];
        return;
    else
        arg = vararguments{flagIndex+1};
        if ischar(arg) && ismember(lower(arg),flags) %Handle case where argument was omitted, and next argument is a flag
            arg = [];
        end
    end
end

% 
% function arg = getArg(vararguments, flag)
%     % make a temp cell array to search for strings
%     argsch = vararguments;
%     ics = ~cellfun(@ischar,argsch);
%     argsch(ics) = {''};
%     
%     [tf,loc] = ismember(flag,argsch); %Use this approach, instead of intersect, to allow detection of flag duplication

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

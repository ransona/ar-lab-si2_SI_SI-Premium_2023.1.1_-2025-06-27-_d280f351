function parsed = parseFcn(filename)
%this function parses the headers of a given function file and returns a struct
%with fields:
% argnames = {argument names}
% outnames = {output names}
% persistnames = {persistent var names}
% fcn = char vector containing the body of the function
% name = char vector containing the name of the function
parsed = struct();
if exist(filename, 'file') ~= 2
    warning([filename ' does not exist as a readable file.']);
    return;
end
fid = fopen(filename);
scriptText = fread(fid, '*char')';
fclose(fid);
if isempty(strfind(scriptText, sprintf('\n')))
    warning([filename ' might not be a matlab function file.']);
    return;
end

nlIndices = strfind(scriptText, sprintf('\n'));

parsed.argnames = {};
%find function args and name
closeBraceIndices = strfind(scriptText(1:nlIndices(1)), ')');
if ~isempty(closeBraceIndices)
    argEndIdx = closeBraceIndices(1)-1;
    openBraceIndices = strfind(scriptText(1:closeBraceIndices(1)), '(');
    argStartIdx = openBraceIndices(1)+1;
    
    parsed.argnames = strip(split(...
        scriptText(argStartIdx:argEndIdx), ','));
end

parsed.outnames = {};
%find output args if exists
eqIdx = strfind(scriptText(1:nlIndices(1)), '=');
if ~isempty(eqIdx)
    openBracketIdx = strfind(scriptText(1:eqIdx), '[');
    if isempty(openBracketIdx)
        parsed.outnames = regexp(scriptText(1:eqIdx), 'function\s+(\S+)\s+=', 'tokens', 'once');
    else
        endBracketIdx = strfind(scriptText(1:eqIdx), ']');
        parsed.outnames = strip(split(...
            scriptText(openBracketIdx+1:endBracketIdx-1), ','));
    end
end

%find name
[~, parsed.name, ~] = fileparts(filename);

%find persistent variables
parsed.persistnames = {};
if ~isempty(strfind(scriptText, 'persistent'))
    persist_pat = '^\s*persistent\s+([^;\n]+)';
    persist_lines = regexp(scriptText, persist_pat, 'tokens', 'lineanchors');
    if ~isempty(persist_lines)
        persist_vars = strip(split([persist_lines{:}], ','));
        parsed.persistnames = reshape(persist_vars, numel(persist_vars), 1);
    end
end

endIndices = strfind(scriptText, 'end');
endIndex = endIndices(end);
fcn = strip(scriptText(nlIndices(1)+1:endIndex-1));
parsed.fcn = regexprep(fcn, '^\s*persistent\s+[\w,\s]+;\s*$', '', 'lineanchors');
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

function str = csvToCell(filename, delimiter, delimiterIsRegex)
if nargin < 2 || isempty(delimiter)
    delimiter = ',';
end

if nargin < 3 || isempty(delimiterIsRegex)
    delimiterIsRegex = false;
end

validateattributes(delimiter,{'char'},{'row'});
validateattributes(delimiterIsRegex,{'numeric','logical'},{'scalar','binary'});

if ~delimiterIsRegex
    delimiter = regexptranslate('escape',delimiter);
end

str = readFileContent(filename);

% split into lines
str = regexp(str,'\s*[\r\n]+\s*','split')';
if isempty(str{end})
    str(end) = [];
end

% split at delimiter into cells
delimiter = ['\s*' delimiter '\s*']; % ignore white space characters around delimiter
str = regexp(str,delimiter,'split');
str = vertcat(str{:});
end

function str = readFileContent(filename)
    assert(exist(filename,'file')~=0,'File %s not found',filename);
    hFile = fopen(filename,'r');
    try
        % read entire content of file
        str = fread(hFile,'*char')';
        fclose(hFile);
    catch ME
        % clean up in case of error
        fclose(hFile);
        rethrow(ME);
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

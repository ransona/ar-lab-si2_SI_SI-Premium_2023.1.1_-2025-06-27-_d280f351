function [name, requiredPath] = path2name(fullPath)
    %PATH2NAME Given a path to a valid file, return a valid module-specified name.
    % [name, requiredPath] = PATH2NAME(fullPath) returns both the module-qualified name along with
    % the environment path that would need to be set in order to reference the name.

    validateattributes(fullPath, {'char', 'string'}, {'scalartext', 'nonempty'}...
        , 'path2functionName', 'fullPath', 1);

    [filePath, fileName, fileExtension] = fileparts(fullPath);
    errorMessage = sprintf('`%s` is not a valid function name', fullPath);
    errorId = 'ScanImage:path2functionName:InvalidPath';
    assert(~isempty(fileName) && strcmp('.m', fileExtension) ...
        , errorId, '%s. Must be a valid .m file', errorMessage);
    if isempty(filePath)
        name = fileName;
        requiredPath = filePath;
        return;
    end

    % Form Mx2 matrix where M := # tokens defined by (start, end) indices
    dirNames = regexp(filePath, '[^\\/]+', 'match');

    if isempty(dirNames)
        name = fileName;
        requiredPath = '.';
        return;
    end

    isModDir = startsWith(dirNames, '+');
    isClassDir = startsWith(dirNames, '@');

    if ~any(isModDir | isClassDir)
        name = fileName;
        requiredPath = filePath;
        return;
    end
    if any(isClassDir)
        assert(1 == sum(isClassDir) ...
            , errorId ...
            , '%s. @Class names can only occur at most once on a path.', errorMessage);
    end
    if any(isModDir)
        assert(isscalar(find(isModDir)) || 1 >= max(diff(find(isModDir))) ...
            , errorId ...
            , '%s. Cannot reference private (non-module) directories.', errorMessage);
    end
    if any(isModDir) && any(isClassDir)
        assert(find(isModDir, 1, 'last') < find(isClassDir, 1, 'last') ...
            , errorId ...
            , '%s. Malformed class directory. @Class directories cannot contain +modules.');
    end
    assert(length(dirNames) == find(isClassDir | isModDir, 1, 'last') ...
        , errorId ...
        , '%s. Cannot reference private (non-module or non-class) directories.', errorMessage);
    requiredPath = strjoin(dirNames(~(isModDir | isClassDir)), filesep());

    modNames = strjoin(extractAfter(dirNames(isModDir), '+'));
    className = extractAfter(dirNames(isClassDir), '@');
    name = strjoin([modNames, className, fileName], '.');
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

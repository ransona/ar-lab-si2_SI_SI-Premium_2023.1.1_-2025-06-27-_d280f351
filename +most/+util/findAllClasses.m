function classNames = findAllClasses(baseDir,filterClassName)
    % this does not return meta classes, since they seem to be deleted at
    % random. to prevent this we return classNames instead
    
    if nargin < 1 || isempty(baseDir)
        baseDir = pwd();
    end
    
    if nargin < 2 || isempty(filterClassName)
        filterClassName = [];
    end
    
    if strcmpi(baseDir(end),filesep)
        baseDir(end) = [];
    end
    
    %% find base identifiers
    filePaths = string(most.util.getMatlabFilesFast(baseDir));
    % first, package names (returns cell)
    iFirstIdentifiers = regexp(filePaths, '(?:\\|^)(\+)', 'tokenExtents', 'once');
    isMissingIdentifier = cellfun('isempty', iFirstIdentifiers);
    if any(isMissingIdentifier)
        % second, @ classes
        iFirstIdentifiers(isMissingIdentifier) = regexp(filePaths(isMissingIdentifier) ...
            , '(?:\\|^)(@)', 'tokenExtents', 'once');
        isMissingIdentifier = cellfun('isempty', iFirstIdentifiers);
        if any(isMissingIdentifier)
            % finally, class definitions.
            iFirstIdentifiers(isMissingIdentifier) = regexp(filePaths(isMissingIdentifier) ...
                , '(?:\\|^)([^\\]+\.[mp])$', 'tokenExtents', 'once');
            isMissingIdentifier = cellfun('isempty', iFirstIdentifiers);
            filePaths = filePaths(~isMissingIdentifier);
            iFirstIdentifiers = iFirstIdentifiers(~isMissingIdentifier);
        end
    end
    iFirstIdentifiers = cell2mat(iFirstIdentifiers);
    iFirstIdentifiers = iFirstIdentifiers(:,1); % we only care about the start of the token.
    
    %% Filter out identifiers not on the path
    
    [expectedPathLocations, ~, iLocationMap] = unique(extractBefore(filePaths, iFirstIdentifiers), 'stable');
    % check the paths to see if these identifiers are accessible
    % add trailing separator since that's what extractBefore will include
    % (if applicable)
    envPaths = string([strsplit(path(), pathsep()), {pwd()}]) + filesep();
    [~, iValidPaths, ~] = intersect(expectedPathLocations, envPaths, 'stable');
    isOnPath = ismember(iLocationMap, iValidPaths);
    filePaths = filePaths(isOnPath);
    expectedPathLocations = expectedPathLocations(iLocationMap(isOnPath));
    
    %% Convert valid class paths to valid class references
    % classPaths is now all path-friendly relative package paths (or
    % classes)
    classPaths = extractAfter(filePaths, expectedPathLocations);
    
    % remove file extensions
    if verLessThan('MATLAB', '9.11')
        classLocations = repmat("", length(classPaths), 1);
        className = classLocations;
        for iPath = 1:length(classPaths)
            [classLocations(iPath), className(iPath)] = fileparts(classPaths(iPath));
        end
    else
        [classLocations, className, ~] = fileparts(classPaths);
    end
    classPaths = fullfile(classLocations, className);
    
    % extract @ classes which invalidate everything after it. @ classes
    % which do not actually match their class names are malformed.
    classPaths = regexprep(classPaths, '@([^\\]+).*', '$1', 'once');
    
    % replace direct class references
    classPaths = regexprep(classPaths, '\\([^\\]+)$', '.$1', 'once');
    
    % convert packages
    classPaths = regexprep(classPaths, '\\\+', '.');
    classPaths = regexprep(classPaths, '^\+', '', 'once');
    
    % remaining file separators are now invalid and are removed.
    hasLocalFolders = contains(classPaths, '\');
    classNames = classPaths(~hasLocalFolders);
    isCorrectClass = false(size(classNames));
    
    for iClass = 1:length(classNames)
        name = classNames{iClass};

        try
            classMetaClass = meta.class.fromName(name);
        catch ME
            if string(ME.identifier) == "MATLAB:err_parse_cannot_access_previously_accessible_file"
                % sometimes, the class is not cached properly yet and
                % metaclass will simply fail with a cryptic error
                % message along the lines of:
                % Previously acessible file "<class path>" now inaccessible.
                % This rehash usually fixes those errors.
                rehash();
                try
                    % A metaclass call will also fail if the class
                    % itself is not instantiable; either because there
                    % are syntax errors or the default arguments are
                    % invalid.
                    classMetaClass = meta.class.fromName(name);
                catch
                    isCorrectClass(iClass) = false;
                    continue;
                end
            else
                isCorrectClass(iClass) = false;
                continue;
            end
        end
        isCorrectClass(iClass) = most.idioms.isa(classMetaClass, filterClassName);
    end
    classNames = classNames(isCorrectClass);
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

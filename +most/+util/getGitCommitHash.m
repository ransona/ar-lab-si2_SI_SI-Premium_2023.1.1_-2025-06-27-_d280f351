function commitHash = getGitCommitHash(gitRepoPath)
    validateattributes(gitRepoPath,{'char'},{'row'});
    
    assert(logical(exist(gitRepoPath,'dir')),'Invalid gitRepoPath: %s',gitRepoPath);
    gitFolder = fullfile(gitRepoPath,'.git');
    assert(logical(exist(gitFolder,'dir')),'.git folder was not found');

    [branch,commitHash] = getBranch(gitFolder);
    
    if ~isempty(commitHash)
        return
    end    
    
    refPath = fullfile(gitFolder,branch);
    
    if exist(refPath,'file')
        commitHash = readRef(gitFolder,branch);
    else
        commitHash = readPackedRef(gitFolder,branch);
    end
end

function [branch,commitHash] = getBranch(gitFolder)
    headFilePath = fullfile(gitFolder,'HEAD');
    text = most.idioms.readTextFile(headFilePath);
    text = strtrim(text);
    
    branch = '';
    commitHash = regexpi(text,'[0-9A-F]{20,}','match','once');
    
    if isempty(commitHash)
        % did not find commit, try to find branch name instead
        tokens = regexpi(text,'^ref:\s*(.*)$','tokens','once','lineanchors');
        assert(isscalar(tokens),'Could not retrieve branch name');
        branch = tokens{1};
    end
end

function commitHash = readRef(gitFolder,branch)
    refPath = fullfile(gitFolder,branch);
    text = most.idioms.readTextFile(refPath);
    commitHash = strtrim(text);
end

function commitHash = readPackedRef(gitFolder,branchName)
    packedRefPath = fullfile(gitFolder,'packed-refs');
    text = most.idioms.readTextFile(packedRefPath);
    
    branchNameEscaped = regexptranslate('escape',branchName);
    pattern = ['\s*([0-9A-F]+)\s+' branchNameEscaped '\s*$'];
    tokens = regexpi(text,pattern,'tokens','once','lineanchors');
    
    commitHash = tokens{1};
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

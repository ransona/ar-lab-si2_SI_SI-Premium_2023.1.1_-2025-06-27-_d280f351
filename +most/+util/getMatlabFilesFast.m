function files = getMatlabFilesFast(baseDir,includePFiles,filter)
    if nargin<1 || isempty(baseDir)
        baseDir = pwd();
    end
    
    if nargin<2 || isempty(includePFiles)
        includePFiles = true;
    end
    
    if nargin<3 || isempty(filter)
        filter = '';
    end

    if verLessThan('matlab','9.1') % Matlab 2016b
        files = getFilesOldMatlab(baseDir,'*.m');
        
        if includePFiles
        	files = vertcat(files,getFilesOldMatlab(baseDir,'*.p'));
        end
    else
        % dir with ** for recursive folder search was
        % introduced in Matlab 2016b
        files = dir([baseDir filesep '**' filesep '*.m']);
        
        if includePFiles
            files = vertcat(files, dir([baseDir filesep '**' filesep '*.p']));
        end

        folders   = {files.folder};
        fileNames = {files.name};

        files = fullfile(folders,fileNames);
        files = files(:);
    end
    
    if ~isempty(filter)
        mask = regexp(files,filter,'once');
        mask = cellfun(@(m)~isempty(m),mask);
        files(mask) = [];
    end
end


%%% Local function
function files = getFilesOldMatlab(baseDir,filter)
    [stat,files] = system(['dir "' baseDir '\' filter '" /s /b']);
    files = strtrim(files);

    if strcmpi(files,'File Not Found')
        files = {};
    else
        files = strsplit(files,'\n');
    end
    
    files = files(:);
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

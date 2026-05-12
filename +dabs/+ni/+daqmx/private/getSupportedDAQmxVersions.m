function versions = getSupportedDAQmxVersions
switch computer('arch')
    case 'win32'
        archFolder = 'win32';
    case 'win64'
        archFolder = 'x64';
    otherwise
        error('NI DAQmx: Unknown computer architecture :%s',computer(arch));
end
    folders = dir('NIDAQmx_*');
    folders = {folders.name};
    
    versions = {};
    for i = 1:length(folders)
        folder = folders{i};
        supported = 0 < exist(fullfile(pwd,folder,archFolder,'NIDAQmx_proto.m'),'file') ...
                 || 0 < exist(fullfile(pwd,folder,archFolder,'NIDAQmx_proto.p'),'file');
        if strcmp(archFolder,'x64')
            supported = supported && 0 < exist(fullfile(pwd,folder,archFolder,'nicaiu_thunk_pcwin64.dll'),'file');
        end
        
        if supported
           versions{end+1} = strrep(strrep(folder,'NIDAQmx_',''),'_','.'); %#ok<AGROW>
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

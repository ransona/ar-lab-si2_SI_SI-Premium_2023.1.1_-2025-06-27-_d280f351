function filename = generateNIMaxReport(filename)
    if nargin < 1 || isempty(filename)
       [filename,pathname] = uiputfile('.zip','Choose path to save report','NIMaxReport.zip');
       if filename==0;return;end
       filename = fullfile(pathname,filename);
    end

    [fpath,fname,fext] = fileparts(filename);
    if isempty(fpath)
        fpath = pwd;
    end
    filename = fullfile(fpath,[fname '.zip']); % extension has to be .zip, otherwise NISysCfgGenerateMAXReport will throw error

    % get singleton configuration object
    hConfig = dabs.ni.configuration.Configuration();
    assert(most.idioms.isValidObj(hConfig),'NI drivers are not installed');
    
    sessionhandle = hConfig.sessionhandle;
    
    % create MAX report
    dabs.ni.configuration.private.nisyscfgCall('NISysCfgGenerateMAXReport',sessionhandle,filename,2,true);
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

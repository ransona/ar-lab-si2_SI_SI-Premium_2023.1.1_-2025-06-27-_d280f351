function setSIFilePermissions()
    siPath = scanimage.util.siRootDir();

    %% set user permissions to full access
     fprintf('Setting user permissions for folder %s ...\n',siPath);
%     [~,currentUser] = system('whoami');
%     currentUser = regexprep(currentUser,'\n','');
%     cmd = ['icacls "' siPath '" /grant "' currentUser '":(OI)(CI)F /T'];

    cmd = ['icacls "' siPath '" /grant "Users":(OI)(CI)F /T'];
    [status,cmdout] = system(cmd);
    if status == 0
        statusLine = regexpi(cmdout,'^.*(Successfully|Failed).*$','lineanchors','dotexceptnewline','match','once');
        if isempty(statusLine)
            disp(cmdOut)
        else
            disp(statusLine)
        end
    else
        fprintf(2,'Setting user file permissions failed with error code %d\n',status);
    end

    %% remove file attributes 'hidden' and 'read-only'
    fprintf('Setting file attributes for folder %s ...\n',siPath);
    cmd = ['attrib -H -R /S "' fullfile(siPath,'*') '"'];
    [status,cmdout] = system(cmd);
    if status == 0
        if ~isempty(cmdout)
            disp(cmdout);
        end
    else
        fprintf(2,'Setting file attributes failed with error code %d\n',status);
    end
    
    fprintf('Done\n');
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

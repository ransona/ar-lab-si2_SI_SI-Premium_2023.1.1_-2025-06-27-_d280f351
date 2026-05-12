function vDAQs = vDAQPCIeInfo()
    filePath = fileparts(mfilename('fullpath'));
    scriptPath = fullfile(filePath,'vDAQList.ps1');
    cmd = sprintf('powershell.exe -ExecutionPolicy Bypass -File "%s"',scriptPath);
    [status,cmdout] = system(cmd);
    assert(status==0,'Error executing command');
    
    Names             = regexpi(cmdout,'^Name\s*:\s*(.*)$','tokens','lineanchors','dotexceptnewline');
    DeviceIDs         = regexpi(cmdout,'^DeviceID\s*:\s*(.*)$','tokens','lineanchors','dotexceptnewline');
    PCIeCurrentLinks  = regexpi(cmdout,'^PCIeCurrentLink\s*:\s*(.*)$','tokens','lineanchors','dotexceptnewline');
    PCIeCurrentWidths = regexpi(cmdout,'^PCIeCurrentWidth\s*:\s*(.*)$','tokens','lineanchors','dotexceptnewline');
    PCIeMaxLinks      = regexpi(cmdout,'^PCIeMaxLink\s*:\s*(.*)$','tokens','lineanchors','dotexceptnewline');
    PCIeMaxWidths     = regexpi(cmdout,'^PCIeMaxWidth\s*:\s*(.*)$','tokens','lineanchors','dotexceptnewline');
    
    PCIeCurrentLinks  = cellfun(@(s)str2double(s),PCIeCurrentLinks,'UniformOutput',false);
    PCIeCurrentWidths = cellfun(@(s)str2double(s),PCIeCurrentWidths,'UniformOutput',false);
    PCIeMaxLinks      = cellfun(@(s)str2double(s),PCIeMaxLinks,'UniformOutput',false);
    PCIeMaxWidths     = cellfun(@(s)str2double(s),PCIeMaxWidths,'UniformOutput',false);
    
    vDAQs = struct('Name',Names,...
                   'DeviceID',DeviceIDs,...
                   'PCIeCurrentLink',PCIeCurrentLinks,...
                   'PCIeCurrentWidth',PCIeCurrentWidths,...
                   'PCIeMaxLink',PCIeMaxLinks,...
                   'PCIeMaxWidth',PCIeMaxWidths);
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

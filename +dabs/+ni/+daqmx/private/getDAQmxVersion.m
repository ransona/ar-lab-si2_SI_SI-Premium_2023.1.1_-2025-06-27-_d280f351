function [majorVer,minorVer,updateVer] = getDAQmxVersion()
persistent versionInfo

if ~isempty(versionInfo)
    majorVer  = versionInfo.majorVer;
    minorVer  = versionInfo.minorVer;
    updateVer = versionInfo.updateVer;
    return
end

if libisloaded('nicaiu')
    unloadlibrary('nicaiu');
end

try
    switch computer('arch')
        case 'win32'
            loadlibrary('nicaiu',@apiVersionDetect);
        case 'win64'
            loadlibrary('nicaiu',@apiVersionDetect64);
        otherwise
            error('NI DAQmx: Unknown computer architecture :%s',computer(arch));
    end
catch ME
    majorVer =  [];
    minorVer =  [];
    updateVer = [];
    return
end

[code,majorVer] = calllib('nicaiu','DAQmxGetSysNIDAQMajorVersion',0);
assert(code==0);
[code,minorVer] = calllib('nicaiu','DAQmxGetSysNIDAQMinorVersion',0);
assert(code==0);

if ismember('DAQmxGetSysNIDAQUpdateVersion',libfunctions('nicaiu'))
    [code,updateVer] = calllib('nicaiu','DAQmxGetSysNIDAQUpdateVersion',0);
else
    updateVer = 0;
end

unloadlibrary('nicaiu');

versionInfo = struct();
versionInfo.majorVer  = majorVer;
versionInfo.minorVer  = minorVer;
versionInfo.updateVer = updateVer;
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

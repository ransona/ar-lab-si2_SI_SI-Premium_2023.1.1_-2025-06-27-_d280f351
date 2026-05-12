classdef Galvo < scanimage.mroi.scanners.Scanner
    properties
        name
        hDevice
    end
    
    properties
        flytoTimeSeconds(1,1);
        flybackTimeSeconds(1,1);
        useScannerTimebase = false;
        sampleRateHz
        actuatorLag_ms (1,1);          % Amount of time to circularly shift scanning samples due to actuator lag.
    end
    
    methods(Static)
        function obj = default
            hDevice = struct();
            hDevice.name = 'Fake Galvo';
            hDevice.travelRange = [-20 20];
            hDevice.parkPosition = -20;
            hDevice.actuatorLag_ms = 0;
            
            obj=scanimage.mroi.scanners.Galvo(hDevice);
        end
    end

    methods
        % See Note (1)
        function obj=Galvo(hDevice)            
            obj.hDevice = hDevice;
            obj.name = sprintf('Scanner: %s',obj.hDevice.name);
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

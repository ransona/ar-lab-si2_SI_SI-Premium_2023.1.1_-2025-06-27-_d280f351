classdef Resonant < handle
    properties
        hDevice
        fullAngleDegrees;
        bidirectionalScan;
        fillFractionSpatial;
        scannerPeriod;
        reverseLineRead;
    end
    
    properties (Dependent, SetAccess = private)
        fillFractionTemporal;
    end
    
    properties (Hidden)
        fillFractionTemporal_ = [];
    end

    methods(Static)
        function obj = default
            obj=scanimage.mroi.scanners.Resonant(15,5/15,true,7910,0.7,1e5,false);
        end
    end

    methods
        function obj=Resonant(hDevice,scannerPeriod,bidirectionalScan,fillFractionSpatial,reverseLineRead)
            obj.hDevice = hDevice;
            obj.scannerPeriod = scannerPeriod;
            obj.bidirectionalScan = bidirectionalScan;
            obj.fillFractionSpatial = fillFractionSpatial;
            obj.reverseLineRead = reverseLineRead;
        end
        
        function val = get.fillFractionTemporal(obj)
            if isempty(obj.fillFractionTemporal_)
                obj.fillFractionTemporal_ = 2/pi * asin(obj.fillFractionSpatial);
            end
            val = obj.fillFractionTemporal_;
        end
        
        function set.fillFractionSpatial(obj,val)
            obj.fillFractionSpatial = val;
            obj.fillFractionTemporal_ = [];
        end
    end
    
    methods
        function val = get.fullAngleDegrees(obj)
            val = obj.hDevice.angularRange_deg;
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

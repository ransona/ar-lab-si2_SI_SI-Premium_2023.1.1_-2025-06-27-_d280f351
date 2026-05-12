classdef FastZ < scanimage.mroi.scanners.Scanner
    properties (SetAccess = immutable)
        hDevice;
    end
    
    properties
        enableFieldCurveCorr = false;
        fieldCurvature = struct('zs',[],'rxs',[],'rys',[]);
    end
    
    properties (Dependent)
        name
    end
    
    methods
        function obj=FastZ(hDevice)
            if ~isempty(hDevice)
                assert(isa(hDevice,'dabs.resources.devices.FastZ'));
            end
            
            obj.hDevice = hDevice;
        end
    end
    
    methods (Static)
        function obj = default()
            obj = scanimage.mroi.scanners.FastZAnalog([]);
        end
    end
    
    methods (Abstract)
        path_FOV = scanPathFOV(obj,ss,actz,actzRelative,dzdt,seconds,slowPathFov)
        path_FOV = scanStimPathFOV(obj,ss,startz,endz,seconds,maxPoints)
        path_FOV = interpolateTransits(obj,ss,path_FOV,tune,zWaveformType)
        path_FOV = transitNaN(obj,ss,dt)
        path_FOV = zFlybackFrame(obj,ss,frameTime)
        path_FOV = padFrameAO(obj, ss, path_FOV, frameTime, flybackTime, zWaveformType)
        samplesPerTrigger = samplesPerTriggerForAO(obj,ss,outputData)
        
        volts = refPosition2Volts(obj,zs);
        zs = volts2RefPosition(obj,volts);
        zs = feedbackVolts2RefPosition(obj,volts);
    end
    
    methods
        function val = get.name(obj)
            if isempty(obj.hDevice)
                val = 'Not a device.';
            else
                val = obj.hDevice.name;
            end
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

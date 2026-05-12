classdef PolygonalGalvo < scanimage.mroi.scannerset.ScannerSet
    %POLYGONALGALVO Summary of this class goes here
    %   Detailed explanation goes here
    
     properties
        angularRange;
    end
    
    properties (Constant)
        optimizableScanners; % Cell array of strings e.g. {'G','Z'}
    end
    
    properties(Hidden)
        CONSTRAINTS;      % Cell array of scanimage.mroi.constraints function handles
    end
    
    methods
        function obj = PolygonalGalvo(name,resonantx,galvox,galvoy,fastBeams,slowBeams,fastz,fillFractionSpatial)
            %POLYGONALGALVO Describes a polygonal-galvo-galvo set
            obj = obj@scanimage.mroi.scannerset.ScannerSet(name,fastBeams,slowBeams,fastz);
            
            scanimage.mroi.util.asserttype(resonantx,'scanimage.mroi.scanners.Resonant');
            if ~isempty(galvox)
                scanimage.mroi.util.asserttype(galvox,'scanimage.mroi.scanners.Galvo');
                obj.CONSTRAINTS.scanimage_mroi_scanfield_ImagingField{end+1} = @scanimage.mroi.constraints.xCenterInRange;
            end
            scanimage.mroi.util.asserttype(galvoy,'scanimage.mroi.scanners.Galvo');
            
            obj.name = name;
            obj.scanners={resonantx,galvox,galvoy};
            obj.fillFractionSpatial = fillFractionSpatial;
        end
        
         % converts a path for all scanners (resonant, galvos, beams)
        % from field of view coordinates to output volts
        ao_volts = pathFovToAo(obj,path_FOV);
        
        % generates scan path for all scanners (resonant, galvos, beams)
        % in field of view coordinates
        [path_FOV, seconds] = scanPathFOV(obj,scanfield,scanPathFOV,actz,actzRelative,dzdt)
        
        % optimizes an analog waveform for tracking accuracy
        ao_volts = optimizeAO(obj,scanner,volts)
        
        % Returns the time required to scan the scanfield in seconds
        % scanfield must be a scanimage.mroi.scanfield.ScanField object.
        seconds  = scanTime(obj,scanfield);
        
        % Returns the total time required to scan a line (including scanner
        % turnaround time) and the time during which the acquisition takes
        % place
        [scanPeriod,acquisitionPeriod] = linePeriod(obj,scanfield);
        
        % Returns the active acquisition time for each line of the
        % scanfield (for precalculation of beams output)
        [startTime,endTime] = acqActiveTimes(obj,scanfield);

        % Returns array of mirror positions in FOV coordinates for parking the mirror
        % during an active scan
        position_FOV = mirrorsActiveParkPosition(obj);
        
        % Returns the estimated time required to position the scanners when
        % moving from scanfield to scanfield.
        %
        % The park position is represented by NaN
        % Either scanfield_from or scanfield_to may be NaN
        seconds  = transitTime(obj,scanfield_from,scanfield_to);
        
        % Returns the path in field of view coordinates for transitioning from one scanfield
        % to another. the transti path is represented as NaN and can be filled
        % in subsequently with the function interpolateTransits
        %
        % The park position is represented by NaN
        % Either scanfield_from or scanfield_to may be NaN
        % transits samples will be filled in with NaN
        path_FOV = transitNaN(obj,scanfieldFrom,scanfieldTo);
        
        % interpolates over NaN ranges of a path in FOV coordinates 
        path_FOV = interpolateTransits(obj,path_FOV,zWaveformType);
        
        % generates path in field of view coordinates for a flyback frame
        path_FOV = zFlybackFrame(obj, frameTime);
        
        % pads all channels to the specified time duration with NaN's
        path_FOV = padFrameAO(obj, path_FOV, frameTime, flybackTime, zWaveformType);
        
        % returns number of samples per trigger for each scanner
        samplesPerTrigger = samplesPerTriggerForAO(obj,outputData);
        
        % returns triggerType (lineClk/frameClk) and configuration of
        % refernce clock
        cfg = beamsTriggerCfg(obj);
        
        v = frameFlybackTime(obj);
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

classdef FastBeam < scanimage.mroi.scanners.Beam
    properties
        interlaceDecimation = 1;
        interlaceOffset = 0;
        powerBoxes = [];
        sampleRateHz;
        flybackBlanking = true;
        turnAroundBlanking = true;
        
        linePhase;          % [seconds]
        beamClockDelay;     % [seconds]
        beamClockExtend;    % [seconds]
    end
    
    methods(Static)
        function obj = default
            obj=scanimage.mroi.scanners.FastBeam([]);
        end
    end
    
    methods % scanimage.mroi.scanners.Beam
        function obj = applySettingsFromRoi(obj,hRoi)
            obj = applySettingsFromRoi@scanimage.mroi.scanners.Beam(obj, hRoi);
            obj.interlaceDecimation = choose(obj.interlaceDecimation,hRoi.interlaceDecimation);
            obj.interlaceOffset     = choose(obj.interlaceOffset,hRoi.interlaceOffset);
            
            function val = choose(val,roiVal)
                assert(isnumeric(val));
                roiVal(end+1:obj.beamIdx) = NaN;
                roiVal = roiVal(obj.beamIdx);
                
                if ~isnan(roiVal)
                    val = roiVal;
                end
            end
        end
        
    end
    
    methods
        function obj = FastBeam(hDevice)
            obj = obj@scanimage.mroi.scanners.Beam(hDevice);
        end
    end
    
    methods
        function beamPath = generateBeamsPathStimulus(obj,path_FOV,scanfield,parkfunctiondetected,repetitionsInteger,durationPerRepetitionInt,durationPerRepetitionFrac,totalduration,maxPoints)
            if nargin < 9
                maxPoints = inf;
            end
            
            if isempty(scanfield.powerFractions)
                powerFrac = obj.powerFraction;
            elseif numel(scanfield.powerFractions) == 1
                powerFrac = scanfield.powerFractions;
            elseif numel(scanfield.powerFractions) >= obj.beamIdx
                powerFrac = scanfield.powerFractions(obj.beamIdx);
            end
            
            if isnan(powerFrac)
                powerFrac = obj.powerFraction;
            end
            
            [tf, idx] = ismember('poweredPause',scanfield.stimparams(1:2:end));
            poweredPause = tf && scanfield.stimparams{idx*2};
            
            isn = isfield(path_FOV, 'G') && all(all(isnan(path_FOV.G)));
            
            if (isn || parkfunctiondetected) && (~poweredPause)
                % detected output from the pause/park stimulus function. set
                % beam powers to zero
                numsamples = round(totalduration * obj.sampleRateHz);
                beamPath = zeros(numsamples,1);
            else
                numsamples = round(durationPerRepetitionInt * obj.sampleRateHz);
                tt = linspace(0,(numsamples-1)/obj.sampleRateHz,min(numsamples,maxPoints));
                numsamples = length(tt); % recalculate in case maxPoints < numsamples
                
                beamPath = scanfield.beamsfcnhdl(tt,powerFrac,'actualDuration',durationPerRepetitionInt,'scanfield',scanfield);
                assert(numel(beamPath) == numsamples,...
                    ['Beams generation function ''%s'' returned incorrect number of samples:',...
                    'Expected: %d Returned: %d'],...
                    func2str(scanfield.beamsfcnhdl),numsamples,numel(beamPath));
                
                beamPath = beamPath(:);
                
                % apply repetitions
                beamPath = repmat(beamPath,repetitionsInteger,1);
                
                % fractional repetitions
                numsamples = round(durationPerRepetitionFrac * obj.sampleRateHz);
                beamPath(end+1:end+numsamples) = beamPath(1:numsamples);
            end
            
            beamPath(end) = 0;
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

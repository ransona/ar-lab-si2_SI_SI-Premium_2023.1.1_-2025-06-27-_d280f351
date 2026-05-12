%% SCANNER FREQUENCY CALIBRATION
% This interface can be used when the scanner has the ability to calibrate
% a "resonant" scan frequency. When a scanner implements this class, it
% can be used in the ResonantFrequencyCalibrator to find the optimal scan frequency

classdef ScannerFrequencyCalibration < handle
    properties (SetObservable,Hidden)
        frequencyLUT = zeros(0,2); % Nx2 array of frequencies (Hz) and amplitudes measured during calibration
    end

    % properties used for calibration (shared with SyncedScanner)
    properties (Abstract,SetObservable)
        nominalFrequency_Hz;
        angularRange_deg;
    end

    methods (Abstract)
        % testAmplitudeResponse
        %  This function should return a scalar value representing the
        %  amplitude at the specified frequency. The amplitude can be
        %  arbitrary units, but the units should be consistent between calls.
        amplitudeResponse = testAmplitudeResponse(obj,frequency_Hz,testAmplitude_deg);
    end
    
    methods
        function hGUI = openFrequencyCalibrationGUI(obj)
            hGUI = dabs.resources.devices.private.ResonantFrequencyCalibrator(obj);
        end

        function actualFrequency_Hz = getClosestFrequency(obj,nominalFrequency_Hz)
            actualFrequency_Hz = nominalFrequency_Hz;
        end

        % optional methods for saving/loading calibration data
        function saveFrequencyCalibration(obj)
        end

        function success = loadFrequencyCalibration(obj)
            success = true;
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

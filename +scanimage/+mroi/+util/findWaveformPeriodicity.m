function [period,numPeriods] = findWaveformPeriodicity(xx)
    assert(isvector(xx),'Expect vector as input');
    xx = xx(:); % ensure input is a column vector
    len = numel(xx);
    
    if all(xx==xx(1))
        period = 1;
        numPeriods = len;
        return
    end

    % calculate waveform autocorrelation
    xx_fft = fft(xx);
    r = ifft( xx_fft .* conj(xx_fft) );
    r = [r(end-len+2:end) ; r(1:len)];

    % find peaks in autocorrelation
    peak = max(r);
    tolerance = 1e-7;
    r(r<(peak-tolerance)|r>(peak+tolerance)) = 0;
    foundPeriod = find(r,1,'first'); % we want to find the smallest period, which corresponds to the first peak

    period = len;
    numPeriods = 1;
    if ~isempty(foundPeriod) && foundPeriod~=len && mod(len,foundPeriod)==0
        % ensure that periodicity is perfect
        xx_ = reshape(xx,foundPeriod,[]);
        xx_max = max(xx_,[],2);
        xx_min = min(xx_,[],2);
        dd = abs(xx_max - xx_min);

        tolerance = 1e-6;
        if all(all(dd < tolerance))
            % all repetitions within tolerance
            period = foundPeriod;
            numPeriods = len/period;
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

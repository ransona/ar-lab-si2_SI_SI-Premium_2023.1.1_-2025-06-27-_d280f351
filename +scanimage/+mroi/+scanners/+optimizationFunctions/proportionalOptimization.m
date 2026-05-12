function [done,nextOutputWaveform,optimizationData] = proportionalOptimization(linearScanner,iterationNumber,sampleRateHz,desiredWaveform,outputWaveform,feedbackWaveform,optimizationData)

if iterationNumber == 1
    optimizationData = struct();
    
    delay = findDelay(feedbackWaveform,desiredWaveform);
    if isempty(delay)
        delay = 0; % no correlation found. probably because waveform is constant
    end
    
    optimizationData.delay = delay;
    nextOutputWaveform = circshift(outputWaveform,-optimizationData.delay);
else
    err = feedbackWaveform - desiredWaveform;
    err_shift = circshift(err,-optimizationData.delay);

    K = 0.5;
    nextOutputWaveform = outputWaveform - K * err_shift;
end

done = iterationNumber >= 5;
end

function delay = findDelay(waveform1,waveform2)
% calculate waveform autocorrelation
    assert(numel(waveform1)==numel(waveform2));
    len = numel(waveform1);
    r = ifft( fft(waveform1) .* conj(fft(waveform2)) );
    r = [r(end-len+2:end) ; r(1:len)];
    
    peakLoc = scanimage.util.peakFinder(r);
    peakLoc(r(peakLoc)<0.99*max(r(peakLoc))) = []; % filter out peaks to compensate for rounding errors
    delay = min(peakLoc);
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

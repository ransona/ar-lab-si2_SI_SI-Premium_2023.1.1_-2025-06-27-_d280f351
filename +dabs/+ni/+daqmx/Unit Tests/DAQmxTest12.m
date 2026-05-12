
import Devices.NI.DAQmx.*

deviceName = 'Dev1';
sampleRate = 10000;
duration = 8;







if exist('hAI','var') && isvalid(hAI);
    delete(hAI);
end

hAI = Task('An AI Task');
hAI.createAIVoltageChan(deviceName,[0:1]);
hAI.cfgSampClkTiming(10000,'DAQmx_Val_FiniteSamps',50000);
hAI.everyNSamples = 10000;
hAI.everyNSamplesEvtCallbacks = 'test12Callback';

hAI.start();

while ~hAI.isTaskDone()
    pause(1);
end

hAI.stop();



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

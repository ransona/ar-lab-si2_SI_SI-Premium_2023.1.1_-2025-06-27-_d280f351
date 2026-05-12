function hTask = registrationTest(AIDevice,AIChans)
%REGISTRATIONTEST Test of register/unregister functionality with DAQmx package

import Devices.NI.DAQmx.*

taskName = 'Registration Test Task';
taskMap = Task.getTaskMap();
if taskMap.isKey(taskName)
    delete(taskMap(taskName));
end
hTask = Task(taskName);


sampRate = 10e3;
numChunks = 4;
numIterations = 30;
chunkTime = 0.2; %Time in seconds

hTask.createAIVoltageChan(AIDevice,AIChans);
hTask.cfgSampClkTiming(sampRate,'DAQmx_Val_FiniteSamps',numChunks*round(sampRate*chunkTime));
hTask.registerDoneEvent(@nextIterationFcn);

iterationCounter = 0;
chunkCounter = 0;
nextIterationFcn();

return;

    function iterationReportFcn(~,~)
        chunkCounter = chunkCounter + 1;
        fprintf(1,'Received Chunk # %d of Iteration # %d\n',chunkCounter,iterationCounter);               
    end

    function nextIterationFcn(~,~)

        hTask.stop();
        if iterationCounter
            fprintf(1,'Completed Iteration # %d\n',iterationCounter);
        end       
                        
        if ~mod(iterationCounter,2)
            hTask.registerEveryNSamplesEvent(@iterationReportFcn,round(sampRate*chunkTime));
        else
            hTask.registerEveryNSamplesEvent();
        end
        
        chunkCounter = 0;
        
        if iterationCounter < numIterations
            iterationCounter = iterationCounter + 1;        
            hTask.start();
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

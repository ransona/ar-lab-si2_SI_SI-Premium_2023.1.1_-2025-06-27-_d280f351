function test8Callback()
%   Function called at end of each iteration

global callbackStruct8


%Increment iteration counter
callbackStruct8.iterationCounter = callbackStruct8.iterationCounter + 1; %Incremented count reflects the iteration that's about to run

%Prepare the data for the next iteration, and start the tasks
if callbackStruct8.iterationCounter <= callbackStruct8.numIterations
    
    %Read & plot AI data
    [numSamps,inputData] = callbackStruct8.hAI(1).readAnalogData(callbackStruct8.numSamples, callbackStruct8.numSamples, 'scaled',1);
    
    set(callbackStruct8.hlines(1),'YData',inputData(:,1));
    set(callbackStruct8.hlines(2),'YData',inputData(:,2));
    drawnow expose;    
    
    %Stop the tasks -- this is needed so they can be restarted
    callbackStruct8.hCtr(1).stop()
    callbackStruct8.hAI(1).stop();
    callbackStruct8.hAO(1).stop();
    callbackStruct8.hDO(1).stop()
    pause(.5);
end

%Prepare the data for the next iteration, and start the tasks
if callbackStruct8.iterationCounter < callbackStruct8.numIterations       
    
    %Start the tasks so they can await trigger. Note these methods are vectorized.
    callbackStruct8.hAI(1).start();
    callbackStruct8.hAO(1).start();
    callbackStruct8.hDO(1).start();
    callbackStruct8.hCtr(1).start();
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

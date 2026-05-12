import Devices.NI.DAQmx.*
global CBDATA

sampleRate = 50000;
everyNSamples = 50000;
acqTime = 5;

hTask = Task('a task');
try
    hChans = hTask.addAnalogInputChannels('Dev1',0:2);
    
    %%%Unfortunately, the following doesn't suffice to correctly configure the timing.
    %Basically, I can't figure out how to replicate the DAQmxCfgSampClkTiming macro
%     set(hTask,'sampClkSrc','ai/SampleClockTimebase');
%     set(hTask,'sampClkTimebaseDiv',round(get(hTask,'sampClkTimebaseRate')/sampleRate));
%     set(hTask,'sampClkRate',sampleRate);
%     set(hTask,'sampQuantSampMode','DAQmx_Val_FiniteSamps');    
%     set(hTask,'sampQuantSampPerChan',round(acqTime*sampleRate));
%     %hTask.control('DAQmx_Val_Task_Verify');
    
    %Use the DAQmx 'macro' to configure the timing properties en masse
    hTask.cfgSampClkTiming('',sampleRate,'','DAQmx_Val_FiniteSamps',round(sampleRate*acqTime));    
   
    %Set voltage range explicitly, ensuring same range for all product categories
    set(hTask.channels,'min',-10);
    set(hTask.channels,'max',10);
    
    status1 = hTask.registerEveryNSamplesCallback(everyNSamples,'test1Callback_1')
    %status2 = hTask.registerEveryNSamplesCallback(everyNSamples,'test1Callback_2')
    
    %Start the task
    %keyboard;
    CBDATA.task = hTask;
    CBDATA.everyNSamples = everyNSamples;
    CBDATA.count = 0;
    hTask.start();
    'Started task!'
           
    %Wait till completion
    while true
        tf =  hTask.isDone();
        if tf
            'Finished!'
            break;
        else
            'Still Acquiring'
            pause(1);
        end
    end
    
    %Clean up
    hTask.clear(); %Avoids deleting the System object
catch
    hTask.clear();
    rethrow(lasterror);
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

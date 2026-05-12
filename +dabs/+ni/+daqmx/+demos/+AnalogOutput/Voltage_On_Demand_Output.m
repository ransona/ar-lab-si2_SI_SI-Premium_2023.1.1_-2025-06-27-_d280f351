function Voltage_On_Demand_Output()
%% Voltage On Demand Output
% This examples demonstrates an analog ouput, that is updated on demand

%% Parameters for the output
devName = 'Dev1'; % the name of the DAQ device as shown in MAX

% Channel configuration
physicalChannels = 0;   % a scalar or an array with the channel numbers
minVoltage = -10;       % channel input range minimum
maxVoltage = 10;        % channel input range maximum

% Generate data for output
outputData = 0:10;
outputDelay = 1;        %output delay in seconds

import dabs.ni.daqmx.*  % import the NI DAQmx adapter

try
    % create and configure the task
    hTask = Task('Task'); 
    hTask.createAOVoltageChan(devName,physicalChannels,[],minVoltage,maxVoltage);

    hTask.start();
    
    for data = outputData
        hTask.writeAnalogData(data);
        disp(['output ' num2str(data) 'V']);
        pause(outputDelay);
    end
    
    % clean up task 
    hTask.stop();
    delete(hTask);
    clear hTask;
    
    disp('Output Finished');
    
catch err % clean up task if error occurs
    if exist('hTask','var')
        delete(hTask);
        clear hTask;
    end
    rethrow(err);
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

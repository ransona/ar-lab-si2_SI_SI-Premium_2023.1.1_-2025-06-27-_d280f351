function test1Callback_1()
global CBDATA

'yo'
CBDATA.count = CBDATA.count + 1;


idx = 1;
%%%Put this section in, if using 2 tasks...need this for demo purposes, until we implement passing the task handle as an argument to callback
if ~mod(CBDATA.count,2)
    idx = 2;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
task = CBDATA.task(idx);
everyNSamples = CBDATA.everyNSamples(idx);

disp(['Visit #' num2str(CBDATA.count) ' to callback']);

[sampsRead, outputData] = readAnalogData(task, everyNSamples, everyNSamples, 'native', 2);
disp(['Read ' num2str(sampsRead) ' samples into a ' num2str(size(outputData,1)) ' X ' num2str(size(outputData,2)) ' matrix of CLASS ''' class(outputData) '''']);
% sampsRead = readAnalogData(CBDATA.task, CBDATA.everyNSamples, CBDATA.everyNSamples, 'scaled', 2);
% disp(['Read ' num2str(sampsRead) ' samples']);

assignin('base','outputData',outputData);




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

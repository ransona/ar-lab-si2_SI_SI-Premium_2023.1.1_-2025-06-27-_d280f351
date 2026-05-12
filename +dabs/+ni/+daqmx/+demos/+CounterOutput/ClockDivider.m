function hTask = ClockDivider()
deviceName = 'PXI1Slot3';
ctrNumber = 3;
clockSource = '/PXI1Slot3/PXI_CLK10';
outputTerminal = 'PFI14';
clkDivisor = 4;

assert(mod(clkDivisor,1)==0 && clkDivisor>=4,'Divisor must be an integer >= 4'); % lowTicks and highTicks must be >= 2

lowTicks = ceil(clkDivisor/2);
highTicks = floor(clkDivisor/2);

hTask = most.util.safeCreateTask('Clock Divider');
hTask.createCOPulseChanTicks(deviceName, ctrNumber, '', clockSource, lowTicks, highTicks);
hTask.channels(1).set('pulseTerm',outputTerminal);
hTask.channels(1).set('pulseTicksInitialDelay',2); % minimum of 2
hTask.cfgImplicitTiming('DAQmx_Val_ContSamps');

hTask.start();
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

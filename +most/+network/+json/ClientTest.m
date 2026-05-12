example1 = struct();
example1.command = 'eval';
example1.function = 'disp(''This works.'')';
example1.num_outputs = 0;

example2 = struct();
example2.command = 'feval';
example2.function = 'hSI.startFocus';
example2.inputs = struct(); %define inputs as msg.inputs.input1 = 1; msg.inputs.input2 = 2;
example2.num_outputs = 0;

example3 = struct();
example3.command = 'get';
example3.property = 'hSI.hRoiManager.scanZoomFactor';

example4 = struct();
example4.command = 'set';
example4.property = 'hSI.hRoiManager.scanZoomFactor';
example4.value = 10;

% which example to use:
msg = example1;

% convert struct to json
msg = jsonencode(msg);
fprintf('Sending JSON string: %s\n',msg);
% convert json to byte array
data = unicode2native(msg,'UTF-8');

hClient = most.network.tcpip.Client('127.0.0.1',5555);

% first send size of message as a uint64 (8 bytes)
numBytes = numel(data);
numBytes_raw = typecast(uint64(numBytes),'uint8');
hClient.send(numBytes_raw);
% then send data
hClient.send(data);

% read 8 bytes to determine response size
rspNumBytes = typecast(hClient.read(8),'uint64');
rsp = hClient.read(rspNumBytes);
hClient.delete();
rsp = native2unicode(rsp,'UTF-8');
fprintf('Received JSON string: %s\n',rsp);
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

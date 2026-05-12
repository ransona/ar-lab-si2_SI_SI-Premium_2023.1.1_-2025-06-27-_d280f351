serverAddress = '127.0.0.1';
serverPort = 5555;

hClient = most.network.tcpip.Client(serverAddress,serverPort); % open connection to server

for idx = 1:10
    msg = sprintf('Message #%d', idx);
    
    msg_uint8 = unicode2native(msg, 'utf-8');   % convert char to uint8 using utf-8 encoding
    numBytes = numel(msg);
    fprintf('Client sending message to server\n');
    
    s = tic();
    hClient.send(msg_uint8);
    rsp_uint8 = hClient.read(numBytes);
    e = toc(s);
    
    rsp = native2unicode(rsp_uint8, 'utf-8');   % convert uint8 to char using utf-8 encoding
    
    assert(strcmp(rsp,msg),'Data corruption, message and response do not match');
    fprintf('Client received echo from server. Roundtrip time: %fms\n\n',e*1e3);
    
    pause(0.1);
end

hClient.delete();
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

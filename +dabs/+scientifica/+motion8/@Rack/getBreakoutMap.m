function Channel2Map = getBreakoutMap(obj)
    import dabs.scientifica.motion8.Axis;
    most.idioms.mustBeValidObj(obj);
    Channel2Map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    Mappings = obj.Inner.Mapping;
    for iEntry = 1:Mappings.Length
        Entry = Mappings(iEntry);

        Channel2Map(bob2ChannelNumber(Entry.Channel)) = struct( ...
            'DeviceNumber', device2Number(Entry.Device) ...
            , 'Axis', Axis.fromMotion8Axis(Entry.Axis) ...
            );
    end
end

function deviceNumber = device2Number(DeviceNumber)
    import('Scientifica.Motion8.Device');
    switch DeviceNumber
        case Device.Device1
            deviceNumber = 1;
        case Device.Device2
            deviceNumber = 2;
    end
end

function channelNumber = bob2ChannelNumber(Channel)
    import('Scientifica.Motion8.BobChannel');
    switch Channel
        case BobChannel.Channel1
            channelNumber = 1;
        case BobChannel.Channel2
            channelNumber = 2;
        case BobChannel.Channel3
            channelNumber = 3;
        case BobChannel.Channel4
            channelNumber = 4;
        case BobChannel.Channel5
            channelNumber = 5;
        case BobChannel.Channel6
            channelNumber = 6;
        case BobChannel.Channel7
            channelNumber = 7;
        case BobChannel.Channel8
            channelNumber = 8;
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

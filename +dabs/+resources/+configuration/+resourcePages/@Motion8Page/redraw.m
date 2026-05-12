function redraw(obj)
    most.idioms.mustBeValidObj(obj);
    Motor = obj.hResource;
    if isempty(Motor.rackUids)
        set(obj.RackSelectionMenu ...
            , 'String', {'none'} ...
            , 'BackgroundColor', most.constants.Colors.lightRed);
    else
        set(obj.RackSelectionMenu ...
            , 'String', num2cell(Motor.rackUids) ...
            , 'BackgroundColor', [.94, .94, .94]);
    end
    if 0 < strlength(Motor.selectedRackId) && any(Motor.selectedRackId == Motor.rackUids)
        obj.RackSelectionMenu.Value = find(Motor.selectedRackId == Motor.rackUids, 1);
    end
    
    if isempty(Motor.selectedDeviceIndex)
        set(obj.Device1Toggle, 'Value', obj.Device1Toggle.Min);
        set(obj.Device2Toggle, 'Value', obj.Device2Toggle.Min);
    elseif 1 == Motor.selectedDeviceIndex
        set(obj.Device1Toggle, 'Value', obj.Device1Toggle.Max);
        set(obj.Device2Toggle, 'Value', obj.Device2Toggle.Min);
    else
        set(obj.Device1Toggle, 'Value', obj.Device1Toggle.Min);
        set(obj.Device2Toggle, 'Value', obj.Device2Toggle.Max);
    end
    
    obj.refreshSummary();
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

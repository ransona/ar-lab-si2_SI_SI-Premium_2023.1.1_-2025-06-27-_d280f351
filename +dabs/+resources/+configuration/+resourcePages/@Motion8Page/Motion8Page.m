classdef Motion8Page < dabs.resources.configuration.ResourcePage
    properties (SetAccess = private)
        RackSelectionMenu;
        Device1Toggle;
        Device2Toggle;
        DevicePropertiesText;
    end

    methods
        %% Lifecycle
        function obj = Motion8Page(Resource, Parent)
            obj@dabs.resources.configuration.ResourcePage(Resource, Parent);
        end

        %% ResourcePage
        makePanel(obj, Parent);

        redraw(obj);

        function apply(obj)
            most.idioms.mustBeValidObj(obj);
            Motor = obj.hResource;
            selectedId = string(obj.RackSelectionMenu.String{obj.RackSelectionMenu.Value});
            assert("none" ~= lower(selectedId), 'no valid selected Rack ID');
            Motor.selectedRackId = selectedId;
            assert(obj.Device1Toggle.Value == obj.Device1Toggle.Max ...
                || obj.Device2Toggle.Value == obj.Device2Toggle.Max ...
                , 'No rack device selected.');
            if obj.Device2Toggle.Value == obj.Device2Toggle.Max
                Motor.selectedDeviceIndex = 2;
            else
                Motor.selectedDeviceIndex = 1;
            end
            Motor.reinit();
            Motor.saveMdf();
        end

        function remove(obj)
            most.idioms.mustBeValidObj(obj);
            obj.hResource.deleteAndRemoveMdfHeading();
        end
    end

    methods (Access = private)
        function refreshSummary(obj)
            Motor = obj.hResource;
            Summary = Motor.getDeviceSummary();
            fields = fieldnames(Summary);
            maxColumnSize = 1 + max(cellfun('length', fields));
            values = struct2cell(Summary);
            formatted = cell(size(fields));
            for iField = 1:length(fields)
                name = fields{iField};
                value = values{iField};
                numSpaces = maxColumnSize - length(name);
                formatted{iField} = sprintf('%s%s: %s', repmat(' ', 1, numSpaces), name, value);
            end
            fullStr = strjoin(formatted, newline());
            if 0 == strlength(fullStr)
                obj.DevicePropertiesText.String = 'N/A';
            else
                obj.DevicePropertiesText.String = fullStr;
            end
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

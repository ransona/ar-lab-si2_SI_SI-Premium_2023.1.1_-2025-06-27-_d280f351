classdef Shutter < dabs.resources.Device & dabs.resources.widget.HasWidget
    properties (SetAccess = protected)
        WidgetClass = 'dabs.resources.widget.widgets.ShutterWidget';
    end
    
    methods
        function obj = Shutter(name)
            obj@dabs.resources.Device(name);
        end
    end
    
    properties (Abstract, SetObservable)
        openTime_s; % time it takes for shutter to fully open
    end

    properties (SetObservable)
        shutterTarget = dabs.resources.devices.shutter.ShutterTarget.empty();
    end
    
    properties (Abstract, SetObservable, SetAccess=protected)
        isOpen;
    end
    
    methods (Abstract)
        startTransition(obj,tf);
        waitTransitionComplete(obj);
    end
    
    methods
        function transition(obj,tf)
            obj.startTransition(tf);
            obj.waitTransitionComplete();
        end
        
        function open(obj)
            obj.transition(true);
        end
        
        function close(obj)
            obj.transition(false);
        end
    end

    methods
        function set.shutterTarget(obj,val)
            if isempty(val)
                val = dabs.resources.devices.shutter.ShutterTarget.empty();
            end
            val = most.idioms.string2Enum(val,'dabs.resources.devices.shutter.ShutterTarget');

            validateattributes(val,{'dabs.resources.devices.shutter.ShutterTarget'},{});

            obj.shutterTarget = unique(val(:)');
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

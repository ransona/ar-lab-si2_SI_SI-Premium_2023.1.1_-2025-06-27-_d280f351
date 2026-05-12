classdef FastZAnalog < dabs.resources.devices.FastZ & dabs.resources.devices.LinearScanner & dabs.resources.widget.HasWidget
    properties (SetAccess=protected)
        WidgetClass = 'dabs.resources.widget.widgets.FastZWidget';
    end
    
    properties (SetObservable)
        hFrameClockIn = dabs.resources.Resource.empty();
        positionInterpolationAlgorithm = 'default';
        moveTimeout_s = 1;
    end
    
    methods
        function obj = FastZAnalog(name)
            obj@dabs.resources.devices.FastZ(name);
            obj@dabs.resources.devices.LinearScanner(name);
            obj.units = 'um';
            
            obj.numSmoothTransitionPoints = 1;
        end
    end
    
    methods
        function deinit(obj)
            obj.deinit@dabs.resources.devices.LinearScanner();
        end
        
        function reinit(obj)
            obj.reinit@dabs.resources.devices.LinearScanner();
            
            try
                obj.assertNoError();
                
                if most.idioms.isValidObj(obj.hFrameClockIn)
                    assert(obj.hAOControl.hDAQ==obj.hFrameClockIn.hDAQ ...
                        ,'The frame clock input needs to be on the same DAQ board as the analog control output.')
                end
            catch ME
                obj.deinit();
                obj.errorMsg = sprintf('%s: initialization error: %s',obj.name,ME.message);
                most.ErrorHandler.logError(ME,obj.errorMsg);
            end
        end
    end
    
    methods
        function move(obj,position)
            obj.pointPosition(position);
        end
        
        function moveBlocking(obj,position,timeout)
            if nargin < 3 || isempty(timeout)
                timeout = obj.moveTimeout_s;
            end
            
            obj.move(position);
            obj.waitMoveComplete(timeout);
        end
    end
    
    methods
        function set.hFrameClockIn(obj,val)
            val = obj.hResourceStore.filterByName(val);
            
            if ~isequal(obj.hFrameClockIn,val)
                if most.idioms.isValidObj(val)
                    validateattributes(val,{'dabs.resources.ios.PFI'},{'scalar'});
                end
                
                obj.deinit();
                
                obj.hFrameClockIn.unregisterUser(obj);
                obj.hFrameClockIn = val;
                obj.hFrameClockIn.registerUser(obj,'Frame Clock');
            end
        end
        
        function set.positionInterpolationAlgorithm(obj,val)
            validateattributes(val,{'char'},{'scalartext'});
            assert(any(strcmpi(val,{'tryall','default','maa','spline','pchip','linear','linearwithsettle'})),'positionInterpolationAlgorithm must be one of ''tryall'',''default'',''maa'',''spline'',''pchip'',''linear'',or ''linearwithsettle''.');
            obj.positionInterpolationAlgorithm = val;
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

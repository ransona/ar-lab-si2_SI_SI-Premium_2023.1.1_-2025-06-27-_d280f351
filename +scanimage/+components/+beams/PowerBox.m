classdef PowerBox < most.util.Uuid
    %POWERBOX class to wrap and validate attributes of power box properties
    %   Class to wrap and validate attributes of power box properties.
    %   Power boxes historically were structs, but since powerFractions
    %   were often given as percents (0-100) rather than decimals (0-1),
    %   properties must be checked.
    
    properties (SetObservable, AbortSet)
        rect = [0.25 0.25 0.5 0.5]; %normalized [x location, y location, width height]
        powers = NaN;
        name = '';
        oddLines = true;
        evenLines = true;
        mask = [];
        zs = [];
                
        useSampleAbsolute = false; %Whether the powerbox should be defined relative to the sample (true) or the focus (false)
        sampleAbsoluteLocation;    %Where the powerbox is located in sample relative space (microns)
        locked = false              %Whether the size and/or position of the powerbox is permitted to change.
    end
    
    methods
        function obj = PowerBox()
        end
    end
    
    %% Conversion to struct
    
    methods
        function s = struct(obj) %to convert object to struct
            s = struct('rect', obj.rect,  ...
            'powers'    , obj.powers,     ...
            'name'      , obj.name,       ...
            'oddLines'  , obj.oddLines,   ...
            'evenLines' , obj.evenLines,  ...
            'mask'      , obj.mask,       ...
            'zs'        , obj.zs);

            s.useSampleAbsolute = obj.useSampleAbsolute;
            s.sampleAbsoluteLocation = obj.sampleAbsoluteLocation;
        end
    end
        
    %% PROP ACCESS
    methods
        function set.rect(obj,val)
            validateattributes(val,{'numeric'},{'vector','real','ncols',4});
            val = most.idioms.ifthenelse(iscolumn(val), val', val);
            
            if ~val(3)
                val(3) = 0.05;
            end
            
            if ~val(4)
                val(4) = 0.05;
            end
            
            obj.rect = val;
        end
        
        function set.powers(obj, val)
            nanMask = isnan(val);
            validateattributes(val(~nanMask),{'numeric'},{'nonnegative','<=',1, 'real'});
            
            rs = dabs.resources.ResourceStore();
            hBeamsDevices_ = rs.filterByClass('dabs.resources.devices.BeamModulator');
            totalNumBeams = numel(hBeamsDevices_);
            
            hBeamsComponent = rs.filterByName('SI Beams');
            
            if isempty(val)
                val = NaN;
            end
            
            if isscalar(val)
                val = repmat(val,1, totalNumBeams);
            else
                assert(numel(val)== totalNumBeams,...
                    'The ''%s'' value must be a vector of length %d -- one value for each beam',...
                    'PowerBox.powers', totalNumBeams);
                
                fastBeamMask = cellfun(@(hB)isa(hB,'dabs.resources.devices.BeamModulatorFast'),hBeamsComponent.hBeams);
                val(~fastBeamMask) = NaN; % only fast beams can use power boxes
                
                s = size(val);
                if s(1) > s(2)
                    val = val';
                end
            end
            
            obj.powers = val;
        end
        
        function set.mask(obj, val)
            notNaNMask = ~isnan(val);
            assert(isnumeric(val) && numel(size(val))<= 2 && all(val(notNaNMask)>=0) && all(val(notNaNMask)<= 1),'Powerbox mask must be numeric 2D array with all values >=0 and <=1');
            obj.mask = double(val);
        end
        
        function set.name(obj, val)
            validateattributes(val,{'char'},{'row'});
            obj.name = val;
        end
        
        function set.oddLines(obj, val)
            validateattributes(val,{'logical'},{'scalar'});
            obj.oddLines = val;
        end
        
        function set.evenLines(obj, val)
            validateattributes(val,{'logical'},{'scalar'});
            obj.evenLines = val;
        end
        
        function set.zs(obj, val)
            validateattributes(val,{'numeric'},{'vector', 'real'});
            obj.zs = val;
        end
        
        function set.sampleAbsoluteLocation(obj, val)
            validateattributes(val,{'numeric'},{'vector','real'});
            if ~obj.locked
                obj.sampleAbsoluteLocation = val;
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

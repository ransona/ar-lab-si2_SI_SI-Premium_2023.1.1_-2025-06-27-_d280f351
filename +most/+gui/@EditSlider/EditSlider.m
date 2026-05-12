classdef EditSlider < handle
    %EDITSLIDER Edit/Slider pair that binds values to each other

    properties
        ValueChangedFunction(1,1) function_handle = @(newValue)[];
    end

    properties (Dependent, Transient, SetObservable, AbortSet)
        Min double;
        Max double;
        Value double; % note: setting this property does not trigger notifications
    end

    properties (SetObservable, AbortSet)
        IsRounded logical;
    end

    properties (Access = private)
        Slider most.gui.slider;
        Edit matlab.ui.control.UIControl;
        LifetimeListener(:,1) event.listener;
        SelfListener(:,1) event.listener;
    end
    
    methods
        function obj = EditSlider(varargin)
            Parser = inputParser;
            Parser.addParameter('Parent', matlab.ui.Figure.empty());
            Parser.addParameter('Slider', most.gui.slider.empty());
            Parser.addParameter('Edit', matlab.ui.control.UIControl.empty());
            Parser.addParameter('Min', 0 ...
                , @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'nonnan'}));
            Parser.addParameter('Max', 1 ...
                , @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'nonnan'}));
            Parser.addParameter('IsRounded', false...
                , @(x)validateattributes(x, {'logical', 'numeric'}, {'scalar'}));
            Parser.addParameter('ValueChangedFunction', @(newValue)[]);
            Parser.parse(varargin{:});
            obj.initFromKeywordResults(Parser.Results);
        end

        %% Dependents
        function set.Min(obj, value)
            obj.Slider.min = value;
        end

        function value = get.Min(obj)
            value = obj.Slider.min;
        end

        function set.Max(obj, value)
            obj.Slider.max = value;
        end

        function value = get.Max(obj)
            value = obj.Slider.max;
        end

        function set.Value(obj, value)
            if obj.IsRounded
                value = round(value);
            end
            if ~obj.Slider.isBeingDragged
                obj.Slider.value = value;
            end
            obj.Edit.String = num2str(value);
        end

        function value = get.Value(obj)
            value = obj.Slider.value;
        end
    end

    methods (Access = private)
        initFromKeywordResults(obj, KeywordResults);

        function rectifyValue(obj)
            % usually called when min, max, or isrounded is changed and corrects value to match. This
            % function does not notify if the value is changed.
            value = obj.Slider.value;
            if obj.IsRounded
                obj.Slider.min = ceil(obj.Slider.min);
                obj.Slider.max = floor(obj.Slider.max);
                value = round(value);
            end
            obj.Slider.value = value; % min/max occurs in the slider setter.
        end

        function updateEditAndNotify(obj, value)
            if obj.IsRounded
                obj.Slider.value = round(value);
                value = obj.Slider.value;
            end
            obj.Edit.String = num2str(value);
            obj.ValueChangedFunction(value);
        end

        function updateSliderAndNotify(obj, str)
            numericValue = str2double(str);
            if isnan(numericValue)
                obj.Edit.String = num2str(obj.Slider.value);
            else
                if obj.IsRounded
                    numericValue = round(numericValue);
                    obj.Edit.String = num2str(numericValue);
                end
                obj.Slider.value = numericValue;
                obj.ValueChangedFunction(numericValue);
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

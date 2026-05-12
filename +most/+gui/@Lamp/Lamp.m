classdef Lamp < handle
    %LAMP uilamp but for the poors (GUIDE figure)
    % this class uses Axes and thus, cannot be nested in other axes.

    properties (Dependent, Transient)
        Color; % either a [r,g,b] value or a valid patch color
        Position(1,4) double; % always in points.
        WidthLimits; % optional property if Lamp is a child of an uiflowcontainer.
        HeightLimits; % optional property if Lamp is a child of an uiflowcontainer.
        Layout; % optional property if Lamp is a child of an uigridlayout.
    end

    properties (Access = private)
        Axes matlab.graphics.axis.Axes;
        Rectangle matlab.graphics.primitive.Rectangle;
        LifetimeListener(:,1) event.listener;
    end

    methods
        function obj = Lamp(varargin)
            Parser = inputParser;
            Parser.addParameter('Parent', []);
            Parser.addParameter('Color', 'k');
            Parser.addParameter('Position', []);
            Parser.parse(varargin{:});
            obj.initGui(Parser.Results);
        end

        %% Dependents
        function set.Color(obj, c)
            if ischar(c) || isstring(c)
                rgb = colorName2Rgb(c);
            else
                validateattributes(c, {'numeric'}, {'vector', 'numel', 3, 'finite', 'nonnan'});
                assert(all(c >= 0 & c <= 1));
                rgb = c;
            end
            obj.Rectangle.FaceColor = rgb;
        end

        function color = get.Color(obj)
            color = obj.Rectangle.FaceColor;
        end

        function set.Position(obj, position)
            if "points" ~= string(obj.Axes.Units)
                obj.Axes.Units = 'points';
            end
            obj.Axes.Position = position;
        end

        function position = get.Position(obj)
            position = obj.Axes.Position;
        end

        function set.WidthLimits(obj, limits)
            obj.Axes.WidthLimits = limits;
        end

        function limits = get.WidthLimits(obj)
            if isprop(obj.Axes, 'WidthLimits')
                limits = obj.Axes.WidthLimits;
            else
                limits = [];
            end
        end

        function set.HeightLimits(obj, limits)
            obj.Axes.HeightLimits = limits;
        end

        function limits = get.HeightLimits(obj)
            if isprop(obj.Axes, 'HeightLimits')
                limits = obj.Axes.HeightLimits;
            else
                limits = [];
            end
        end

        function set.Layout(obj, LayoutStruct)
            obj.Axes.Layout = LayoutStruct;
        end

        function LayoutStruct = get.Layout(obj)
            if isprop(obj.Axes, 'Layout')
                LayoutStruct = obj.Axes.Layout;
            else
                LayoutStruct = struct();
            end
        end
    end

    methods (Access = private)
        initGui(obj, KeywordResults);
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

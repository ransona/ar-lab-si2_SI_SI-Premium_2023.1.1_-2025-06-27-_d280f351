classdef HasWidget < handle
    properties (Abstract, SetAccess=protected)
        WidgetClass
    end

    properties
        widgetVisibility = true;
        minimizeOnStart = false;
    end
    
    methods
        function showWidget(obj)
            try
                assert(~isempty(obj.WidgetClass),'WidgetClass cannot be empty');
                assert(logical(exist(obj.WidgetClass,'class')),'WidgetClass ''%s'' does not exist',obj.WidgetClass);
                assert(most.idioms.isa(obj.WidgetClass,'dabs.resources.widget.Widget'),...
                    '''%s'' is not a valid ''%s''',obj.WidgetClass);
                
                obj.makeWidget();
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end
        end
        
        function hWidget = makeWidget(obj,hParent)
            if nargin < 2 || isempty(hParent)
                hParent = [];
            end
            
            hideWidget = isa(obj,'most.HasMachineDataFile') && isfield(obj.mdfData,'widgetVisibility') && ~obj.mdfData.widgetVisibility;
            if isempty(obj.WidgetClass) || hideWidget
                hWidget = [];
                return
            end
            
            if isa(obj.WidgetClass,'meta.class') || isa(obj.WidgetClass,'matlab.metadata.Class')
                constructor = str2func(obj.WidgetClass.Name);
            else
                constructor = str2func(obj.WidgetClass);
            end
            
            hWidget = constructor(obj,hParent);

            minimize = isa(obj,'most.HasMachineDataFile') && isfield(obj.mdfData,'minimizeOnStart') && obj.mdfData.minimizeOnStart;
            if minimize
                hWidget.toggleMinimize(false);
            end
        end
        
        function val = findWidgets(obj)
            if dabs.resources.widget.WidgetBar.isInstantiated()
                hWb = dabs.resources.widget.WidgetBar();
                hWidgets = hWb.hWidgets;
                mask = cellfun(@(hW)hW.hResource==obj,hWidgets);
                val = hWidgets(mask);
            else
                val = {};
            end
        end
        
        function highlightWidgets(obj)
            hWidgets = obj.findWidgets();
            for idx = 1:numel(hWidgets)
                hWidgets{idx}.highlight();
            end
        end
    end

    methods
        function set.widgetVisibility(obj,val)
            obj.widgetVisibility = val;

            if isa(obj,'most.HasMachineDataFile')
                obj.updateMdfVar('widgetVisibility', obj.widgetVisibility);
            end

            if dabs.resources.widget.WidgetBar.isInstantiated()
                hWb = dabs.resources.widget.WidgetBar();
                hWb.redraw();
            end
        end

        function set.minimizeOnStart(obj,val)
            obj.minimizeOnStart = val;

            if isa(obj,'most.HasMachineDataFile')
                obj.updateMdfVar('minimizeOnStart', obj.minimizeOnStart);
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

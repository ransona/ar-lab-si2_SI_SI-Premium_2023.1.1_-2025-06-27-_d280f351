classdef NoSelectionPage < dabs.resources.configuration.ResourcePage
    methods
        function obj = NoSelectionPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end

        function makeLayout(obj)
            % overload parent function
            obj.makePanel(obj.hParent);
        end
        
        function makePanel(obj,hParent)
            hFlow = most.gui.uiflowcontainer('Parent',hParent,'FlowDirection','TopDown','margin',1);
            hFlowTop    = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','margin',1);
            hFlowMiddle = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','margin',1,'HeightLimits',[20 20]);
            hFlowBottom = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','margin',1);
            
            uicontrol('Parent',hFlowMiddle,'Style','text','String','No resource selected.','HorizontalAlignment','center','FontWeight','bold');
        end
        
        function redraw(obj)
        end
        
        function apply(obj)
        end
        
        function remove(obj)
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

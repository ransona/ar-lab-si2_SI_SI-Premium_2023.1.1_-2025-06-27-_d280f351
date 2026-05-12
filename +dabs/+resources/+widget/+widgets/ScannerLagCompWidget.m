classdef ScannerLagCompWidget < dabs.resources.widget.Widget
    properties
        hEditFieldFlow
        hListeners = event.listener.empty(0,1);
        etXActuatorLag_ms = matlab.ui.control.UIControl.empty();
        etYActuatorLag_ms = matlab.ui.control.UIControl.empty();
    end
    
    methods
        function obj = ScannerLagCompWidget(hResource,hParent)
            obj@dabs.resources.widget.Widget(hResource,hParent);
            
            try
                obj.redraw();

                obj.hListeners(end+1) = addlistener(obj.hResource,'xActuatorLag_ms','PostSet',@(varargin)obj.redraw());
                obj.hListeners(end+1) = addlistener(obj.hResource,'yActuatorLag_ms','PostSet',@(varargin)obj.redraw());
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end
        end
        
        function delete(obj)
            obj.hListeners.delete();
        end
       
       function makePanel(obj,hParent)
           obj.hEditFieldFlow = most.gui.uiflowcontainer('Parent',hParent,'FlowDirection','TopDown','margin',2);
       
           most.gui.uicontrol('Parent',obj.hEditFieldFlow,'Style','text','Tag','txXActuatorLag_ms','String','X Actuator Lag [ms]','HorizontalAlignment','right');
           obj.etXActuatorLag_ms = most.gui.uicontrol('Parent',obj.hEditFieldFlow,'Style','edit','Tag','etXActuatorLag_ms','callback',@(src,evt)obj.setActuatorLag('x'));

           most.gui.uicontrol('Parent',obj.hEditFieldFlow,'Style','text','Tag','txYActuatorLag_ms','String','Y Actuator Lag [ms]','HorizontalAlignment','right');
           obj.etYActuatorLag_ms = most.gui.uicontrol('Parent',obj.hEditFieldFlow,'Style','edit','Tag','etYActuatorLag_ms','callback',@(src,evt)obj.setActuatorLag('y'));
       end
       
       function redraw(obj)          
           obj.etXActuatorLag_ms.String = num2str(obj.hResource.xActuatorLag_ms);
           obj.etYActuatorLag_ms.String = num2str(obj.hResource.yActuatorLag_ms);
       end
       
       function setActuatorLag(obj,dir)
           try
               switch dir
                   case 'x'
                       obj.hResource.setNewActuatorLag(str2double(obj.etXActuatorLag_ms.String),dir);
                   case 'y'
                       obj.hResource.setNewActuatorLag(str2double(obj.etYActuatorLag_ms.String),dir);
                   otherwise
               end
           catch ME
               most.ErrorHandler.logAndReportError(ME);
           end
       end
   end
end



% ----------------------------------------------------------------------------
% Copyright (C) 2023 MBF Bioscience
% 
% ScanImage (R) 2023 is software to be used under the purchased terms
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
% ----------------------------------------------------------------------------

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

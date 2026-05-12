classdef ThorBCMPage < dabs.resources.configuration.ResourcePage
    properties
       hListeners = event.listener.empty(0,1); 
    end
    
    properties(SetObservable)
        pmControlType;
        pmhPort;
        txhPort;
        etLabelPosition0;
        etLabelPosition1;
        pmStartupPosition
    end
    
    methods
        function obj = ThorBCMPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [-23 55 120 20],'Tag','txControlType','String','Control Type','HorizontalAlignment','right');
            obj.pmControlType = most.gui.uicontrol('Parent',hParent,'Style','popupmenu','String',{'Serial' 'TTL'},'RelPosition', [120 52 120 20],'Tag','pmControlType','callback',@obj.redrawPorts);
            
            obj.txhPort = most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [-23 85 120 20],'Tag','txhPort','String','Serial Port','HorizontalAlignment','right');
            obj.pmhPort  = most.gui.uicontrol('Parent',hParent,'Style','popupmenu','String',{''},'RelPosition', [120 82 120 20],'Tag','pmhPort');
            
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [-20 115 120 20],'Tag','txLabelPosition0','String','Position 0 Label ','HorizontalAlignment','right');
            obj.etLabelPosition0 = most.gui.uicontrol('Parent',hParent,'Style','edit','RelPosition', [120 112 120 20],'Tag','etLabelPosition0');  
            
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [-20 146 120 20],'Tag','txLabelPosition1','String','Position 1 Label','HorizontalAlignment','right');
            obj.etLabelPosition1 = most.gui.uicontrol('Parent',hParent,'Style','edit','RelPosition', [120 142 120 20],'Tag','etLabelPosition1');    
            
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [-12 176 120 20],'Tag','txStartupPosition','String','Startup Position: ','HorizontalAlignment','right');
            obj.pmStartupPosition = most.gui.uicontrol('Parent',hParent,'Style','popupmenu','String',{'Position 0', 'Position 1'},'RelPosition', [120 172 120 20],'Tag','pmStartupPosition');
        end
        
        function redraw(obj)
            obj.redrawPorts();
            
            obj.pmStartupPosition.Value = (obj.hResource.startupPosition + 1);            
            obj.etLabelPosition0.String = obj.hResource.labelPosition0;
            obj.etLabelPosition1.String = obj.hResource.labelPosition1;
        end

        function redrawPorts(obj, varargin)            
            switch obj.pmControlType.pmValue
                case 'Serial'
                    obj.txhPort.String = 'Serial port:';
                    hCOMs = obj.hResourceStore.filterByClass(?dabs.resources.SerialPort);
                    obj.pmhPort.String = [{''}, hCOMs];
                    obj.pmhPort.pmValue = obj.hResource.hCOM;
                case 'TTL'
                    obj.txhPort.String = 'TTL port:';
                    hDOs = obj.hResourceStore.filterByClass({?dabs.resources.ios.DO, ?dabs.resources.ios.PFI});
                    obj.pmhPort.String = [{''}, hDOs];
                    if most.idioms.isValidObj(obj.hResource.hDOControl) && isprop(obj.hResource.hDOControl,'name')
                        obj.pmhPort.pmValue = obj.hResource.hDOControl.name;
                    else
                        obj.pmhPort.pmValue = '';
                    end
                otherwise
                    %No-op
            end
        end
        
        function apply(obj)
            most.idioms.safeSetProp(obj.hResource,'controlType',obj.pmControlType.pmValue);

            switch obj.pmControlType.pmValue
                case 'Serial'
                    most.idioms.safeSetProp(obj.hResource,'hDOControl','');
                    most.idioms.safeSetProp(obj.hResource,'hCOM',obj.pmhPort.pmValue);
                case 'TTL'
                    most.idioms.safeSetProp(obj.hResource,'hCOM','');
                    most.idioms.safeSetProp(obj.hResource,'hDOControl',obj.pmhPort.pmValue);
                otherwise
                    %No-op
            end

            most.idioms.safeSetProp(obj.hResource, 'startupPosition', logical(obj.pmStartupPosition.Value - 1));
            most.idioms.safeSetProp(obj.hResource, 'labelPosition0', obj.etLabelPosition0.String);
            most.idioms.safeSetProp(obj.hResource, 'labelPosition1', obj.etLabelPosition1.String);

            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end
        
        function remove(obj)
            obj.hResource.deleteAndRemoveMdfHeading();
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

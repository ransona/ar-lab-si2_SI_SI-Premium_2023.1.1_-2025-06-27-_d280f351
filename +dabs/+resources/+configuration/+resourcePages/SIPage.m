classdef SIPage < dabs.resources.configuration.ResourcePage
    properties
        etObjectiveResolution
        etstartUpScript
        etshutDownScript
        cbUseJsonHeaderFormat
    end
    
    methods
        function obj = SIPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [50 82 130 20],'Tag','txObjectiveResolution','String',['Objective Resolution [um/' most.constants.Unicode.degree_sign ']'],'HorizontalAlignment','right');
            obj.etObjectiveResolution = most.gui.uicontrol('Parent',hParent,'Style','edit','String','','RelPosition', [190 82 120 20],'Tag','etObjectiveResolution');
            
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [60 112 120 20],'Tag','txstartUpScript','String','startUp Script (optional)','HorizontalAlignment','right');
            obj.etstartUpScript = most.gui.uicontrol('Parent',hParent,'Style','edit','String','','RelPosition', [190 112 120 20],'Tag','etstartUpScript');
            
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [40 142 140 20],'Tag','txshutDownScript','String','shutDown Script (optional)','HorizontalAlignment','right');
            obj.etshutDownScript = most.gui.uicontrol('Parent',hParent,'Style','edit','String','','RelPosition', [190 142 120 20],'Tag','etshutDownScript');
            
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [50 172 130 20],'Tag','txUseJsonHeaderFormat','String','Use JSON header format','HorizontalAlignment','right');
            obj.cbUseJsonHeaderFormat = most.gui.uicontrol('Parent',hParent,'Style','checkbox','String','','RelPosition', [190 172 20 20],'Tag','cbUseJsonHeaderFormat');
        end
        
        function redraw(obj)            
            obj.etObjectiveResolution.String = num2str(obj.hResource.objectiveResolution);
            obj.etstartUpScript.String = obj.hResource.startUpScript;
            obj.etshutDownScript.String = obj.hResource.shutDownScript;
            obj.cbUseJsonHeaderFormat.Value = obj.hResource.useJsonHeaderFormat;
        end
        
        function apply(obj)
            most.idioms.safeSetProp(obj.hResource,'objectiveResolution',str2double(obj.etObjectiveResolution.String));
            most.idioms.safeSetProp(obj.hResource,'startUpScript',obj.etstartUpScript.String);
            most.idioms.safeSetProp(obj.hResource,'shutDownScript',obj.etshutDownScript.String);
            most.idioms.safeSetProp(obj.hResource,'useJsonHeaderFormat',obj.cbUseJsonHeaderFormat.Value);
            
            obj.hResource.saveMdf();
            obj.hResource.validateConfiguration();
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

classdef ThorMCM5000Mirrors < dabs.resources.configuration.ResourcePage
    properties
        cbGalvoGalvoMirrorInvert
        cbGalvoResonantMirrorInvert
        cbFlipperMirrorInvert
    end
    
    methods
        function obj = ThorMCM5000Mirrors(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [10 55 150 20],'Tag','txGalvoGalvoMirrorInvert','String','Galvo-Galvo mirror invert','HorizontalAlignment','right');
            obj.cbGalvoGalvoMirrorInvert  = most.gui.uicontrol('Parent',hParent,'Style','checkbox','String',{''},'RelPosition', [170 32 20 20],'Tag','cbGalvoGalvoMirrorInvert');
            
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [10 35 150 20],'Tag','txGalvoResonantMirrorInvert','String','Galvo-Resonant mirror invert','HorizontalAlignment','right');
            obj.cbGalvoResonantMirrorInvert  = most.gui.uicontrol('Parent',hParent,'Style','checkbox','String',{''},'RelPosition', [170 52 20 20],'Tag','cbGalvoResonantMirrorInvert');
            
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [10 75 150 20],'Tag','txFlipperMirrorInvert','String','PMT/Camera mirror invert','HorizontalAlignment','right');
            obj.cbFlipperMirrorInvert  = most.gui.uicontrol('Parent',hParent,'Style','checkbox','String',{''},'RelPosition', [170 72 20 20],'Tag','cbFlipperMirrorInvert');
        end
        
        function redraw(obj)            
            obj.cbGalvoGalvoMirrorInvert.Value    = obj.hResource.galvoGalvoMirrorInvert;
            obj.cbGalvoResonantMirrorInvert.Value = obj.hResource.galvoResonantMirrorInvert;
            obj.cbFlipperMirrorInvert.Value       = obj.hResource.flipperMirrorInvert;
        end
        
        function apply(obj)
            most.idioms.safeSetProp(obj.hResource,'galvoGalvoMirrorInvert',    obj.cbGalvoGalvoMirrorInvert.Value);
            most.idioms.safeSetProp(obj.hResource,'galvoResonantMirrorInvert', obj.cbGalvoResonantMirrorInvert.Value);
            most.idioms.safeSetProp(obj.hResource,'flipperMirrorInvert',       obj.cbFlipperMirrorInvert.Value);
            
            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end
        
        function remove(obj)
            warndlg('Remove the MCM5000 motor to remove this resource.','Info');
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

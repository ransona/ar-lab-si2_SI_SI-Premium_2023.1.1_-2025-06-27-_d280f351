classdef ConexCCPage < dabs.resources.configuration.ResourcePage
    properties
        pmhCOM
        etControllerAddress

        etBaudRate
        pmDataBits
        pmStopBits
        etTerminator
        pmFlowControl
        pmParity

        % TODO: should more stage configuration options be exposed here?
        % - e.g. travel range, jerk, etc?
        % - they can be exposed or set in whatever object uses the stage,
        %   e.g. a half wave plate
    end

    methods
        function obj = ConexCCPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end

        function makePanel(obj,hParent)
            hTabGroup = uitabgroup('Parent',hParent);
            hTab = uitab('Parent',hTabGroup,'Title','Basic');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [80 65 100 20],'Tag','txhCOM','String','COM Port','HorizontalAlignment','right');
                obj.pmhCOM = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'Tag','pmhCOM','RelPosition', [190 60 80 20]);

                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [80 102 100 20],'Tag','txControllerAddress','String','Controller Address','HorizontalAlignment','right');
                obj.etControllerAddress = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'Tag','etControllerAddress','RelPosition', [190 99 80 20]);

            hTab = uitab('Parent',hTabGroup,'Title','COM Port');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [50 52 120 20],'Tag','txBaudRate','String','Baud Rate (bits/s)','HorizontalAlignment','right');
                obj.etBaudRate = most.gui.uicontrol('Parent',hTab,'Style','edit','String','','Tag','etBaudRate','RelPosition', [190 50 80 20]);
                
                options = {'5','6','7','8'};
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [50 82 120 20],'Tag','txDataBits','String','Data Bits','HorizontalAlignment','right');
                obj.pmDataBits = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',options,'Tag','pmDataBits','RelPosition', [190 78 80 20]);
                
                options = {'1','1.5','2'};
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [50 111 120 20],'Tag','txStopBits','String','Stop Bits','HorizontalAlignment','right');
                obj.pmStopBits = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',options,'Tag','pmStopBits','RelPosition', [190 107 80 20]);
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [50 140 120 20],'Tag','txTerminator','String','Command Terminator','HorizontalAlignment','right');
                obj.etTerminator = most.gui.uicontrol('Parent',hTab,'Style','edit','String','','Tag','etTerminator','RelPosition', [190 137 80 20]);
                
                options = {'none','hardware','software'};
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [50 170 120 20],'Tag','txFlowControl','String','Flow Control','HorizontalAlignment','right');
                obj.pmFlowControl = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',options,'Tag','pmFlowControl','RelPosition', [190 166 80 20]);
                
                options = {'none','even','odd'};
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [50 199 120 20],'Tag','txParity','String','Parity','HorizontalAlignment','right');
                obj.pmParity = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',options,'Tag','pmParity','RelPosition', [190 196 80 20]);
        end

        function redraw(obj)
            hCOMs = obj.hResourceStore.filterByClass(?dabs.resources.SerialPort);
            obj.pmhCOM.String = [{''},hCOMs];
            obj.pmhCOM.pmValue = obj.hResource.hCOM;

            obj.etControllerAddress.String = num2str(obj.hResource.controllerAddress);

            obj.etBaudRate.String = num2str(obj.hResource.baudRate);
            obj.pmDataBits.pmValue = num2str(obj.hResource.dataBits);
            obj.pmStopBits.pmValue = num2str(obj.hResource.stopBits);
            obj.pmFlowControl.pmValue = obj.hResource.flowControl;
            obj.pmParity.pmValue = obj.hResource.parity;

            if isnumeric(obj.hResource.terminator)
                terminator = num2str(obj.hResource.terminator);
            else
                terminator = obj.hResource.terminator;
            end
            obj.etTerminator.String = terminator;
        end

        function apply(obj)
            most.idioms.safeSetProp(obj.hResource,'hCOM',obj.pmhCOM.pmValue);
            most.idioms.safeSetProp(obj.hResource,'controllerAddress',str2double(obj.etControllerAddress.String));

            most.idioms.safeSetProp(obj.hResource,'baudRate',str2double(obj.etBaudRate.String));
            most.idioms.safeSetProp(obj.hResource,'dataBits',str2double(obj.pmDataBits.pmValue));
            most.idioms.safeSetProp(obj.hResource,'stopBits',str2double(obj.pmStopBits.pmValue));
            most.idioms.safeSetProp(obj.hResource,'flowControl',obj.pmFlowControl.pmValue);
            most.idioms.safeSetProp(obj.hResource,'parity',obj.pmParity.pmValue);

            if ~isnan(str2double(obj.etTerminator.String))
                terminator = str2double(obj.etTerminator.String);
            else
                terminator = obj.etTerminator.String;
            end
            most.idioms.safeSetProp(obj.hResource,'terminator',terminator);

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

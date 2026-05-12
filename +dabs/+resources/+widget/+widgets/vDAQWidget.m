classdef vDAQWidget < dabs.resources.widget.Widget
    properties
        hAx
        hSurf
        hText
        hAxText
        hListeners = event.listener.empty(0,1);
    end
    
    methods
        function obj = vDAQWidget(hResource,hParent)
            obj@dabs.resources.widget.Widget(hResource,hParent);
            validateattributes(hResource,{'dabs.resources.daqs.vDAQ'},{'scalar'});
        end
        
        function delete(obj)
            delete(obj.hListeners);
            most.idioms.safeDeleteObj(obj.hAx);
        end
    end
    
    methods
        function makePanel(obj,hParent)
            hFlow = most.gui.uiflowcontainer('Parent',hParent,'FlowDirection','TopDown','margin',0.001);
                hAxFlow = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','margin',0.001);
                    obj.hAx = most.idioms.axes('Parent',hAxFlow,'Units','normalized','Position',[0.1 0.1 0.8 0.8],'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'Visible','off','XLimSpec','tight','YLimSpec','tight');
                hTextFlow = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','HeightLimits',[15 15],'margin',0.001);
                    obj.hText = most.gui.uicontrol('Parent',hTextFlow,'Style','text','String','');  
                hButtonFlow = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','HeightLimits',[20 20],'margin',0.001);
                    most.gui.uicontrol('Parent',hButtonFlow,'String','Testpanel','Callback',@(varargin)obj.showTestpanel);
                    most.gui.uicontrol('Parent',hButtonFlow,'String','Breakout','Callback',@(varargin)obj.showBreakout);
            
            view(obj.hAx,0,-90);
            
            obj.makeBackground();
            
            hResourceStore = obj.hResource.hResourceStore;
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(hResourceStore.hSystemTimer,'beacon_0_2Hz',@(varargin)obj.redraw);
            obj.redraw();
        end
        
        function makeBackground(obj)
            fileName = 'vDAQ symbol FPGA.png';
            %fileName = 'vDAQ symbol text.png';
            
            folder = fileparts(mfilename('fullpath'));
            file = fullfile(folder,'+private',fileName);
            [im,~,transparency] = imread(file);
            
            color = most.constants.Colors.darkGray;
            
            [xx,yy,zz] = meshgrid([0 size(im,2)],[0 size(im,1)],0);
            obj.hSurf = surface('Parent',obj.hAx,'XData',xx,'YData',yy,'ZData',zz,'FaceColor','texturemap','CData',shiftdim(color,-1),'FaceAlpha','texturemap','AlphaData',transparency,'LineStyle','none','ButtonDownFcn',@(varargin)obj.showBreakout);
            
            obj.hAxText = text('Parent',obj.hAx,'Position',[size(im,2)*0.8,size(im,1)*0.4],'HorizontalAlignment','center','String','abc','FontSize',10,'FontWeight','bold','Color',most.constants.Colors.lightGray,'Hittest','off','PickableParts','none');
        end
        
        function redraw(obj)
            temperature_C = obj.hResource.hDevice.hSysmon.temperature;
            alarms = obj.hResource.hDevice.hSysmon.alarms;
            warnings = obj.hResource.warnMsg;
            lostPcieLink = ~obj.hResource.hDevice.isPCIeLinkAlive();

            if lostPcieLink || (~isempty(alarms) && ~strcmpi(alarms,'none'))
                msg = 'alarms';
                backgroundColor = most.constants.Colors.red;
                surfColor = most.constants.Colors.lightRed;
                textColor = most.constants.Colors.white;
            elseif ~isempty(warnings)
                msg = warnings;
                backgroundColor = [1 1 0.3];
                surfColor = backgroundColor;
                textColor = most.constants.Colors.black;
            else
                msg = '';
                backgroundColor = most.constants.Colors.lightGray;
                surfColor = most.constants.Colors.darkGray;
                textColor = most.constants.Colors.black;
            end

            if obj.hResource.simulated
                obj.hText.String = 'SIMULATED vDAQ';
                obj.hAxText.String = 'SIM';
            elseif lostPcieLink
                obj.hText.String = 'CONNECTION LOST';
                obj.hAxText.String = most.constants.Unicode.warning;
            else
                if isempty(msg)
                    obj.hText.String = sprintf('S/N:%s R%d.%s',obj.hResource.serial,obj.hResource.hardwareRevision,obj.hResource.firmwareVersion);
                else
                    obj.hText.String = msg;
                end
                obj.hAxText.String = sprintf('%.0f%sC',temperature_C,most.constants.Unicode.degree_sign);
            end
            
            obj.hText.hCtl.ForegroundColor = textColor;
            obj.hText.hCtl.BackgroundColor = backgroundColor;
            obj.hSurf.CData = shiftdim(surfColor,-1);
        end
        
        function showBreakout(obj)
            obj.hResource.showBreakout();
        end
        
        function showTestpanel(obj)
            obj.hResource.showTestpanel();
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

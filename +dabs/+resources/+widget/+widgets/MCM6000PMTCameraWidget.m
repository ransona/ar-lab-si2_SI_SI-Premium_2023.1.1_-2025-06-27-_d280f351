classdef MCM6000PMTCameraWidget < dabs.resources.widget.Widget
    properties
        hAx
        hPatchShutter;        
        hListeners = event.listener.empty(0,1);
        hTxWarning;
        hWarningFlow;
        
        pbPosition1;
        pbPosition2;
    end
    
    methods
        function obj = MCM6000PMTCameraWidget(hResource,hParent)
            obj@dabs.resources.widget.Widget(hResource,hParent);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource.hMCM6000,'pmtCameraState','PostSet',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource,'errorMsg','PostSet',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource,'warnMsg','PostSet',@(varargin)obj.redrawWarning);
            
            try
                obj.redraw();
                obj.redrawWarning();
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end
        end
        
        function delete(obj)
            obj.hListeners.delete();
            most.idioms.safeDeleteObj(obj.hAx);
        end
    end
    
    methods
        function makePanel(obj,hParent)            
            hFlow = most.gui.uiflowcontainer('Parent',hParent,'FlowDirection','TopDown','Margin',1e-3);
                hButtonFlow = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','Margin',1e-3, 'HeightLimits', [20 20]);
                    
                hButton = uicontrol('Parent',hButtonFlow);
                set(hButton,'HeightLimits',[20 20]);
                hButton.Callback = @(varargin)obj.gotoPosition1;
                hButton.String = 'PMT';
                obj.pbPosition1 = hButton;
                    
                hButtonFlow = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','Margin',1e-3, 'HeightLimits', [20 20]);

                hButton = uicontrol('Parent',hButtonFlow);
                set(hButton,'HeightLimits',[20 20]);
                hButton.Callback = @(varargin)obj.gotoPosition2;
                hButton.String = 'Camera';
                obj.pbPosition2 = hButton;
                    
                obj.hWarningFlow = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','Margin',1e-3,'HeightLimits',[20 20]);
                    obj.hTxWarning = uicontrol('Parent',obj.hWarningFlow,'Style','text');
                    most.gui.setComponentsBackgroundColor(obj.hTxWarning,'yellow');
                    obj.hTxWarning.FontWeight = 'Bold';
                    obj.hTxWarning.String = [ getWarningSign() ' Warning ' getWarningSign()];
                    obj.hTxWarning.FontSize = 12;
                    obj.hTxWarning.Enable = 'inactive';
                    obj.hTxWarning.ButtonDownFcn = @(varargin)obj.showWarningMessage();
                    
            function warnsign = getWarningSign()
                if verLessThan('matlab','9.3') % warning sign is available in Matlab 2017b or later
                    warnsign = '!';
                else
                    warnsign = most.constants.Unicode.warning;
                end
            end
        end
        
        function redrawWarning(obj)
            if isempty(obj.hResource.warnMsg)
                obj.hWarningFlow.Visible = 'off';
            else
                obj.hWarningFlow.Visible = 'on';
            end
        end
        
        function showWarningMessage(obj)
            h = warndlg(obj.hResource.warnMsg);
            most.gui.centerOnScreen(h);
        end
        
        function redraw(obj)
            if ~isempty(obj.hResource.hMCM6000.errorMsg) || isempty(obj.hResource.hMCM6000.pmtCameraSelectorSlot)
                obj.changeColor("red",most.constants.Colors.white);
                most.gui.setComponentsBackgroundColor([obj.pbPosition1 obj.pbPosition2],'red');
            end
            
            obj.pbPosition1.Enable = 'on';
            obj.pbPosition2.Enable = 'on';

            state = obj.hResource.hMCM6000.pmtCameraState;
            if isempty(state)
                state = nan;
            end

            switch state
                case 0
                    most.gui.setComponentsBackgroundColor(obj.pbPosition2,'background');
                    most.gui.setComponentsBackgroundColor(obj.pbPosition1, 'green');
                case 1
                    most.gui.setComponentsBackgroundColor(obj.pbPosition1,'background');
                    most.gui.setComponentsBackgroundColor(obj.pbPosition2, 'green');
                otherwise
                    most.gui.setComponentsBackgroundColor([obj.pbPosition1, obj.pbPosition2],'blue');
            end
        end
        
        function gotoPosition1(obj,varargin)
            if ~isempty(obj.hResource.hMCM6000.pmtCameraSelectorSlot)
                obj.hResource.hMCM6000.setMotorizedIndexedActuatorPosition(obj.hResource.hMCM6000.pmtCameraSelectorSlot,0);
            end
        end
        
        function gotoPosition2(obj,varargin)
            if ~isempty(obj.hResource.hMCM6000.pmtCameraSelectorSlot)
                obj.hResource.hMCM6000.setMotorizedIndexedActuatorPosition(obj.hResource.hMCM6000.pmtCameraSelectorSlot,1);
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

classdef MCM6000FilterWheelWidget < dabs.resources.widget.Widget
    properties
        hAx
        hPatchShutter;        
        hListeners = event.listener.empty(0,1);
        hTxWarning;
        hWarningFlow;
        
        pbPosition1;
        pbPosition2;
        pbPosition3;
        pbPosition4;
        pbPosition5;
        pbPosition6;
    end
    
    methods
        function obj = MCM6000FilterWheelWidget(hResource,hParent)
            obj@dabs.resources.widget.Widget(hResource,hParent);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource.hMCM6000,'filterWheelState','PostSet',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource.hMCM6000,'filterWheelNames','PostSet',@(varargin)obj.renameButtons);
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
                hButtonFlow = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','Margin',1e-3, 'HeightLimits', [18 18]);

                for idx = 1:6
                    hButton = uicontrol('Parent',hButtonFlow);
                    set(hButton,'HeightLimits',[20 20]);
                    hButton.Callback = @(varargin)obj.gotoPosition(idx-1);

                    if isempty(obj.hResource.hMCM6000.filterWheelNames{idx})
                        hButton.String = sprintf('Position %.0f',idx);
                    else
                        hButton.String = obj.hResource.hMCM6000.filterWheelNames{idx};
                    end

                    switch idx
                        case 1
                            obj.pbPosition1 = hButton;
                        case 2
                            obj.pbPosition2 = hButton;
                        case 3
                            obj.pbPosition3 = hButton;
                        case 4
                            obj.pbPosition4 = hButton;
                        case 5
                            obj.pbPosition5 = hButton;
                        case 6
                            obj.pbPosition6 = hButton;
                    end

                    hButtonFlow = most.gui.uiflowcontainer('Parent',hFlow,'FlowDirection','LeftToRight','Margin',1e-3, 'HeightLimits', [18 18]);
                end
                    
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
            if ~isempty(obj.hResource.hMCM6000.errorMsg) || isempty(obj.hResource.hMCM6000.filterWheelSlot)
                obj.changeColor("red",most.constants.Colors.white);
                buttons = [obj.pbPosition1 obj.pbPosition2 obj.pbPosition3 obj.pbPosition4 obj.pbPosition5 obj.pbPosition6];

                if isempty(buttons)
                    return;
                end

                most.gui.setComponentsBackgroundColor(buttons,'red');
            end
            
            obj.pbPosition1.Enable = 'on';
            obj.pbPosition2.Enable = 'on';
            obj.pbPosition3.Enable = 'on';
            obj.pbPosition4.Enable = 'on';
            obj.pbPosition5.Enable = 'on';
            obj.pbPosition6.Enable = 'on';

            switch obj.hResource.hMCM6000.filterWheelState
                case 0
                    most.gui.setComponentsBackgroundColor([obj.pbPosition2, obj.pbPosition3, obj.pbPosition4, obj.pbPosition5, obj.pbPosition6],'background');
                    most.gui.setComponentsBackgroundColor(obj.pbPosition1, 'green');
                case 1
                    most.gui.setComponentsBackgroundColor([obj.pbPosition1, obj.pbPosition3, obj.pbPosition4, obj.pbPosition5, obj.pbPosition6],'background');
                    most.gui.setComponentsBackgroundColor(obj.pbPosition2, 'green');
                case 2
                    most.gui.setComponentsBackgroundColor([obj.pbPosition1, obj.pbPosition2, obj.pbPosition4, obj.pbPosition5, obj.pbPosition6],'background');
                    most.gui.setComponentsBackgroundColor(obj.pbPosition3, 'green');
                case 3
                    most.gui.setComponentsBackgroundColor([obj.pbPosition1, obj.pbPosition2, obj.pbPosition3, obj.pbPosition5, obj.pbPosition6],'background');
                    most.gui.setComponentsBackgroundColor(obj.pbPosition4, 'green');
                case 4
                    most.gui.setComponentsBackgroundColor([obj.pbPosition1, obj.pbPosition2, obj.pbPosition3, obj.pbPosition4, obj.pbPosition6],'background');
                    most.gui.setComponentsBackgroundColor(obj.pbPosition5, 'green');
                case 5
                    most.gui.setComponentsBackgroundColor([obj.pbPosition1, obj.pbPosition2, obj.pbPosition3, obj.pbPosition4, obj.pbPosition5],'background');
                    most.gui.setComponentsBackgroundColor(obj.pbPosition6, 'green');
                otherwise
                    most.gui.setComponentsBackgroundColor([obj.pbPosition1, obj.pbPosition2, obj.pbPosition3, obj.pbPosition4, obj.pbPosition5, obj.pbPosition6],'blue');
            end
        end
        
        function renameButtons(obj)
            obj.pbPosition1.String = obj.hResource.hMCM6000.filterWheelNames{1};
            obj.pbPosition2.String = obj.hResource.hMCM6000.filterWheelNames{2};
            obj.pbPosition3.String = obj.hResource.hMCM6000.filterWheelNames{3};
            obj.pbPosition4.String = obj.hResource.hMCM6000.filterWheelNames{4};
            obj.pbPosition5.String = obj.hResource.hMCM6000.filterWheelNames{5};
            obj.pbPosition6.String = obj.hResource.hMCM6000.filterWheelNames{6};
        end
        
        function gotoPosition(obj,position)
            if ~isempty(obj.hResource.hMCM6000.filterWheelSlot)
                obj.hResource.hMCM6000.setMotorizedIndexedActuatorPosition(obj.hResource.hMCM6000.filterWheelSlot,position);
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

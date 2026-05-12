classdef TriggerScriptWidget < dabs.resources.widget.Widget
    properties(SetObservable)
        hFlButtonTop
        hFlButtonLeft
        hListeners = event.listener.empty(0,1);
        hCbEnable = most.gui.uicontrol.empty();
        pbSoftTrigger = most.gui.uicontrol.empty();
        etscriptruntime = most.gui.uicontrol.empty();
        txtmilliseconds = most.gui.uicontrol.empty();
    end

    methods
        function obj = TriggerScriptWidget(hResource,hParent)
            obj@dabs.resources.widget.Widget(hResource,hParent);
            
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource,'scripts','PostSet',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource,'hDITriggerport','PostSet',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource,'scriptruntime','PostSet',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource,'trigEnabled','PostSet',@(varargin)obj.redraw);

            function delete(obj)
                delete(obj.hListeners);
                obj.hListeners = event.listener.empty(0,1);
                most.idioms.safeDeleteObj(obj.hFlButtonLeft);
            end
        end

        function makePanel(obj,hParent)
            obj.hFlButtonTop = most.gui.uiflowcontainer('Parent', hParent, 'FlowDirection', 'TopDown', 'margin', 2);
            for i=1:5
                obj.hFlButtonLeft = most.gui.uiflowcontainer('Parent', obj.hFlButtonTop, 'FlowDirection', 'LeftToRight', 'margin', 1);
                obj.hCbEnable(i) = most.gui.uicontrol('Parent', obj.hFlButtonLeft,'Style', 'checkbox','WidthLimits',[15 15], 'Callback',@obj.hCbEnable_changed);
                obj.pbSoftTrigger(i) = most.gui.uicontrol('Parent', obj.hFlButtonLeft,'Style', 'Pushbutton','Enable','on', 'String', 'script', 'WidthLimits',[55 55], 'Callback', @obj.softwareTriggerScript);
                obj.etscriptruntime(i) = most.gui.uicontrol('Parent', obj.hFlButtonLeft,'Style', 'edit', 'WidthLimits',[41 41],'Enable','Inactive');
                obj.txtmilliseconds(i) = most.gui.uicontrol('Parent',obj.hFlButtonLeft,'Style','text','String','ms');
            end
            try
                obj.redraw()
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end
        end

        function redraw(obj)
            if ~most.idioms.isValidObj(obj)
                return;
            end

            for idx = 1:5
                script = obj.hResource.scripts{idx};
                tfEnableSoftTrigger = ~isempty(script);
                if tfEnableSoftTrigger
                    [~, scriptName, ~] = fileparts(script);
                else
                    scriptName = '';
                end

                obj.pbSoftTrigger(idx).String = scriptName;
                obj.pbSoftTrigger(idx).Enable = tfEnableSoftTrigger;
                scriptRunTime_ms = obj.hResource.scriptruntime(idx);

                if scriptRunTime_ms < 1
                    scriptRuntimeStr = sprintf('%.2f ms',scriptRunTime_ms);
                else
                    scriptRuntimeStr = sprintf('%.0f ms',scriptRunTime_ms);
                end

                if tfEnableSoftTrigger
                    obj.etscriptruntime(idx).Enable = 'Inactive';
                else
                    obj.etscriptruntime(idx).Enable = 'off';
                end
                set(obj.etscriptruntime(idx), 'String', scriptRuntimeStr);

                tfEnable = ~isempty(obj.hResource.hDITriggerport{idx});
                obj.hCbEnable(idx).Enable = most.gui.OnOff(tfEnable && tfEnableSoftTrigger);

                set(obj.hCbEnable(idx),'Value',logical(obj.hResource.trigEnabled(idx)))
            end
        end

        function hCbEnable_changed(obj,src,evt)
            cbMask = arrayfun(@(pb)pb.hCtl==src,obj.hCbEnable);
            obj.hResource.trigEnabled(cbMask) = obj.hCbEnable(cbMask).Value;
        end

        function softwareTriggerScript(obj,src,evt)
            pbMask = arrayfun(@(pb)pb.hCtl==src,obj.pbSoftTrigger);
            obj.hResource.softwareTriggerScript(pbMask);
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

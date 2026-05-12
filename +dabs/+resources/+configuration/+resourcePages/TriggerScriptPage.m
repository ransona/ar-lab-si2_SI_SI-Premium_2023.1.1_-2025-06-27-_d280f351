classdef TriggerScriptPage < dabs.resources.configuration.ResourcePage
    properties (SetObservable)
        etSelectedScript = most.gui.uicontrol.empty();
        pmDITriggerPort = most.gui.uicontrol.empty();
        pbSelectScript = most.gui.uicontrol.empty();
        cbTriggerEnable = most.gui.uicontrol.empty();
        pmDITriggerEdge = most.gui.uicontrol.empty();
        DITriggerPort = strings(5,1);
        hListeners = event.listener.empty(0,1);

        scriptFullFiles = cell(1,5);
    end

    methods
        function obj = TriggerScriptPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource, 'scripts','PostSet',@(varargin)obj.redraw);
        end

        function delete(obj)
            obj.hListeners.delete();
        end

        function makePanel(obj,hParent)
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [70 39 120 20],'Tag','txScript','String','Script to Trigger');
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [200 39 80 20],'Tag','txDITriggerPort','String','Terminal');
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [270 39 80 20],'Tag','txDITriggerEdge','String','Edge');
            most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [330 39 60 20],'Tag','txCbTriggerEnable','String','Enable');

            for i=1:5
                obj.etSelectedScript(i) = most.gui.uicontrol('Parent',hParent,'Style','edit', 'String','','RelPosition', [70 36+40*i 120 23],'Tag','etSelectedScript','Enable','Inactive');
                obj.pmDITriggerPort(i) = most.gui.uicontrol('Parent',hParent,'Style','popupmenu','String',{''},'RelPosition', [200 33+40*i 80 20],'Tag','pmDITriggerPort','callback',@obj.refreshTriggerEnable);
                obj.pbSelectScript(i) = most.gui.uicontrol('Parent', hParent,'Style', 'pushbutton', 'String', 'Browse','RelPosition', [10 37+40*i 50 25],'Tag','pbSelectScript','Callback',@obj.selectScript);
                obj.pmDITriggerEdge(i)  = most.gui.uicontrol('Parent',hParent,'Style','popupmenu','String',{'rising' 'falling'},'RelPosition', [290 33+40*i 50 20],'Tag','pmDITriggerEdge');
                obj.cbTriggerEnable(i)  = most.gui.uicontrol('Parent',hParent,'Style','checkbox','RelPosition', [350 33+40*i 80 20],'Tag','cbTriggerEnable');
            end

        end

        function redraw(obj)
            hDIs = obj.hResourceStore.filter(@(hR)isa(hR,'dabs.resources.ios.DI')||isa(hR,'dabs.resources.ios.PFI'));

            obj.scriptFullFiles = obj.hResource.scripts;

            for idx=1:5  
                [~, scriptName, ~] = fileparts(obj.scriptFullFiles{idx});
                obj.etSelectedScript(idx).String = scriptName;

                enableRow = ~isempty(scriptName);
                obj.pmDITriggerPort(idx).String = [{''}, hDIs];
                obj.pmDITriggerPort(idx).pmValue = obj.hResource.hDITriggerport{idx};
                obj.pmDITriggerPort(idx).Enable = most.gui.OnOff(enableRow);

                if enableRow
                    obj.cbTriggerEnable(idx).Value = obj.hResource.trigEnabled(idx);
                else
                    obj.cbTriggerEnable(idx).Value = false;
                end

                if obj.hResource.hDITriggeredge(idx)
                    obj.pmDITriggerEdge(idx).pmValue = 'rising';
                else
                    obj.pmDITriggerEdge(idx).pmValue = 'falling';
                end
            end

            obj.refreshTriggerEnable();
        end

        function refreshTriggerEnable(obj,varargin)
            for idx = 1:5
                scriptName = obj.etSelectedScript(idx).String;
                tfEnable = ~isempty(obj.pmDITriggerPort(idx).pmValue) && ~isempty(scriptName);
                obj.cbTriggerEnable(idx).Enable = most.gui.OnOff(tfEnable);

                if ~tfEnable
                    obj.cbTriggerEnable(idx).Value = false;
                end
            end
        end

        function selectScript(obj,src,evt)
            pbMask = arrayfun(@(pb)pb.hCtl==src,obj.pbSelectScript);
            [filename, path, ~]= uigetfile('*.m','Pick a MATLAB code file');
            fileLoc = fullfile(path,filename);

            fileSelected = isfile(fileLoc);
            if fileSelected
                obj.scriptFullFiles{pbMask} = fileLoc;
                set(obj.etSelectedScript(pbMask), 'String', char(filename))
            else
                obj.scriptFullFiles{pbMask} = '';
                obj.etSelectedScript(pbMask).String = ''; %Only means of clearing a script for the selected slot.
                obj.pmDITriggerPort(pbMask).pmValue = '';
            end
            obj.pmDITriggerPort(pbMask).Enable = most.gui.OnOff(fileSelected);

            obj.refreshTriggerEnable();
        end

        function apply(obj)
            TriggerEdge = false(1,5);
            trigEnabled = false(1,5);

            for idxs=1:5
                obj.DITriggerPort(idxs) = obj.pmDITriggerPort(idxs).pmValue;
                TriggerEdge(idxs) = ~logical(dabs.vidrio.ddi.types.DigitalEdge.(obj.pmDITriggerEdge(idxs).pmValue));
                trigEnabled(idxs) = obj.cbTriggerEnable(idxs).Value;
            end

            most.idioms.safeSetProp(obj.hResource,'scripts',obj.scriptFullFiles);
            most.idioms.safeSetProp(obj.hResource,'hDITriggerport', obj.DITriggerPort.cellstr);
            most.idioms.safeSetProp(obj.hResource,'hDITriggeredge',TriggerEdge);
            most.idioms.safeSetProp(obj.hResource,'trigEnabled',trigEnabled);

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

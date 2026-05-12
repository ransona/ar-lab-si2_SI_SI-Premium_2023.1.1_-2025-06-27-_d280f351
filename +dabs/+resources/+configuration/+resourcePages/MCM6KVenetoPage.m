classdef MCM6KVenetoPage < dabs.resources.configuration.ResourcePage
    properties
        pmhCOM
        pbQueryHWInfo
        txBaudRate
        pmBaudRate
        
        pmLightPathSlot
        pmFilterWheelSlot
        pmZSlot
        pmPiezoZSlot
        pmPMTCamSlot
        
        pmShutterSlot
        etShutterOpenTime

        etLightPathName1
        etLightPathName2
        etLightPathName3

        etFilterName1
        etFilterName2
        etFilterName3
        etFilterName4
        etFilterName5
        etFilterName6
        
        txInfo;
        
        hListeners = event.listener.empty(0,1);
    end
    
    properties (Dependent)
        isBaudRateSettable
    end
    
    methods
        function obj = MCM6KVenetoPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
            
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hResource,'hardwareInfo','PostSet',@(varargin)obj.redraw);
        end
        
        function makePanel(obj,hParent)
            hTabGroup = uitabgroup('Parent',hParent);
            
            hTab = uitab('Parent',hTabGroup,'Title','Basic');
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 30 120 20],'Tag','txhComPort','String','Serial Port','HorizontalAlignment','right');
            obj.pmhCOM  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 27 120 20],'Tag','pmhCOM','Callback',@obj.SetpbHWEnable);
            obj.pbQueryHWInfo = most.gui.uicontrol('Parent',hTab,'Style','pushbutton','String','Query Hardware Info','RelPosition', [216 185.333333333333 120 20],'Tag','pbHardwareInfo','Enable','off','Callback',@obj.queryHardwareInfo);
            obj.txBaudRate = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 55 120 20],'Tag','txhComPort','String','Baud rate','HorizontalAlignment','right');
            obj.pmBaudRate = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 52 120 20],'Tag','pmBaudRate');
            
            ttStr = sprintf('Slot Number of the MCM6000 to which the Light Path Selector is connected.\nIn most cases, Thorlabs controller buttons map such that L = Camera, C = RG Scanner, R = Trinocular');
            txLightPathSelector = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-1 57 70 30],'Tag','txLightPathSelector','String','Light Path Selector Slot','HorizontalAlignment','right');
            obj.pmLightPathSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [84 54 81 20],'Tag','pmLightPathSelector','tooltip',ttStr);
            
            ttStr = sprintf('Slot Number of the MCM6000 to which the Filter Wheel is connected.');
            txFilterWheel = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [8 91 56 26],'Tag','txFilterWheel','String','Filter Wheel Slot','HorizontalAlignment','right');
            obj.pmFilterWheelSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [84 90 81 20],'Tag','pmYSlot','tooltip',ttStr);
            
            ttStr = sprintf('Slot Number of the MCM6000 that the Z stage is connected to.');
            txSlotZ = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [199 58 80 20],'Tag','txSlotStageZ','String','Stage Z Slot','HorizontalAlignment','right');
            obj.pmZSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [293 53 81 20],'Tag','pmZStageSlot','tooltip',ttStr);

            ttStr = sprintf('Slot Number of the MCM6000 that the Z piezo is connected to.');
            txSlotPiezoZ = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [221 132 60 20],'Tag','txSlotPiezoZ','String','Piezo Z Slot','HorizontalAlignment','right');
            obj.pmPiezoZSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [293 127 81 20],'Tag','pmPiezoZSlot','tooltip',ttStr);
            
            ttStr = sprintf('Slot Number of the MCM6000 to which the PMT/Camera selector is connected.');
            txSlotPMTCam = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [181 91 101 25],'Tag','txSlotPMTCam','String','PMT/Camera Selection Slot','HorizontalAlignment','right');
            obj.pmPMTCamSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [293 89 81 20],'Tag','pmRSlot','tooltip',ttStr);
            
            obj.txInfo = most.gui.uicontrol('Parent',hTab,'Style','text','FontSize', 7, 'RelPosition', [4 296 167 200],'Tag','txInfo','String','','HorizontalAlignment','left');
            
            hTab = uitab('Parent',hTabGroup,'Title','Misc');
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 30 120 20],'Tag','txShutter','String','Shutter Slot','HorizontalAlignment','right');
            obj.pmShutterSlot  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 27 120 20],'Tag','pmShutter');
            
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 56 120 20],'Tag','txShutterOpenTime','String','Shutter Open Time [s]','HorizontalAlignment','right');
            obj.etShutterOpenTime = most.gui.uicontrol('Parent',hTab,'Style','edit','String','0.5','RelPosition', [150 53 120 20],'Tag','etShutterOpenTime');

            %Light Path Names
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-4 112 120 20],'Tag','txLPN','String','Light Path Names:','HorizontalAlignment','right');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-6 136 30 20],'Tag','txLPN1','String','1','HorizontalAlignment','right');
            obj.etLightPathName1 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [31 138 90 20],'Tag','etLightPathName1');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [127 137 10 20],'Tag','txLPN2','String','2','HorizontalAlignment','right');
            obj.etLightPathName2 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [144 138 90 20],'Tag','etLightPathName2');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [250 139 10 20],'Tag','txLPN3','String','3','HorizontalAlignment','right');
            obj.etLightPathName3 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [268 138 90 20],'Tag','etLightPathName3');

            %Filter Names
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-7 183 120 20],'Tag','txFilterNames','String','Filter Names:','HorizontalAlignment','right');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-5 209 30 20],'Tag','txFilterName1','String','1','HorizontalAlignment','right');
            obj.etFilterName1 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [31 205 90 20],'Tag','etFilterName1');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [129 203 10 20],'Tag','txFilterName2','String','2','HorizontalAlignment','right');
            obj.etFilterName2 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [144 205 90 20],'Tag','etFilterName2');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [250 207 10 20],'Tag','txFilterName3','String','3','HorizontalAlignment','right');
            obj.etFilterName3 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [268 205 90 20],'Tag','etFilterName3');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-5 238 30 20],'Tag','txFilterName4','String','4','HorizontalAlignment','right');
            obj.etFilterName4 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [31 236 90 20],'Tag','etFilterName4');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [129 240 10 20],'Tag','txFilterName5','String','5','HorizontalAlignment','right');
            obj.etFilterName5 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [143 236 90 20],'Tag','etFilterName5');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [250 238 10 20],'Tag','txFilterName6','String','6','HorizontalAlignment','right');
            obj.etFilterName6 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [267 233 90 20],'Tag','etFilterName6');
        end
        
        function redraw(obj)  
            if ~most.idioms.isValidObj(obj)
                return;
            end

            hCOMs = obj.hResourceStore.filterByClass(?dabs.resources.SerialPort);
            
            obj.pmhCOM.String = [{''}, hCOMs];
            obj.pmhCOM.pmValue = obj.hResource.hCOM;
            
            if ~isempty(obj.hResource.hCOM) && most.idioms.isValidObj(obj.hResource.hCOM)
                obj.pbQueryHWInfo.Enable = 'on';
            else
                obj.pbQueryHWInfo.Enable = 'off';
            end
            
            obj.txBaudRate.Visible = obj.isBaudRateSettable;
            obj.pmBaudRate.Visible = obj.isBaudRateSettable;
            
            if obj.isBaudRateSettable
                if isprop(obj.hResource,'availableBaudRates')
                    obj.pmBaudRate.String = arrayfun(@(v)num2str(v),obj.hResource.availableBaudRates,'UniformOutput',false);
                else
                    obj.pmBaudRate.String = {'75' '110' '150' '300' '600' '1200' '1800' '2400' '4800' '7200' '9600' '14400' '19200' '31250' '38400' '56000' '57600' '76800' '115200' '128000' '230400' '256000'};
                end
                obj.pmBaudRate.pmValue = num2str(obj.hResource.baudRate);
            end
            
            obj.pmShutterSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmShutterSlot.pmValue = num2str(obj.hResource.shutterSlot);

            obj.etShutterOpenTime.String = num2str(obj.hResource.shutterOpenTime_s);
            
            obj.pmLightPathSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmLightPathSlot.pmValue = num2str(obj.hResource.lightPathSelectorSlot);

            if numel(obj.hResource.filterWheelNames) > 0
                obj.etLightPathName1.String = obj.hResource.lightPathNames{1};
            end

            if numel(obj.hResource.filterWheelNames) > 1
                obj.etLightPathName2.String = obj.hResource.lightPathNames{2};
            end

            if numel(obj.hResource.filterWheelNames) > 2
                obj.etLightPathName3.String = obj.hResource.lightPathNames{3};
            end

            obj.pmFilterWheelSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmFilterWheelSlot.pmValue = num2str(obj.hResource.filterWheelSlot);

            if numel(obj.hResource.filterWheelNames) > 0
                obj.etFilterName1.String = obj.hResource.filterWheelNames{1};
            end

            if numel(obj.hResource.filterWheelNames) > 1
                obj.etFilterName2.String = obj.hResource.filterWheelNames{2};
            end

            if numel(obj.hResource.filterWheelNames) > 2
                obj.etFilterName3.String = obj.hResource.filterWheelNames{3};
            end

            if numel(obj.hResource.filterWheelNames) > 3
                obj.etFilterName4.String = obj.hResource.filterWheelNames{4};
            end

            if numel(obj.hResource.filterWheelNames) > 4
                obj.etFilterName5.String = obj.hResource.filterWheelNames{5};
            end

            if numel(obj.hResource.filterWheelNames) > 5
                obj.etFilterName6.String = obj.hResource.filterWheelNames{6};
            end

            
            obj.pmZSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmZSlot.pmValue = num2str(obj.hResource.zMotorSlot);

            obj.pmPiezoZSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmPiezoZSlot.pmValue = num2str(obj.hResource.zPiezoSlot);
            
            obj.pmPMTCamSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmPMTCamSlot.pmValue = num2str(obj.hResource.pmtCameraSelectorSlot);
            
            
            info = '';
            
            if ~isempty(obj.hResource.hardwareInfo)
                cellfo = cellfun(@(x,y) [x ' = ' y '\n'], fieldnames(obj.hResource.hardwareInfo), struct2cell(obj.hResource.hardwareInfo), 'UniformOutput', false);
                s = size(cellfo,1);

                for i=1:s
                    info = [info sprintf(cellfo{i})];
                end
                obj.txInfo.String = info;
                most.gui.setComponentsBackgroundColor(obj.txInfo.hCtl,'background');
            else
                obj.txInfo.String = '';
            end
        end
        
        function apply(obj)
            obj.hResource.deinit();
            most.idioms.safeSetProp(obj.hResource,'hCOM',obj.pmhCOM.pmValue);
            
            most.idioms.safeSetProp(obj.hResource,'zMotorSlot',str2num(obj.pmZSlot.pmValue));

            most.idioms.safeSetProp(obj.hResource,'zPiezoSlot',str2num(obj.pmPiezoZSlot.pmValue));            
            
            most.idioms.safeSetProp(obj.hResource,'shutterSlot',str2num(obj.pmShutterSlot.pmValue));
            most.idioms.safeSetProp(obj.hResource,'shutterOpenTime_s',str2double(obj.etShutterOpenTime.String));
            
            most.idioms.safeSetProp(obj.hResource,'shutterOpenTime_s',str2double(obj.etShutterOpenTime.String));
            most.idioms.safeSetProp(obj.hResource,'shutterOpenTime_s',str2double(obj.etShutterOpenTime.String));

            most.idioms.safeSetProp(obj.hResource,'lightPathSelectorSlot',str2num(obj.pmLightPathSlot.pmValue));
            strs = uncellifyStrings({obj.etLightPathName1.String obj.etLightPathName2.String obj.etLightPathName3.String});
            most.idioms.safeSetProp(obj.hResource,'lightPathNames',strs);

            most.idioms.safeSetProp(obj.hResource,'filterWheelSlot',str2num(obj.pmFilterWheelSlot.pmValue));
            strs = uncellifyStrings({obj.etFilterName1.String obj.etFilterName2.String obj.etFilterName3.String obj.etFilterName4.String obj.etFilterName5.String obj.etFilterName6.String});
            most.idioms.safeSetProp(obj.hResource,'filterWheelNames',strs);

            most.idioms.safeSetProp(obj.hResource,'pmtCameraSelectorSlot',str2num(obj.pmPMTCamSlot.pmValue));

            most.idioms.safeSetProp(obj.hResource,'shutterOpenTime_s',str2double(obj.etShutterOpenTime.String));
            most.idioms.safeSetProp(obj.hResource,'shutterOpenTime_s',str2double(obj.etShutterOpenTime.String));
            
            if obj.isBaudRateSettable
                obj.hResource.baudRate = str2double(obj.pmBaudRate.pmValue);
            end
            
            obj.hResource.saveMdf();
            obj.hResource.reinit();
            pause(0.2);
            obj.redraw();

            %%% Nested function
            function out = uncellifyStrings(strs)
                out = cell(1,numel(strs));
                for idx = 1:numel(strs)
                    str = strs{idx};
                    if iscell(str)
                        out(idx) = str;
                    else
                        out{idx} = str;
                    end
                end
            end
        end
        
        function remove(obj)
            most.idioms.safeDeleteObj(obj.hListeners);
            obj.hListeners = [];
            
            obj.hResource.deleteAndRemoveMdfHeading();
        end
    end
    
    methods
        function SetpbHWEnable(obj, varargin)
            if ~isempty(obj.pmhCOM.pmValue)
                obj.pbQueryHWInfo.Enable = 'on';
            else
                obj.pbQueryHWInfo.Enable = 'off';
            end
        end
        
        function queryHardwareInfo(obj,varargin)
            obj.pbQueryHWInfo.Enable = 'off';
            obj.pbQueryHWInfo.String = 'Querying';
            pause(0); %force uicontrol string to change before proceeding
            most.idioms.safeSetProp(obj.hResource,'hCOM',obj.pmhCOM.pmValue);
            obj.hResource.peekHardwareInfo();
            obj.pbQueryHWInfo.String = 'Query Hardware Info';
            obj.pbQueryHWInfo.Enable = 'on';
        end
        
        function val = get.isBaudRateSettable(obj)
            mc = meta.class.fromName(class(obj.hResource));
            [tf,idx] = ismember('baudRate',{mc.PropertyList.Name});
            
            if ~tf
                val = false;
                return
            end
            
            mp = mc.PropertyList(idx);
            
            val = true;
            val = val && ~mp.Constant;
            val = val && strcmpi(mp.GetAccess,'public');
            val = val && strcmpi(mp.SetAccess,'public');
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

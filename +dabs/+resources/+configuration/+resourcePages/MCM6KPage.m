classdef MCM6KPage < dabs.resources.configuration.ResourcePage
    properties
        pmhCOM
        pbQueryHWInfo
        txBaudRate
        pmBaudRate
        
        pmXSlot
        pmYSlot
        pmZSlot
        pmRSlot
        
        pmShutterSlot
        etShutterOpenTime
        pmFlipperMirrorSlot
        etPosition1
        etPosition2
        cbAutoRead;
        
        txInfo;
        
        hListeners = event.listener.empty(0,1);
    end
    
    properties (Dependent)
        isBaudRateSettable
    end
    
    methods
        function obj = MCM6KPage(hResource,hParent)
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
            
            ttStr = sprintf('Slot Number of the MCM6000 that the X actuator is connected to.\nSlot 1 may be labeled "X", in which case, it would be most appropriate\n(but not strictly necessary) for the X stage to be connected to this slot.');
            txSlotX = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-81 57 150 20],'Tag','txSlotX','String','X Axis Slot','HorizontalAlignment','right');
            obj.pmXSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [74 54 81 20],'Tag','pmXSlot','tooltip',ttStr);
            
            ttStr = sprintf('Slot Number of the MCM6000 that the Y actuator is connected to.\nSlot 2 may be labeled "Y", in which case, it would be most appropriate\n(but not strictly necessary) for the Y stage to be connected to this slot.');
            txSlotY = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [13 85 56 20],'Tag','txSlotY','String','Y Axis Slot','HorizontalAlignment','right');
            obj.pmYSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [74 80 81 20],'Tag','pmYSlot','tooltip',ttStr);
            
            ttStr = sprintf('Slot Number of the MCM6000 that the Z actuator is connected to.\nSlot 3 may be labeled "Z", in which case, it would be most appropriate\n(but not strictly necessary) for the Z stage to be connected to this slot.');
            txSlotZ = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [231 59 60 20],'Tag','txSlotZ','String','Z Axis Slot','HorizontalAlignment','right');
            obj.pmZSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [293 53 81 20],'Tag','pmZSlot','tooltip',ttStr);
            
            ttStr = sprintf('Slot Number of the MCM6000 that the R actuator is connected to.\nSlot 4 may be labeled "R", in which case, it would be most appropriate\n(but not strictly necessary) for the Rotation stage to be connected to this slot.');
            txSlotR = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [230 81 60 20],'Tag','txSlotR','String','R Axis Slot','HorizontalAlignment','right');
            obj.pmRSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [293 79 81 20],'Tag','pmRSlot','tooltip',ttStr);
            
            obj.txInfo = most.gui.uicontrol('Parent',hTab,'Style','text','FontSize', 7, 'RelPosition', [4 296 167 200],'Tag','txInfo','String','','HorizontalAlignment','left');
            
            hTab = uitab('Parent',hTabGroup,'Title','Misc');
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 30 120 20],'Tag','txShutter','String','Shutter Slot','HorizontalAlignment','right');
            obj.pmShutterSlot  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 27 120 20],'Tag','pmShutter');
            
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 56 120 20],'Tag','txShutterOpenTime','String','Shutter Open Time [s]','HorizontalAlignment','right');
            obj.etShutterOpenTime = most.gui.uicontrol('Parent',hTab,'Style','edit','String','0.5','RelPosition', [150 53 120 20],'Tag','etShutterOpenTime');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 82 120 20],'Tag','txMirror','String','Flipper Mirror Slot','HorizontalAlignment','right');
            obj.pmFlipperMirrorSlot = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150.8 79.4 120 20],'Tag','pmMirror');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 108.4 120 20],'Tag','txMirrorPosition1','String','Position 1 Name','HorizontalAlignment','right');
            obj.etPosition1 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [150.4 105.8 120 20],'Tag','etMirrorPosition1');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24.0000000000001 136.6 120 20],'Tag','txMirrorPosition2','String','Position 2 Name','HorizontalAlignment','right');
            obj.etPosition2 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [149.8 134.2 120 20],'Tag','etMirrorPosition2');

            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [24 170 120 20],'Tag','txAutoRead','String','Enable Auto Read','HorizontalAlignment','right');
            obj.cbAutoRead = most.gui.uicontrol('Parent',hTab,'Style','checkbox','String',{''},'RelPosition', [151.8 166.8 120 20],'Tag','cbAutoRead');
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
            
            obj.pmFlipperMirrorSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmFlipperMirrorSlot.pmValue = num2str(obj.hResource.mirrorSlot);

            obj.etPosition1.String = obj.hResource.mirrorPosition1Name;
            obj.etPosition2.String = obj.hResource.mirrorPosition2Name;
            
            obj.pmXSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmXSlot.pmValue = num2str(obj.hResource.xMotorSlot);
            
            obj.pmYSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmYSlot.pmValue = num2str(obj.hResource.yMotorSlot);
            
            obj.pmZSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmZSlot.pmValue = num2str(obj.hResource.zMotorSlot);
            
            obj.pmRSlot.String = {'' '1', '2', '3', '4', '5', '6', '7'};
            obj.pmRSlot.pmValue = num2str(obj.hResource.rMotorSlot);
            
            obj.cbAutoRead.Value = obj.hResource.tfAutoRead;
            
            info = '';
            
            if ~isempty(obj.hResource.hardwareInfo)
                cellfo = cellfun(@(x,y) [x ' = ' y '\n'], fieldnames(obj.hResource.hardwareInfo), struct2cell(obj.hResource.hardwareInfo), 'UniformOutput', false);
                s = size(cellfo,1);

                for i=1:s
                    info = [info sprintf(cellfo{i})];
                end
                obj.txInfo.String = info;
                obj.txInfo.hCtl.BackgroundColor = most.constants.Colors.lightGray;
            else
                obj.txInfo.String = '';
            end
        end
        
        function apply(obj)
            obj.hResource.deinit();
            most.idioms.safeSetProp(obj.hResource,'hCOM',obj.pmhCOM.pmValue);
            
            most.idioms.safeSetProp(obj.hResource,'xMotorSlot',str2num(obj.pmXSlot.pmValue));
            most.idioms.safeSetProp(obj.hResource,'yMotorSlot',str2num(obj.pmYSlot.pmValue));
            most.idioms.safeSetProp(obj.hResource,'zMotorSlot',str2num(obj.pmZSlot.pmValue));
            most.idioms.safeSetProp(obj.hResource,'rMotorSlot',str2num(obj.pmRSlot.pmValue));
            
            
            most.idioms.safeSetProp(obj.hResource,'shutterSlot',str2num(obj.pmShutterSlot.pmValue));
            most.idioms.safeSetProp(obj.hResource,'shutterOpenTime_s',str2double(obj.etShutterOpenTime.String));
            most.idioms.safeSetProp(obj.hResource,'mirrorSlot',str2num(obj.pmFlipperMirrorSlot.pmValue));
            most.idioms.safeSetProp(obj.hResource,'mirrorPosition1Name',obj.etPosition1.String);
            most.idioms.safeSetProp(obj.hResource,'mirrorPosition2Name',obj.etPosition2.String);
            most.idioms.safeSetProp(obj.hResource,'tfAutoRead',logical(obj.cbAutoRead.Value));
            
            if obj.isBaudRateSettable
                obj.hResource.baudRate = str2double(obj.pmBaudRate.pmValue);
            end
            
            obj.hResource.saveMdf();
            obj.hResource.reinit();
            pause(0.2);
            obj.redraw();
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

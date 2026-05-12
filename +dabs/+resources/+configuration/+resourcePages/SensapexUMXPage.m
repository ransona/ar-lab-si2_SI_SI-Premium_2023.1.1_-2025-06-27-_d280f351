classdef SensapexUMXPage < dabs.resources.configuration.ResourcePage
    properties
        etBroadcastAddress;
        txBroadcastAddressStatus;
        pbGetDeviceList;
        pmDevId;
        etTimeout_ms;

        etSpeed_umPerS;
        cbSimultaneousAxisMotion;
        etMax_acc_umPerS2;
    end

    methods
        function obj = SensapexUMXPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end

        function makePanel(obj,hParent)
            hTabGroup = uitabgroup('Parent',hParent);
                hTab = uitab('Parent',hTabGroup,'Title','Connection');
                    most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [18 31 134 20],'Tag','txBroadcastAddress','String','Broadcast Address [IPv4]:','HorizontalAlignment','right');
                    obj.etBroadcastAddress = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [160 22 120 20],'Tag','etBroadcastAddress','callback',@(src,evt)obj.updateDevListButton);
                    obj.txBroadcastAddressStatus = most.gui.uicontrol('Parent',hTab,'Style','text','String',{''},'RelPosition', [25 60 260 30],'Tag','txBroadcastAddressStatus');
        
                    most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [30 95 120 20],'Tag','txDevId','String','Device Id:','HorizontalAlignment','right');
                    obj.pmDevId = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [160 95 120 20],'Tag','pmDevId');
                    obj.pbGetDeviceList = most.gui.uicontrol('Parent',hTab,'Style','pushbutton','String','Update Device List','RelPosition', [160 100 120 20],'Tag','etBroadcastAddress','callback',@(varargin)obj.updateDeviceList);
        
                    most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [10 149 148 20],'Tag','txTimeout_ms','String','Communication Timeout [ms]:','HorizontalAlignment','right');
                    obj.etTimeout_ms = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [161.2 146.4 120 20],'Tag','etTimeout_ms');


                hTab = uitab('Parent',hTabGroup,'Title','Movement Settings');
                    most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [12.4 62.2 150 20],'Tag','txSpeed_umPerS','String','Movement Speed [µm/s]:','HorizontalAlignment','right');
                    obj.etSpeed_umPerS = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [181.6 61.2 120 20],'Tag','etSpeed_umPerS');
        
                    most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [5.19999999999999 97.2 160 20],'Tag','txSimultaneousAxesMovement','String','Simultaneous Axes Movement:','HorizontalAlignment','right');
                    obj.cbSimultaneousAxisMotion = most.gui.uicontrol('Parent',hTab,'Style','checkbox','String',{''},'RelPosition', [182 92 120 20],'Tag','cbSimultaneousAxisMotion');
        
                    most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [10 125 161 20],'Tag','txAcceleration','String','Movement Acceleration [µm/s²]:','HorizontalAlignment','right');
                    obj.etMax_acc_umPerS2 = most.gui.uicontrol('Parent',hTab,'Style','edit','String',{''},'RelPosition', [181.2 121 120 20],'Tag','etMax_acc_umPerS2');
        end

        function redraw(obj)
            obj.etBroadcastAddress.String = obj.hResource.broadcastAddress;

            obj.updateDevListButton();
            obj.updateDeviceList();
            if ~isempty(obj.hResource.devId)
                obj.pmDevId.pmValue = obj.hResource.devId;
            end

            obj.etTimeout_ms.String = num2str(obj.hResource.timeout_ms);
            obj.etSpeed_umPerS.String = num2str(obj.hResource.speed_umPerS);
            obj.cbSimultaneousAxisMotion.Value = logical(obj.hResource.speed_umPerS);
            obj.etMax_acc_umPerS2.String = num2str(obj.hResource.max_acc_umPerS2);
        end

        function apply(obj)
            most.idioms.safeSetProp(obj.hResource,'devId',str2double(obj.pmDevId.String));
            most.idioms.safeSetProp(obj.hResource,'broadcastAddress',obj.etBroadcastAddress.String);
            most.idioms.safeSetProp(obj.hResource,'timeout_ms',str2double(obj.etTimeout_ms.String));

            most.idioms.safeSetProp(obj.hResource,'speed_umPerS',str2double(obj.etSpeed_umPerS.String));
            most.idioms.safeSetProp(obj.hResource,'simultaneousAxisMotion',logical(obj.cbSimultaneousAxisMotion.Value));
            most.idioms.safeSetProp(obj.hResource,'max_acc_umPerS2',str2double(obj.etMax_acc_umPerS2.String));

            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end

        function updateDevListButton(obj)
            try
                if isempty(obj.etBroadcastAddress.String) || isempty(obj.etTimeout_ms.String)
                    obj.pbGetDeviceList.Enable = false;
                else
                    obj.hResource.broadcastAddress = obj.etBroadcastAddress.String; %For redraw and validation check
                    obj.hResource.timeout_ms = str2double(obj.etTimeout_ms.String);
                    obj.pbGetDeviceList.Enable = true;
                end
                obj.txBroadcastAddressStatus.String = '';
            catch
                %Would set device error message from here, but its
                %SetAccess is protected.
                obj.txBroadcastAddressStatus.String = 'Broadcast Address is of invalid syntax';
                obj.pbGetDeviceList.Enable = false;
            end
        end

        function updateDeviceList(obj)
            if isempty(obj.hResource.broadcastAddress)
                return;
            end

            hUMX = dabs.sensapex.UMX.getInst(obj.hResource.broadcastAddress,obj.hResource.timeout_ms,0);
            [err, deviceList] = hUMX.um_get_device_list();

            if ~err
                mask = logical(deviceList);
                deviceList = deviceList(mask);
                obj.pmDevId.String= num2str(deviceList);
                obj.txBroadcastAddressStatus.String = '';
            else
                %Would set device error message from here, but its
                %SetAccess is protected.
                obj.txBroadcastAddressStatus.String = 'Broadcast Address likely does not match a controller on the network.';
            end
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

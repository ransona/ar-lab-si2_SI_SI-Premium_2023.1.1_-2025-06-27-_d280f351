function redraw(obj)
    %% COM port detection/refresh
    ports = obj.hResourceStore.filterByClass(?dabs.resources.SerialPort);
    assert(iscell(ports));
    portNames = cell(1, numel(ports));
    for iCom = 1:numel(ports)
        portNames{iCom} = ports{iCom}.name;
    end
    modelCom = obj.hResource.Com;
    assert(isa(modelCom, 'dabs.resources.Resource'));
    set(obj.ComDropdown ...
        , Value = 1 ...
        , String = [{' '}, portNames] ...
        , UserData = struct(Ports = {ports}) ... % note, off by one due to empty default
        );
    if ~isempty(modelCom)
        newIndex = find( ...
            modelCom.name == convertCharsToStrings(obj.ComDropdown.String), 1);
        assert(~isempty(newIndex)); % must exist because reinit is always called before redraw.
        obj.ComDropdown.Value = newIndex;
    end
    
    if ~isempty(obj.hResource.errorMsg)
        obj.ComDropdown.BackgroundColor = most.constants.Colors.lightRed;
        obj.HardwareInfoLabel.String = "";
        set([obj.EnabledCheckboxes, obj.JoystickBlinkButtons], Enable = 'off');
        set(obj.AxisLabels, String = "");
        set(obj.StatusLabels, String = char(0x2753)); % ❓
        
        panelColor = [.6, .6, .6];
        set(obj.AxisPanels, BackgroundColor = panelColor);
        for iPanel = 1:numel(obj.AxisPanels)
            set(obj.AxisPanels(iPanel).Children, BackgroundColor = panelColor);
        end
        return;
    end
    obj.ComDropdown.BackgroundColor = [.94, .94, .94];
    
    obj.hResource.stopAsyncPoller();
    
    mcm = obj.hResource.Controller;
    
    %% general hardware info
    p = mcm.getHardwareInfo();
    mcm.waitForLastResponse();
    hwInfo = p.Data;
    obj.HardwareInfoLabel.String = [...
        sprintf("Firmware: %s", hwInfo.Firmware) ...
        sprintf("CPLD Ver: %s", hwInfo.CpldVersion) ...
        sprintf("SN: %s", hwInfo.SerialNumber) ...
        ];
    
    %% motor info
    p = mcm.getHardwareStatus();
    mcm.waitForLastResponse();
    hwStatus = p.Data;
    for iMotor = 1:3
        p = mcm.getMotorInfo(iMotor);
        checkboxValue = obj.EnabledCheckboxes(iMotor).Min;
        interactiveEnableState = 'off';
        mcm.waitForLastResponse();
        minfo = p.Data;
        if minfo.IsConnected
            if hwStatus.IsErrored(iMotor)
                panelColor = 'r';
                statusSymbol = char(0x2757); % ❗
                statusTooltip = ["This axis is in an error state and cannot be recovered from " ...
                    "while this resource is running."];
            else
                motorStatusPromise = mcm.getMotorStatus(iMotor);
                panelColor = [.94, .94, .94];
                statusSymbol = char(0x2714); % ✔
                mcm.waitForLastResponse();
                if ismember(dabs.thorlabs.mcm301.StatusFlag.Enabled, motorStatusPromise.Data.Flags)
                    checkboxValue = obj.EnabledCheckboxes(iMotor).Max;
                end
                interactiveEnableState = 'on';
                statusTooltip = "This axis is connected and controllable.";
            end
        else
            panelColor = [.6, .6, .6];
            statusSymbol = char(0x274C); % ❌
            statusTooltip = "This axis is disconnected and cannot be controlled.";
        end
        set([obj.AxisPanels(iMotor); obj.AxisPanels(iMotor).Children], BackgroundColor = panelColor);
        obj.EnabledCheckboxes(iMotor).Value = checkboxValue;
        obj.AxisLabels(iMotor).String = minfo.PartNumber;
        set(obj.StatusLabels(iMotor), String = statusSymbol, Tooltip = statusTooltip);
        set([obj.JoystickBlinkButtons(iMotor), obj.EnabledCheckboxes(iMotor)] ...
            , Enable = interactiveEnableState ...
            );
    end
    obj.hResource.startAsyncPoller();
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

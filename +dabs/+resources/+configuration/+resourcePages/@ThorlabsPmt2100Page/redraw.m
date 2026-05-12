function redraw(obj)
    %% Get valid VISA addresses
    AddressPopup = obj.SerialNumberPopupMenu;
    serialNumbers = getPmtSerialNumbers();
    isSelectedConnected = false(size(serialNumbers));
    Device = obj.hResource.PmtDevice;
    if ~isempty(Device)
        isSelectedConnected = serialNumbers == Device.SerialNumber;
    end

    if isempty(serialNumbers)
        % this can rarely occur but only if ScanImage was freshly started
        % without any PMT connected.
        AddressPopup.BackgroundColor = 'r';
        return;
    end
    AddressPopup.String = ["" serialNumbers];
    if ~any(isSelectedConnected)
        % choose empty
        set(AddressPopup, 'Value', 1, 'BackgroundColor', 'y');
        set(obj.LiveModeToggle, 'Value', obj.LiveModeToggle.Min, 'Enable', 'off');
        obj.disableLiveMode();
        obj.updatePowerToggleState(false);
        obj.PowerLamp.Color = 'k';
        obj.DetectorLabel.String = "N/A";
        return;
    end
    set(AddressPopup ...
        , 'Value', find(isSelectedConnected, 1) + 1 ...
        , 'BackgroundColor', [.94, .94, .94]);
    obj.LiveModeToggle.Enable = 'on';
    obj.DetectorLabel.String = sprintf('%s', obj.hResource.PmtType);

    %% Redraw entries
    if obj.LiveModeToggle.Value == obj.LiveModeToggle.Max
        return; % redraws handled by listeners instead.
    end

    obj.updatePowerToggleState(Device.isConnected() && Device.isPowered());
    Device.isTrippedAsync(@obj.updateTrippedState);

    obj.GainEditSlider.Min = Device.PERCENT_GAIN_LIMITS(1);
    obj.GainEditSlider.Max = Device.PERCENT_GAIN_LIMITS(2);
    obj.OffsetEditSlider.Min = Device.VOLTAGE_OFFSET_LIMITS(1);
    obj.OffsetEditSlider.Max = Device.VOLTAGE_OFFSET_LIMITS(2);

    obj.updateGainVoltage(obj.hResource.GainPercentage2VoltageFunction(Device.GainPercent));
    obj.updateOffsetVoltage(Device.getReportedVoltageOffset());
    obj.updateBandwidth(Device.getReportedHertzBandwidth());
end

function serialNumbers = getPmtSerialNumbers()
    visaDevices = dabs.resources.VISA.scanSystem();
    visaAddresses = cell(size(visaDevices));
    for iVisa = 1:length(visaDevices)
        visaAddresses{iVisa} = visaDevices{iVisa}.name;
    end
    visaAddresses = string(visaAddresses);

    pmtRegexPattern = 'USB0\:\:0x1313\:\:0x2F00\:\:(.{8})(?:\:\:0)?\:\:INSTR';
    foundTokens = regexp(visaAddresses, pmtRegexPattern, 'tokens', 'once');
    serialNumbers = [foundTokens{:}];
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

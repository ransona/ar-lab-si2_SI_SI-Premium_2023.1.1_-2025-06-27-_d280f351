function apply(obj)
    % propagate to model
    % We do this backwards so setting the power value is last in case of
    % weirdness after unpowering the PMT.

    Pmt = obj.hResource;

    %% Wavelength Value
    Pmt.wavelength_nm = obj.WavelengthEdit.Value;

    %% AutoOn
    Pmt.autoOn = obj.AutoOnCheckbox.Value == obj.AutoOnCheckbox.Max;

    Pmt.saveMdf();
    %% VISA Address
    serialNumber = string(obj.SerialNumberPopupMenu.String(obj.SerialNumberPopupMenu.Value));

    if serialNumber ~= obj.hResource.SerialNumber
        Pmt.selectDevice(serialNumber); % intentionally sets error message if empty.
        Pmt.saveMdf();
        return;
    end

    if 0 == strlength(serialNumber)
        return; % don't pull from properties if serialNumber is empty.
    end

    if obj.LiveModeToggle.Value == obj.LiveModeToggle.Max
        return; % applies handled by callbacks.
    end
    
    %% Properties
    BandwidthMenu = obj.BandwidthPopupMenu;
    Pmt.setBandwidth(BandwidthMenu.UserData.BandwidthValues(BandwidthMenu.Value));

    Pmt.setGainOffset(obj.OffsetEditSlider.Value);
    Pmt.setGain(Pmt.GainPercentage2VoltageFunction(obj.GainEditSlider.Value));
    Pmt.setPower(obj.PowerToggle.Value == obj.PowerToggle.Max);
    Pmt.saveMdf();
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

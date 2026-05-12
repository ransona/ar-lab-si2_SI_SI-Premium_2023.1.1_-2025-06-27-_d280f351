classdef ThorlabsPmt2100Page < dabs.resources.configuration.ResourcePage
   %% PROPERTIES

   properties (Access = private)
       WavelengthEdit matlab.ui.control.UIControl;
       WavelengthColorPanel matlab.ui.container.Panel;
       SerialNumberPopupMenu matlab.ui.control.UIControl;
       DetectorLabel most.gui.staticText;
       LiveModeToggle matlab.ui.control.UIControl;
       PowerToggle matlab.ui.control.UIControl;
       PowerLamp most.gui.Lamp;
       GainEditSlider most.gui.EditSlider;
       GainReportedEdit matlab.ui.control.UIControl;
       OffsetEditSlider most.gui.EditSlider;
       OffsetReportedEdit matlab.ui.control.UIControl;
       BandwidthPopupMenu matlab.ui.control.UIControl;
       BandwidthReportedEdit matlab.ui.control.UIControl;
       AutoOnCheckbox matlab.ui.control.UIControl;

       % live mode listeners
       ControlListeners(:,1) event.listener;

       % persistently on listeners. These listeners are not tied to device
       % lifetime and can be left on.
       WavelengthListener(:,1) event.listener;
       AutoOnListener(:,1) event.listener;
   end

   %% METHODS
   methods
       function obj = ThorlabsPmt2100Page(ResourceModel, GuiParent)
           assert(isa(ResourceModel, 'dabs.thorlabs.Pmt2100'));
           obj@dabs.resources.configuration.ResourcePage(ResourceModel, GuiParent);
           obj.bindToModel();
           [obj.ControlListeners.Enabled] = deal(false);
       end

       function delete(obj)
           delete(obj.ControlListeners);
           delete(obj.WavelengthListener);
           delete(obj.AutoOnListener);
       end

       % dabs.resources.configuration.ResourcePage
       makePanel(varargin);

       redraw(varargin);

       apply(varargin);

       function remove(obj)
           obj.hResource.deleteAndRemoveMdfHeading(); % from HasMachineDataFile.
       end
   end

   methods (Access = private)
       function bindToModel(obj)
           Pmt = obj.hResource;

           %% sync with model
           obj.updatePowerState(Pmt.powerOn);
           obj.updateGainVoltage(Pmt.gain_V);
           obj.updateOffsetVoltage(Pmt.gainOffset_V);
           obj.updateBandwidth(Pmt.bandwidth_Hz);
           obj.updateTrippedState(Pmt.tripped);
           obj.updateWavelength(Pmt.wavelength_nm);
           obj.updateAutoOnState(Pmt.autoOn);

           %% listeners
           addPropertyListener = @(propertyName, callback)most.ErrorHandler.addCatchingListener(...
               Pmt, propertyName, 'PostSet' ...
               , @(~,Event)callback(Event.AffectedObject.(propertyName)) ...
               );
           obj.ControlListeners = [...
               addPropertyListener('powerOn', @obj.updatePowerState) ...
               addPropertyListener('gain_V', @obj.updateGainVoltage) ...
               addPropertyListener('gainOffset_V', @obj.updateOffsetVoltage) ...
               addPropertyListener('bandwidth_Hz', @obj.updateBandwidth) ...
               addPropertyListener('tripped', @obj.updateTrippedState) ...
               ];
           obj.WavelengthListener = addPropertyListener('wavelength_nm', @obj.updateWavelength);
           obj.AutoOnListener = addPropertyListener('autoOn', @obj.updateAutoOnState);
       end

       function updatePowerToggleState(obj, isOn)
           Control = obj.PowerToggle;
           if isOn
               Control.Value = Control.Max;
               Control.String = 'On';
           else
               Control.Value = Control.Min;
               Control.String = 'Off';
           end
       end

       function updateLampState(obj, isOn, isTripped)
           if isOn && isTripped
               lampColor = 'r';
           elseif isOn && ~isTripped
               lampColor = 'g';
           else % ~isOn
               lampColor = [0.4, 0.4, 0.4];
           end
           obj.PowerLamp.Color = lampColor;
       end

       function updatePowerState(obj, isOn)
           Model = obj.hResource;
           obj.updateLampState(isOn, Model.tripped);
           obj.updatePowerToggleState(isOn);
       end

       function updateGainVoltage(obj, voltage)
           Model = obj.hResource;
           obj.GainEditSlider.Value = Model.GainVoltage2PercentageFunction(voltage);
           if isempty(Model.PmtDevice)
               obj.GainReportedEdit.String = '??? V';
           else
               gain = Model.PmtDevice.getReportedVoltageGain();
               obj.GainReportedEdit.String = sprintf('%.3f V', gain);
           end
       end

       function updateOffsetVoltage(obj, voltage)
           Model = obj.hResource;
           obj.OffsetEditSlider.Value = voltage;
           if isempty(Model.PmtDevice)
               obj.OffsetReportedEdit.String = '??? V';
           else
               offset = Model.PmtDevice.getReportedVoltageOffset();
               obj.OffsetReportedEdit.String = sprintf('%.3f V', offset);
           end
       end

       updateBandwidth(varargin);

       function updateTrippedState(obj, isTripped)
           obj.updateLampState(obj.hResource.powerOn, isTripped);
       end

       function updateAutoOnState(obj, isAutoOnModeEnabled)
           obj.hResource.autoOn = isAutoOnModeEnabled;
           if isAutoOnModeEnabled
               obj.AutoOnCheckbox.Value = obj.AutoOnCheckbox.Max;
           else
               obj.AutoOnCheckbox.Value = obj.AutoOnCheckbox.Min;
           end
       end
      
       function disableLiveMode(obj)
           [obj.ControlListeners.Enabled] = deal(false);
           % unbind callbacks
           obj.PowerToggle.Callback = '';
           obj.GainEditSlider.ValueChangedFunction = @(~)[];
           obj.OffsetEditSlider.ValueChangedFunction = @(~)[];
           obj.BandwidthPopupMenu.Callback = '';
       end

       function enableLiveMode(obj)
           [obj.ControlListeners.Enabled] = deal(true);
           % bind control callbacks.
           Pmt = obj.hResource;
           obj.PowerToggle.Callback = @(Toggle,~)Pmt.setPower(Toggle.Value == Toggle.Max);
           obj.GainEditSlider.ValueChangedFunction = @(newPercentage)Pmt.setGain(...
               Pmt.GainPercentage2VoltageFunction(newPercentage)...
               );
           obj.OffsetEditSlider.ValueChangedFunction = @(newPercentage)setAndSaveMdf( ...
               @()Pmt.setGainOffset(newPercentage));
           obj.BandwidthPopupMenu.Callback = @(Menu,~)setAndSaveMdf( ...
               @()Pmt.setBandwidth(Menu.UserData.BandwidthValues(Menu.Value)));
           function setAndSaveMdf(setterFunction)
               setterFunction();
               Pmt.saveMdf();
           end
       end

       function toggleLiveMode(obj, isEnabled)
           if isEnabled
               obj.enableLiveMode();
           else
               obj.disableLiveMode();
           end
       end

       function updateWavelength(obj, lambdaNm)
           obj.WavelengthColorPanel.BackgroundColor = most.idioms.wavelengthToRGB(lambdaNm);
           set(obj.WavelengthEdit ...
               , 'Value', lambdaNm ...
               , 'String', sprintf(obj.WavelengthEdit.UserData.DisplayFormat, lambdaNm));
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

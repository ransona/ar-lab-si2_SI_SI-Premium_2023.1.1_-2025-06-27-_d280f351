classdef Rack < handle
    % RACK Scientifica Motion8 Rack
    
    properties (SetAccess = private)
        Uid(1,1) string; % Unique Id of the Rack
        SoftwareVersion(1,1) string; % Motion8 Software Version.
    end
    
    properties (Access = private)
        Inner; % internal .Net Rack interface. Should be a Motion8Rack
    end
    
    methods (Static)
        function Racks = getAll()
            import dabs.scientifica.motion8.isAssemblyLoaded;
            import dabs.scientifica.motion8.loadAssembly;
            import dabs.scientifica.motion8.Rack;
            
            if ~isAssemblyLoaded()
                loadAssembly();
            end
            RackList = Scientifica.Motion8.Motion8Rack.GetDevices();
            Racks = Rack.empty();
            for iRack = 1:RackList.Count
                Racks(iRack) = Rack(RackList.Item(iRack - 1));
            end
        end
    end
    
    methods (Access = private) %% Lifecycle
        function obj = Rack(DotNet)
            obj.Inner = DotNet;
            obj.Uid = string(DotNet.UidString);
            obj.SoftwareVersion = string(DotNet.Version.ToString());
        end
    end
    
    methods %% Devices
        function Devices = getDevices(obj)
            import dabs.scientifica.motion8.Device;
            most.idioms.mustBeValidObj(obj);
            DeviceList = obj.Inner.Devices;
            for iDevice = 1:DeviceList.Count
                Devices(iDevice) = Device(DeviceList.Item(iDevice - 1));
            end
        end
    end
    
    methods %% Metadata
        function thermistorReadings = getTemperature(obj)
            most.idioms.mustBeValidObj(obj);
            Temperatures = obj.Inner.Temperatures;
            thermistorReadings = [Temperatures.Thermistor0, Temperatures.Thermistor1];
        end
        
        function voltage = getPsuVoltage(obj)
            most.idioms.mustBeValidObj(obj);
            voltage = obj.Inner.PsuVoltage;
        end
        
        function [SpeedSetting, isAuto] = getFanSetting(obj)
            % If import is using the non-functional form (import Scientifica.Motion8...),
            % MATLAB R2020A (and maybe other versions) will attempt to
            % "preload" what it assumes to be a .m or a Java file with this
            % name. Since the .NET assemblies for Scientifica have not been
            % loaded, this will throw an error.
            % As such, please do not correct this errant import call since
            % it works around this error while keeping the import.
            import('Scientifica.Motion8.TemperatureControlMode');
            most.idioms.mustBeValidObj(obj);
            SpeedSetting = string(obj.Inner.Temperatures.FanSpeed);
            ControlMode = obj.Inner.Temperatures.ControlMode;
            if TemperatureControlMode.Over == ControlMode
                warning('Motion8:OverTemperature' ...
                    , ['The Motion8 Rack is over temperature and power to the motors is disabled! ' ...
                    'Power cycling the rack once it has cooled will be required for recovery!']);
            end
            isAuto = TemperatureControlMode.Manual ~= ControlMode;
        end
        
        function setFanSpeed(obj, speedSetting)
            % If import is using the non-functional form (import Scientifica.Motion8...),
            % MATLAB R2020A (and maybe other versions) will attempt to
            % "preload" what it assumes to be a .m or a Java file with this
            % name. Since the .NET assemblies for Scientifica have not been
            % loaded, this will throw an error.
            % As such, please do not correct this errant import call since
            % it works around this error while keeping the import.
            import('Scientifica.Motion8.FanSpeed');
            most.idioms.mustBeValidObj(obj);
            validateattributes(speedSetting, {'char', 'string'}, {'scalartext'} ...
                , 'setFanSpeed', 'speedSetting', 2);
            speedSetting = lower(string(speedSetting));
            if "auto" == speedSetting
                obj.Inner.SetFanAuto();
                return;
            end
            AllSpeeds = System.Enum.GetValues(FanSpeed.Low.GetType);
            for iSpeed = 1:AllSpeeds.Length
                Speed = AllSpeeds(iSpeed);
                if speedSetting == lower(string(Speed))
                    obj.Inner.SetFanSpeed(Speed);
                    return;
                end
            end
            error('Motion8:InvalidSpeedSetting' ...
                , 'invalid fan speed setting "%s". Must be one of: \n%s, or Auto' ...
                , join(string(System.Enum.GetNames(FanSpeed.Low.GetType)), ', '));
        end
        
        getBreakoutMap(obj);
        
        function S = summarize(obj)
            readings = obj.getTemperature();
            S = struct(...
                'SoftwareVersion', obj.SoftwareVersion ...
                , 'Thermistor0', num2str(readings(1)) ...
                , 'Thermistor1', num2str(readings(2)) ...
                , 'PsuVoltage', num2str(obj.getPsuVoltage()) ...
                , 'FanSpeed', obj.getFanSetting() ...
                );
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

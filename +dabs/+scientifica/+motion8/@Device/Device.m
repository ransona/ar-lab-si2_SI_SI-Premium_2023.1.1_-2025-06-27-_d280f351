classdef Device < handle
    % DEVICE Scientifica Motion8 Device
    
    properties (SetAccess = immutable)
        Id(1,1) string;
        DeviceNumber(1,1);
        AvailableAxes;
    end
    
    properties (SetAccess = private)
        isWaitingOnMove = false;
    end
    
    properties (Access = private)
        Inner; % DotNet Object (Motion8Device).
        MoveDelegate;
        asyncTimerTag;
        TimerDoneListener(:,1) event.listener;
    end
    
    methods (Access = ?dabs.scientifica.motion8.Rack) %% Lifecycle
        function obj = Device(Inner)
            import dabs.scientifica.motion8.isAsyncAssemblyLoaded;
            import dabs.scientifica.motion8.loadAsyncAssembly;
            if ~isAsyncAssemblyLoaded()
                loadAsyncAssembly();
            end
            
            obj.Inner = Inner;
            if Inner.Device == Scientifica.Motion8.Device.Device1
                obj.DeviceNumber = 1;
            elseif Inner.Device == Scientifica.Motion8.Device.Device2
                obj.DeviceNumber = 2;
            else
                error('unsupported device enumeration %s', string(Inner.Device));
            end
            obj.Id = string(obj.Inner.LocalID);
            obj.MoveDelegate = Mbf.AsyncDelegation.MoveXyz(@Inner.AbsoluteXYZ);
            obj.AvailableAxes = obj.getAvailableAxes();
            obj.initTimer();
        end
    end
    
    methods %% Lifecycle
        function delete(obj)
            obj.Inner.AbruptStop();
            delete(obj.TimerDoneListener);
            delete(obj.getTimer());
        end
    end
    
    methods %% Movement
        function step(obj)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            obj.Inner.Step();
        end
        
        function stop(obj)
            most.idioms.mustBeValidObj(obj);
            obj.Inner.AbruptStop();
        end
        
        function goTo(obj, varargin)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            obj.goToAsync(varargin{:});
            while obj.isWaitingOnMove
                pause(round(1/30, 3));
            end
        end
        
        goToAsync(obj, varargin);
    end
    
    methods %% Queries
        function tf = isMoving(obj)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            tf = obj.Inner.IsMoving;
        end
        
        function tf = isAxisMoving(obj, Axes)
            most.idioms.mustBeValidObj(obj);
            assert(isa(Axes, 'dabs.scientifica.motion8.Axis'), 'A must be an Axis');
            assert(isscalar(Axes) || isvector(Axes), 'A must be a scalar or vector Axis');
            
            Readouts = selectAxes(obj.Inner.DroData, Axes);
            tf = false(size(Readouts));
            for iR = 1:length(Readouts)
                R = Readouts{iR};
                assert(~isempty(R), 'Readout was empty! Axis %s is invalid for this device' ...
                    , char(Axes(iR)));
                tf(iR) = R.IsMoving;
            end
        end
        
        function tf = isAtLowerLimit(obj)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            tf = obj.isAxisAtLowerLimit(obj.AvailableAxes);
        end
        
        function tf = isAxisAtLowerLimit(obj, Axes)
            most.idioms.mustBeValidObj(obj);
            assert(isa(Axes, 'dabs.scientifica.motion8.Axis'), 'A must be an Axis');
            assert(isscalar(Axes) || isvector(Axes), 'A must be a scalar or vector Axis');
            
            Readouts = selectAxes(obj.Inner.DroData, Axes);
            tf = false(size(Readouts));
            for iR = 1:length(Readouts)
                R = Readouts{iR};
                assert(~isempty(R), 'Readout was empty! Axis %s is invalid for this device' ...
                    , char(Axes(iR)));
                tf(iR) = R.LowerLimit;
            end
        end
        
        function tf = isAtUpperLimit(obj)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            tf = obj.isAxisAtUpperLimit(obj.AvailableAxes);
        end
        
        function tf = isAxisAtUpperLimit(obj, Axes)
            most.idioms.mustBeValidObj(obj);
            assert(isa(Axes, 'dabs.scientifica.motion8.Axis'), 'A must be an Axis');
            assert(isscalar(Axes) || isvector(Axes), 'A must be a scalar or vector Axis');
            
            Readouts = selectAxes(obj.Inner.DroData, Axes);
            tf = false(size(Readouts));
            for iR = 1:length(Readouts)
                R = Readouts{iR};
                assert(~isempty(R), 'Readout was empty! Axis %s is invalid for this device' ...
                    , char(Axes(iR)));
                tf(iR) = R.UpperLimit;
            end
        end
    end
    
    methods %% Metadata
        function [Type, SubType] = getDeviceType(obj)
            most.idioms.mustBeValidObj(obj);
            Type = string(obj.Inner.DeviceType);
            SubType = string(obj.Inner.DeviceSubType);
        end
        
        function Pos_um = getLastPosition(obj)
            import dabs.scientifica.motion8.deserializeUm;
            most.idioms.mustBeValidObj(obj);
            Axes = obj.AvailableAxes;
            pos = deserializeUm(cell2mat(selectAxes(obj.Inner.Position, Axes)));
            Pos_um = struct();
            for iA = 1:length(Axes)
                A = Axes(iA);
                Pos_um.(char(A)) = pos(iA);
            end
        end
        
        function S = summarize(obj)
            S = struct(...
                'ID', obj.Id ...
                , 'Number', num2str(obj.DeviceNumber) ...
                , 'Axes', strjoin(string(obj.AvailableAxes), ',') ...
                , 'Type', obj.getDeviceType() ...
                );
        end
    end
    
    methods (Access = private) %% Axes
        function Axes = getAvailableAxes(obj)
            most.idioms.mustBeValidObj(obj);
            assert(isscalar(obj), 'obj must be scalar');
            Axes = enumeration('dabs.scientifica.motion8.Axis');
            isDisplayed = false(size(Axes));
            Readouts = selectAxes(obj.Inner.DroData, Axes);
            for iR = 1:length(Readouts)
                R = Readouts{iR};
                % the condition for display is copied directly from the undocumented DroData
                % property "ShouldDisplay". We don't want to rely on undocumented features for
                % something like this so we recreate the decompilation here using documented
                % properties.
                isDisplayed(iR) = ~isempty(R) && R.IsEnabled && ~(R.LowerLimit && R.UpperLimit);
            end
            Axes = Axes(isDisplayed);
        end
    end
    
    methods (Access = private) %% Timer
        initTimer(obj);
        
        function Timer = getTimer(obj)
            assert(isscalar(obj), 'obj must be scalar');
            Timer = timerfindall('Tag', obj.asyncTimerTag);
            assert(~isempty(Timer) && isvalid(Timer), 'failed to retrieve timer: no timer found');
            assert(isscalar(Timer), 'failed to retrieve timer: multiple timers found');
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

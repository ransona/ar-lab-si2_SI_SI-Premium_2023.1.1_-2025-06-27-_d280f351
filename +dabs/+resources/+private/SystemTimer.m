classdef SystemTimer < handle
    events
        beacon_QueryIO
        beacon_1Hz
        beacon_15Hz
        beacon_30Hz
        beacon_0_2Hz
    end
    
    properties (SetAccess=private)
        started = false;
    end
    
    properties (SetAccess=private,GetAccess=private)
        hTimers = timer.empty();
    end
    
    methods
        function obj = SystemTimer()
            errorFcn = @(Timer,~)fprintf(2, 'Timer "%s" threw an error with message:\n\n"%s"' ...
                , Timer.Name, Timer.UserData.ME.getReport());
            obj.hTimers(end+1) = timer( ...
                'Name', 'System Timer 1Hz' ...
                , 'ExecutionMode', 'fixedSpacing' ...
                , 'Period', 1 ...
                , 'TimerFcn', @(Timer, ~)obj.catchingNotify(Timer, 'beacon_1Hz') ...
                , 'ErrorFcn', errorFcn);
            obj.hTimers(end+1) = timer( ...
                'Name', 'System Timer 15Hz' ...
                , 'ExecutionMode', 'fixedSpacing' ...
                , 'Period', 0.066 ...
                , 'TimerFcn', @(Timer, ~)obj.catchingNotify(Timer, 'beacon_15Hz') ...
                , 'ErrorFcn', errorFcn);
            obj.hTimers(end+1) = timer( ...
                'Name','System Timer 30Hz' ...
                , 'ExecutionMode','fixedSpacing' ...
                ,'Period', 0.033 ...
                , 'TimerFcn',@(Timer, ~)obj.catchingNotify(Timer, 'beacon_30Hz') ...
                , 'ErrorFcn', errorFcn);
            obj.hTimers(end+1) = timer( ...
                'Name','System Timer 0.2Hz' ...
                , 'ExecutionMode','fixedSpacing' ...
                ,'Period', 5 ...
                ,'TimerFcn',@(Timer, ~)obj.catchingNotify(Timer, 'beacon_0_2Hz') ...
                , 'ErrorFcn', errorFcn);
            obj.hTimers(end+1) = timer( ...
                'Name', 'System Timer Query IO' ...
                , 'ExecutionMode','fixedSpacing' ...
                , 'Period', 1 ...
                , 'TimerFcn', @(Timer, ~)obj.catchingNotify(Timer, 'beacon_QueryIO') ...
                , 'ErrorFcn', errorFcn);
        end
        
        function start(obj)
            if obj.started
                return
            end
            start(obj.hTimers);
            obj.started = true;
        end
        
        function stop(obj)
            stop(obj.hTimers);
            obj.started = false;
        end
        
        function delete(obj)
            try
                obj.stop();
                delete(obj.hTimers);
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end
        end
        
        function catchingNotify(obj, Timer, event)
            try
                obj.notify(event);
            catch ME
                Timer.UserData.ME = ME;
                rethrow(ME);
            end
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

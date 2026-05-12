classdef DelayedEventListener < handle    
    properties
        delay;
        enabled = true;
    end
    
    properties (Access = private)
       hDelayTimer;
       delayTimerRunning = false;
       lastDelayFunctionCall (1,1) uint64 {} = 0;
       functionHandle;
       hListener;
       evtList = {};
    end
    
    methods
        function obj = DelayedEventListener(delay,varargin)            
            obj.hDelayTimer = timer(...
                'TimerFcn',@(varargin)false,...
                'StopFcn',@obj.timerCallback,...
                'BusyMode','drop',...
                'ExecutionMode','singleShot',...
                'StartDelay',1,... % overwritten later
                'ObjectVisibility','off');
            
            obj.delay = delay;
            obj.hListener = addlistener(varargin{:});
            
            obj.functionHandle = obj.hListener.Callback;
            obj.hListener.Callback = @(varargin)obj.delayFunction(varargin{:});
            
            listenerSourceNames = strjoin(cellfun(@(src)class(src),obj.hListener.Source,'UniformOutput',false));
            set(obj.hDelayTimer,'Name',sprintf('Delayed Event Listener Timer %s:%s',listenerSourceNames,obj.hListener.EventName));
        end
        
        function delete(obj)
            obj.hDelayTimer.StopFcn = []; % stop will be called when deleting the timer. Avoid the stop function
            most.idioms.safeDeleteObj(obj.hListener);
            most.idioms.safeDeleteObj(obj.hDelayTimer);
        end
    end
    
    methods
        function delayFunction(obj,src,evt)
            if obj.enabled
                % restart timer
                obj.lastDelayFunctionCall = tic();
                obj.evtList{end+1} = evt;
                if ~obj.delayTimerRunning
                    obj.hDelayTimer.StartDelay = obj.delay;
                    obj.delayTimerRunning = true;
                    start(obj.hDelayTimer);
                end 
            end
        end
        
        function timerCallback(obj,varargin)
            try
                dt = toc(obj.lastDelayFunctionCall);
                newDelay = obj.delay-dt;
                
                if newDelay > 0
                    % rearm timer
                    newDelay = (ceil(newDelay*1000)) / 1000; % timer delay is limited to 1ms precision
                    obj.hDelayTimer.StartDelay = newDelay;
                    start(obj.hDelayTimer);
                else
                    % execute delayed callback
                    obj.delayTimerRunning = false;
                    if ~isempty(obj.evtList)
                        eL = obj.evtList;
                        obj.evtList = {};
                        obj.executeFunctionHandle(obj.hListener.Source,eL);
                    end
                end
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end
        end
        
        function executeFunctionHandle(obj,varargin)
            try
                obj.functionHandle(varargin{:});
            catch ME
                msg = sprintf('Error occured while handling an event. The last command may not have produced the expected behavior.\nError message: %s', ME.message);
                most.ErrorHandler.logAndReportError(ME, msg);
            end
        end
        
        function flushEvents(obj)
            stop(obj.hDelayTimer);
            obj.delayTimerRunning = false;
            if ~isempty(obj.evtList)
                try
                    eL = obj.evtList;
                    obj.evtList = {};
                    obj.executeFunctionHandle(obj.hListener.Source,eL);
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
        end
    end
    
    methods
        function set.delay(obj,val)
            validateattributes(val,{'numeric'},{'scalar','positive','nonnan','finite'});
            val = (ceil(val*1000)) / 1000; % timer delay is limited to 1ms precision
            obj.delay = val;
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

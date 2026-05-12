function initTimer(obj)
    % INITTIMER initializes and constructs the timer object. Do not call this method more than once
    % as it may create memory leaks.
    
    import dabs.scientifica.motion8.Emitter;
    
    timerErrorFcn = @(Timer,Event)fprintf(2 ...
        , 'Error in Timer %s\n\n%s\n', Timer.Name, Event.Data.message);
    obj.asyncTimerTag = sprintf('M8D-%X', uint64(floor(rand() * 1e16)));
    UserData = struct( ...
        'DotNetDevice', obj.Inner ...
        , 'ME', [] ...
        , 'mode', 'awaitMove' ...
        , 'goCount', 0 ...
        , 'stopCount', 0 ...
        , 'DoneFcn', [] ...
        , 'Emitter', Emitter() ...
        );
    timer(...
        'ErrorFcn', timerErrorFcn ...
        , 'ExecutionMode', 'fixedSpacing' ...
        , 'Name', 'Motion8 Device Timer' ...
        , 'ObjectVisibility', 'off' ...
        , 'Period', 0.001 ...
        , 'Tag', obj.asyncTimerTag ...
        , 'TimerFcn', @timerFcn ...
        , 'StopFcn', @resetTimer ...
        , 'UserData', UserData ...
        );
    obj.TimerDoneListener = UserData.Emitter.listener('Event', @(~,~)unsetWaitFlag(obj));
end

function unsetWaitFlag(obj)
    obj.isWaitingOnMove = false;
end

function resetTimer(Timer, ~)
    NewUserData = struct( ...
        'DotNetDevice', Timer.UserData.DotNetDevice ...
        , 'ME', [] ...
        , 'mode', 'awaitMove' ...
        , 'goCount', 0 ...
        , 'stopCount', 0 ...
        , 'DoneFcn', Timer.UserData.DoneFcn ...
        , 'Emitter', Timer.UserData.Emitter ...
        );
    Timer.UserData = NewUserData;
    Timer.UserData.Emitter.emit();
end

function timerFcn(Timer, ~)
    Device = Timer.UserData.DotNetDevice;
    timeoutSeconds = 0.3;
    switch Timer.UserData.mode
        case 'awaitMove'
            if Device.IsMoving || Timer.UserData.goCount * Timer.Period >= timeoutSeconds
                Timer.UserData.mode = 'awaitStop';
                timerFcn(Timer);
            else
                Timer.UserData.goCount = Timer.UserData.goCount + 1;
            end
        case 'awaitStop'
            if Device.IsMoving
                Timer.UserData.stopCount = Timer.UserData.stopCount + 1;
            else
                if ~isempty(Timer.UserData.DoneFcn)
                    Timer.UserData.DoneFcn();
                end
                stop(Timer);
            end
        otherwise
            error('invalid mode %s', Timer.UserData.mode);
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

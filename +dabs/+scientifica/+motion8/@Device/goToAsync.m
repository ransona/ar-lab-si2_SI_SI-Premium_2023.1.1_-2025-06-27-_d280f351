function goToAsync(obj, varargin)
    import dabs.scientifica.motion8.serializeUm;
    import dabs.scientifica.motion8.Axis;
    most.idioms.mustBeValidObj(obj);
    assert(isscalar(obj), 'obj must be scalar');
    p = inputParser;
    Axes = [Axis.X, Axis.Y, Axis.Z];
    Position = struct('X', 0, 'Y', 0, 'Z', 0);
    LastPosition = obj.getLastPosition();
    for iA = 1:length(Axes)
        axisName = char(Axes(iA));
        if isfield(LastPosition, char(axisName))
            Position.(axisName) = LastPosition.(axisName);
        end
    end
    p.addParameter('X', Position.X, @(x)isnumeric(x) && isreal(x) && isscalar(x));
    p.addParameter('Y', Position.Y, @(x)isnumeric(x) && isreal(x) && isscalar(x));
    p.addParameter('Z', Position.Z, @(x)isnumeric(x) && isreal(x) && isscalar(x));
    p.addParameter('Callback', []);
    p.parse(varargin{:});
    Position = struct( ...
        'X', serializeUm(p.Results.X) ...
        , 'Y', serializeUm(p.Results.Y) ...
        , 'Z', serializeUm(p.Results.Z) ...
        );
    
    callback = @(AsyncResult)moveCallback(obj, AsyncResult, p.Results.Callback);
    assert(~obj.isMoving() && ~obj.isWaitingOnMove ...
        , 'stage is still moving. please wait warmly.');
    obj.isWaitingOnMove = true;
    obj.MoveDelegate.BeginInvoke(Position.X, Position.Y, Position.Z, callback, []);
end

function moveCallback(obj, AsyncResult, callback)
    obj.MoveDelegate.EndInvoke(AsyncResult);
    Timer = obj.getTimer();
    Timer.UserData.DoneFcn = callback;
    start(Timer);
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

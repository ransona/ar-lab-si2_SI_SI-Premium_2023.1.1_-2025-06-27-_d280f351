function registerClickFunction(Control, varargin)
    % REGISTERCLICKFUNCTION Registers a single or double click function to
    % the given control.
    %   REGISTERCLICKFUNCTION(H) registers two empty callbacks for
    %   single and double clicks for control object H, switching out 
    %   the property named `Callback` after 0.5 seconds.
    %
    %   REGISTERCLICKFUNCTION(__, 'ControlCallbackPropertyName', name) sets
    %   the expected property name to assign the control callbacks to.
    %   Default is `Callback`.
    %
    %   REGISTERCLICKFUNCTION(__, 'SingleClickCallback', callback) assigns
    %   the callback called on detected single-click. Default is an empty
    %   callback.
    %
    %   REGISTERCLICKFUNCTION(__, 'DoubleClickCallback', callback) assigns
    %   the callback called on detected double-click. Default is an empty
    %   callback.
    %
    %   REGISTERCLICKFUNCTION(__, 'DoubleClickTimeWindow_Seconds', S) sets
    %   the double-click detection timeout. When the elapsed time exceeds
    %   the set time, the single-click callback is called. If a click is
    %   registered before then, the double-click callback is called.
    %   Default is 0.5 seconds.

    assert(isscalar(Control) && isvalid(Control), 'Argument `Control` must be a valid object');
    callbackValidation = @(callback)assert(isa(callback, 'function_handle') ...
        || (iscell(callback) && ~isempty(callback) && isa(callback{1}, 'function_handle')));
    Parser = inputParser;
    Parser.addParameter('ControlCallbackPropertyName', 'Callback' ...
        , @(n)validateattributes(n, {'char', 'string'}, {'scalartext'}));
    Parser.addParameter('SingleClickCallback', @(~,~)[], callbackValidation);
    Parser.addParameter('DoubleClickCallback', @(~,~)[], callbackValidation);
    Parser.addParameter('DoubleClickTimeWindow_Seconds', 0.5 ...
        , @(s)validateattributes(s, {'numeric'}, {'scalar', 'finite', 'nonnan', 'positive'}));
    Parser.parse(varargin{:});

    Parameters = Parser.Results;
    if ~isempty(Control.(Parameters.ControlCallbackPropertyName))
        warning('ScanImage:Most:Gui:CallbackOverwrite' ...
            , ['A non-empty object was detected in Control.(%s). ' ...
            'It will be overwritten by the set callbacks.'] ...
            , Parameters.ControlCallbackPropertyName);
    end
    Control.(Parameters.ControlCallbackPropertyName) = {@mouseClickFunction, Parameters};
end

function catchAndReportTimerErrors(Timer, EventData, callback)
    try
        evaluateCallback(Timer, EventData, callback);
    catch ME
        Timer.UserData.MException = ME;
        rethrow(ME);
    end
end

function mouseClickFunction(Control, ClickEvent, Parameters)
    timerCallback = {@singleClickFunction, Control, ClickEvent, Parameters};
    timerErrorFunction = @(Timer,~)fprintf(2, '%s\n', Timer.UserData.MException.message);
    SingleClickTimer = timer(...
        'Name', 'Click Detection Timer' ...
        , 'StartDelay', Parameters.DoubleClickTimeWindow_Seconds ...
        , 'ErrorFcn', timerErrorFunction ...
        , 'TimerFcn', {@catchAndReportTimerErrors, timerCallback} ...
        , 'StopFcn', @(Timer,~)delete(Timer) ...
        , 'UserData', struct(MException = []) ...
        , 'ObjectVisibility', 'off');
    Control.(Parameters.ControlCallbackPropertyName) = {@doubleClickFunction ...
        , SingleClickTimer, Parameters};
    SingleClickTimer.start();
end

function evaluateCallback(Source, Event, callback)
    if iscell(callback)
        assert(isa(callback{1}, 'function_handle') ...
            , ['cell callbacks must contain a valid function handle ' ...
            'as its first argument']);
        callback = [callback(1), {Source, Event}, callback(2:end)];
    else
        assert(isa(callback, 'function_handle') ...
            , 'non-cell callbacks must be valid function handles');
        callback = {callback, Source, Event};
    end
    feval(callback{:});
end

function singleClickFunction(~, ~, Control, ClickEvent, Parameters)
    % reset button down function
    Control.(Parameters.ControlCallbackPropertyName) = {@mouseClickFunction, Parameters};
    evaluateCallback(Control, ClickEvent, Parameters.SingleClickCallback);
end

function doubleClickFunction(Control, ClickEvent, SingleClickTimer, Parameters)
    % cancel and delete the timer object.
    SingleClickTimer.stop();
    % reset button down function
    Control.(Parameters.ControlCallbackPropertyName) = {@mouseClickFunction, Parameters};
    evaluateCallback(Control, ClickEvent, Parameters.DoubleClickCallback);
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

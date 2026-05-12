function varargout = figure(varargin)
    try
        varargout = cell(1,nargout);
        [varargout{:}] = builtin('figure', varargin{:});
        if 0 == nargout
            return;
        end

        Figure = varargout{1};

        if any(strcmpi(varargin, 'HandleVisibility'))
            optionalWarning('ScanImage:IdiomFigure:ShouldNotChangeVisibility' ...
                , ['You should not normally need to modify the handle visibility when using ' ...
                , '`most.idioms.figure`.']);
        else
            set(Figure, 'HandleVisibility', 'callback');
        end

        if ~any(strcmpi(varargin, 'MenuBar'))
            set(Figure, 'MenuBar', 'none');
        end

        if ~any(strcmpi(varargin, 'ToolBar'))
            set(Figure, 'ToolBar', 'none');
        end

        if ~any(strcmpi(varargin, 'DockControls'))
            set(Figure, 'DockControls', 'off');
        end

        if ~any(strcmpi(varargin, 'NumberTitle'))
            set(Figure, 'NumberTitle', 'off');
        end
    catch ME
        ME.throwAsCaller();
    end
end

function optionalWarning(id, message)
    linkMessage = 'here';
    link = sprintf('<a href="matlab: warning(''off'', ''%s'')">%s</a>', id, linkMessage);
    disableMessage = sprintf('If you wish to temporarily disable this warning, click %s.', link);
    warning(id, '%s\n\n%s', message, disableMessage);
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

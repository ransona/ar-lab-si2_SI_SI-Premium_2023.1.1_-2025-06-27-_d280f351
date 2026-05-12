function initGui(obj, KeywordResults)
    assert(most.idioms.isValidObj(KeywordResults.Parent));
    [Axes, obj.Axes] = deal(most.idioms.axes(KeywordResults.Parent ...
        , 'XTick', [], 'YTick', [], 'XTickLabel', {}, 'YTickLabel', {}...
        , 'XLim', [0, 1], 'YLim', [0, 1] ...
        , 'XColor', 'none', 'YColor', 'none', 'Color', 'none' ...
        , 'DataAspectRatio', [1, 1, 1]));
    Axes.Toolbar.Visible = 'off';
    obj.Rectangle = rectangle(Axes...
        , 'FaceColor', 'k' ...
        , 'EdgeColor', 'k' ...
        , 'LineWidth', 0.1 ...
        , 'Curvature', [1, 1]);

    obj.Color = KeywordResults.Color;
    if ~isempty(KeywordResults.Position)
        obj.Position = KeywordResults.Position;
    end
    
    % bind to parent lifetime
    obj.LifetimeListener = addlistener(KeywordResults.Parent ...
        , 'ObjectBeingDestroyed', @(~,~)delete(obj));
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

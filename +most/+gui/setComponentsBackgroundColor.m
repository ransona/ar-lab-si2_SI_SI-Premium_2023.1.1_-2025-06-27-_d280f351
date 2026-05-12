function setComponentsBackgroundColor(hComponents,color)
    arguments
        hComponents
        color char {mustBeMember(color,{'red' 'blue' 'green' 'yellow' 'gray', 'background'})}
    end

    try
        assert(all(isprop(hComponents,'BackgroundColor')),'Background Color is not property of all hComponents');

        hFig = ancestor(hComponents(1),'figure');

        if strcmpi(color,'background')
            color = hFig.Color;
            if isa(hComponents,'matlab.ui.control.UIControl')
                color = round(color,1); % Don't ask me why this works
            end
            set(hComponents,BackgroundColor = color);
            return;
        end


        if isprop(hFig,'Theme') && ~isempty(hFig.Theme) && isprop(hFig.Theme,'BaseColorStyle') && strcmpi(hFig.Theme.BaseColorStyle,'dark')
            color(1) = upper(color(1));
            color = ['dark' color];
            set(hComponents,BackgroundColor = most.constants.Colors.(color));
        else
            color(1) = upper(color(1));
            color = ['light' color];
            set(hComponents,BackgroundColor = most.constants.Colors.(color));
        end
    catch ME
        most.ErrorHandler.logAndReportError(ME);
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

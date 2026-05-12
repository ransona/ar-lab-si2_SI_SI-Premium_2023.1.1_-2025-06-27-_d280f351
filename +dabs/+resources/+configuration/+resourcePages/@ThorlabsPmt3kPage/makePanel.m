function makePanel(obj, GuiParent)
    % https://undocumentedmatlab.com/articles/matlab-layout-managers-uicontainer-and-relatives
    % for uigridcontainer objects
    
    %% Identifier Grid
    % Wavelength and Serial number selector
    
    % label, interactible, response
    IdentifierFlow = uiflowcontainer('v0', 'Parent', GuiParent, 'FlowDirection', 'TopDown');
    IdentifierGrid = uigridcontainer('v0', 'Parent', IdentifierFlow ...
        , 'GridSize', [3, 3], 'HorizontalWeight', [2, 3, 3] ...
        , 'Units', 'points', 'Margin', 1);
    set(IdentifierGrid, 'HeightLimits', [86, 86]);
    
    % wavelength row
    most.gui.staticText('Parent', IdentifierGrid ...
        , 'String', 'Wavelength (nm):' ...
        , 'HorizontalAlignment', 'right' ...
        );
    obj.WavelengthEdit = uicontrol(IdentifierGrid ...
        , 'Style', 'edit' ...
        , 'UserData', struct('DisplayFormat', '%.3f nm') ...
        , 'Callback', @(Edit,~)formatAndUpdateWavelengthString(obj, Edit.String));
    LampFlow = uiflowcontainer('v0', 'Parent', IdentifierGrid, 'FlowDirection', 'LeftToRight');
    obj.WavelengthColorPanel = uipanel(LampFlow, 'BorderType', 'line', 'HighlightColor', 'k');
    set(obj.WavelengthColorPanel, 'Units', 'points', 'WidthLimits', [30, 30]);
    
    % serial number row
    most.gui.staticText('Parent', IdentifierGrid ...
        , 'HorizontalAlignment', 'right'...
        , 'String', 'Serial Number:' ...
        );
    
    CenteredPopup = uigridcontainer('v0', 'Parent', IdentifierGrid ...
        , 'GridSize', [3, 1], 'VerticalWeight', [1, 2, 1] ...
        , 'Margin', 0.1 ...
        );
    uipanel(CenteredPopup, 'BorderType', 'none'); % filler
    obj.DeviceDropdown = uicontrol(CenteredPopup ...
        , 'Style', 'popupmenu' ...
        , 'String', " " ... % populated by redraw.
        );
    
    obj.DetectorLabel = most.gui.staticText('Parent', IdentifierGrid ...
        , 'String', 'N/A' ...
        , 'FontSize', 10, 'FontWeight', 'bold' ...
        , 'HorizontalAlignment', 'left' ...
        );
    
    % auto on row
    most.gui.staticText('Parent', IdentifierGrid ...
        , 'String', 'Auto-Enable:' ...
        , 'HorizontalAlignment', 'right' ...
        );
    
    obj.AutoOnCheckbox = uicontrol(IdentifierGrid ...
        , 'Style', 'checkbox' ...
        , 'Tooltip', 'i.e. AutoOn. Enable the PMT whenever acquisition is started.' ...
        );
end

function formatAndUpdateWavelengthString(obj, valueString)
    if endsWith(valueString, 'nm')
        valueString = extractBefore(valueString, 'nm');
    end
    valueString = strtrim(valueString);
    value = str2double(valueString);
    if isnan(value)
        value = obj.WavelengthEdit.Value; % revert changes;
    end
    obj.updateWavelength(value);
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

function makePanel(obj, parent)
    downFlow = uiflowcontainer('v0', Parent = parent, FlowDirection = 'TopDown');
    headerFlow = uiflowcontainer('v0' ...
        , Parent = downFlow ...
        , Units = 'pixels' ...
        , FlowDirection = 'LeftToRight' ...
        );
    set(headerFlow, HeightLimits = [50, 50]);
    
    % COM dropdown styling
    comPanel = uipanel(headerFlow ...
        , BorderType = 'none' ...
        , Units = 'pixels' ...
        , UserData = struct(Columns = []) ...
        , SizeChangedFcn = @onComResize ...
        );
    set(comPanel, WidthLimits = [200, 200]);
    comLabel = uicontrol(comPanel ...
        , Style = 'text' ...
        , String = 'COM port:' ...
        , FontSize = 9 ...
        , Units = 'pixels' ...
        , HorizontalAlignment = 'right' ...
        );
    comLabel.Position(4) = 15;
    obj.ComDropdown = uicontrol(comPanel ...
        , Style = 'popupmenu' ...
        , String = " " ...
        , Value = 1 ...
        , Units = 'pixels' ...
        );
    obj.ComDropdown.Position(3) = 120;
    comPanel.UserData.Columns = [comLabel, obj.ComDropdown];
    
    % hardware info
    obj.HardwareInfoLabel = uicontrol(headerFlow ...
        , Style = 'text' ...
        , FontWeight = 'bold' ...
        , FontSize = 10 ...
        , String = "" ...
        , HorizontalAlignment = 'left' ...
        , Units = 'pixels' ...
        );
    
    % Axes panel
    lrFlow = uiflowcontainer('v0', Parent = downFlow, FlowDirection = 'LeftToRight');
    
    userData = struct(ColumnWeights = [1, 1, 1, 2, 1], Rows = matlab.ui.control.UIControl.empty());
    mainPanel = uipanel(lrFlow ...
        , Title = 'Main' ...
        , UserData = userData ...
        , SizeChangedFcn = @onAxisResize ...
        , Units = 'pixels' ...
        , BorderType = 'line' ...
        );
    tableFlow = uiflowcontainer('v0', Parent = mainPanel, FlowDirection = 'TopDown');
    rowHeightLim = [50 50];
    
    rowFlow = uiflowcontainer('v0', Parent = tableFlow, FlowDirection = 'LeftToRight');
    set(rowFlow, 'HeightLimits', rowHeightLim);
    headerRow = uipanel(rowFlow, Units = 'pixels', BorderType = 'none');
    axisLabel = uicontrol(headerRow, Style = 'text', String = 'Axis');
    enabledLabel = uicontrol(headerRow, Style = 'text', String = 'Enabled');
    joystickLabel = uicontrol(headerRow, Style = 'text', String = 'Joystick');
    motorLabel = uicontrol(headerRow, Style = 'text', String = 'Label');
    statusLabel = uicontrol(headerRow, Style = 'text', String = 'Status');
    headerColumns = [axisLabel, enabledLabel, joystickLabel, motorLabel, statusLabel];
    set(headerColumns ...
        , Units = 'pixels' ...
        , FontWeight = 'bold' ...
        , Position = [0, 0, 70, 40] ...
        );
    headerRow.UserData.Columns = headerColumns;
    
    for iRow = 1:3
        rowFlow = uiflowcontainer('v0', Parent = tableFlow, FlowDirection = 'LeftToRight');
        set(rowFlow, 'HeightLimits', rowHeightLim);
        row = uipanel(rowFlow, Units = 'pixels', BorderType = 'none');
        axisIndex = uicontrol(row ...
            , Style = 'text' ...
            , String = num2str(iRow) ...
            , FontWeight = 'bold' ...
            , Tooltip = "The index which matches the MCM301 control box" ...
            );
        enabledCheckbox = uicontrol(row, Style = 'checkbox', Units = 'pixels');
        enabledCheckbox.Position(3) = 20;
        joyButton = uicontrol(row ...
            , Style = 'pushbutton' ...
            , String = char([0xD83D, 0xDD06]) ... % 
            , FontWeight = 'bold' ...
            , Units = 'pixels' ...
            , Tooltip = sprintf("Briefly blink the LED located on joystick labelled %d", iRow) ...
            , Callback = @onJoyClick ...
            , UserData = struct(Model = obj.hResource, MotorIndex = iRow) ...
            );
        joyButton.Position(3:4) = 40;
        label = uicontrol(row, Style = 'text', Units = 'pixels');
        label.Position(3) = 80;
        status = uicontrol(row ...
            , Style = 'text' ...
            , String = char(0x2753) ... % ❓see redraw()
            , Enable = 'inactive' ...
            );
        columns = [axisIndex, enabledCheckbox, joyButton, label, status];
        set(columns, Units = 'pixels', FontSize = 12);
        obj.AxisPanels(iRow) = row;
        obj.EnabledCheckboxes(iRow) = enabledCheckbox;
        obj.JoystickBlinkButtons(iRow) = joyButton;
        obj.AxisLabels(iRow) = label;
        obj.StatusLabels(iRow) = status;
        row.UserData.Columns = columns;
        mainPanel.UserData.Rows(iRow) = row;
    end
    mainPanel.UserData.Rows(4) = headerRow;
end

function onJoyClick(button, ~)
    if isempty(button) || ~isvalid(button)
        return;
    end
    model = button.UserData.Model;
    if isempty(model) || ~isvalid(model)
        return;
    end
    mcm = model.Controller;
    if isempty(mcm) || ~isvalid(mcm)
        return;
    end
    mcm.blinkJoystick(button.UserData.MotorIndex);
end

function onComResize(panel, ~)
    if isempty(panel) || ~isvalid(panel)
        return;
    end
    columns = panel.UserData.Columns;
    columnWidths = zeros(size(columns));
    for iCol = 1:numel(columns)
        columnWidths(iCol) = columns(iCol).Position(3);
    end
    margin = 1;
    offsets = (cumsum(columnWidths) - columnWidths) + (margin .* (1:(numel(columnWidths))));
    panelHeight = panel.Position(4);
    for iCol = 1:numel(columns)
        col = columns(iCol);
        colHeight = col.Position(4);
        col.Position(2) = (panelHeight / 2) - (colHeight / 2);
        col.Position(1) = offsets(iCol);
    end
end

function onAxisResize(panel, ~)
    if isempty(panel) || ~isvalid(panel)
        return;
    end
    weights = panel.UserData.ColumnWeights;
    assert(isvector(weights));
    rows = panel.UserData.Rows;
    colTotal = sum(weights);
    assert(colTotal > 0);
    
    margin = 1;
    width = panel.Position(3) - (2 * margin);
    cellSize = width / colTotal;
    colSizes = weights .* cellSize;
    offsetSizes = cumsum(colSizes) - colSizes;
    colOffsets = (margin .* (1:numel(weights))) + offsetSizes;
    centerOffsets = (colSizes ./ 2) + colOffsets;
    if isempty(rows)
        return;
    end
    rowCenter = rows(1).Position(4) / 2;
    for iRow = 1:numel(rows)
        row = rows(iRow);
        columns = row.UserData.Columns;
        assert(numel(columns) <= numel(weights));
        for iCol = 1:numel(columns)
            item = columns(iCol);
            itemWidth = item.Position(3);
            itemHeight = item.Position(4);
            offset = centerOffsets(iCol) - (itemWidth / 2);
            item.Position(1:2) = [offset, (rowCenter - (itemHeight / 2))];
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

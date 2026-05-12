classdef Meadowlark1024SLMv2Page < dabs.resources.configuration.ResourcePage
    properties
        PopupmenuPathLUT;
        FlowBoardSelect;
    end

    methods
        function obj = Meadowlark1024SLMv2Page(resource, GUIParent)
            obj@dabs.resources.configuration.ResourcePage(resource, GUIParent);
        end
    end

    methods %% dabs.resources.configuration.ResourcePage
        function makePanel(obj, GUIParent)
            flowColumn = uiflowcontainer('v0', 'Parent', GUIParent, 'FlowDirection', 'TopDown');
            grid = uigridcontainer('v0', 'Parent', flowColumn, 'GridSize', [1, 2], 'HorizontalWeight', [1, 1.5]);
            set(grid, 'HeightLimits', [60, 60]);

            %% lookup table file
            gridCentering = uigridcontainer('v0', 'Parent', grid ...
                , 'GridSize', [3, 1], 'VerticalWeight', [1.6, 2, 1] ...
                , 'Margin', 0.1);
            uiflowcontainer('v0', 'Parent', gridCentering);
            uicontrol('Parent', gridCentering, 'Style', 'text', 'String', 'Lookup Table File (*.lut):' ...
                , 'HorizontalAlignment', 'right', 'FontWeight', 'bold');

            gridCentering = uigridcontainer('v0', 'Parent', grid ...
                , 'GridSize', [3, 1], 'VerticalWeight', [1, 2, 1] ...
                , 'Margin', 0.1);
            uiflowcontainer('v0', 'Parent', gridCentering);
            flowRow = uiflowcontainer('v0', 'Parent', gridCentering, 'FlowDirection', 'LeftToRight');
            obj.PopupmenuPathLUT = uicontrol('Parent', flowRow, 'Style', 'popupmenu' ...
                , 'String', {'<none>'}, 'Value', 1);
            buttonBrowse = uicontrol('Parent', flowRow, 'Style', 'pushbutton'...
                , 'String', most.constants.Unicode.open_file ...
                , 'Callback', @obj.callbackButtonPushBrowse);
            set(buttonBrowse, 'WidthLimits', [40, 40]);

            panel = uipanel('Parent', flowColumn, 'Title', 'Detected Boards ([Board Index] Serial Number)');
            obj.FlowBoardSelect = uiflowcontainer('v0', 'Parent', panel, 'FlowDirection', 'TopDown');
        end

        function redraw(obj)
            if isempty(obj.hResource.PathFileLUT)
                obj.PopupmenuPathLUT.Value = 1;
            else
                indexFileLUT = find(contains(obj.PopupmenuPathLUT.String, obj.hResource.PathFileLUT), 1);
                if isempty(indexFileLUT)
                    obj.PopupmenuPathLUT.String{end+1} = obj.hResource.PathFileLUT;
                    obj.PopupmenuPathLUT.Value = numel(obj.PopupmenuPathLUT.String);
                else
                    obj.PopupmenuPathLUT.Value = indexFileLUT;
                end
            end

            serialNumbers = dabs.meadowlark.slm1024v2.getBoards();
            delete(obj.FlowBoardSelect.Children);
            for i = 1:numel(serialNumbers)
                uicontrol('Parent', obj.FlowBoardSelect ...
                    , 'Style', 'radiobutton' ...
                    , 'String', sprintf('[%d] %d', i, serialNumbers(i)) ...
                    , 'FontSize', 12 ...
                    , 'Callback', @obj.callbackSelectBoard ...
                    , 'Value', 0);
            end
            set(obj.FlowBoardSelect.Children, 'HeightLimits', [20, 20]);

            if ~isempty(serialNumbers) && ~isempty(obj.hResource.IndexBoard)
                obj.FlowBoardSelect.Children(obj.hResource.IndexBoard).Value = 1;
            end
        end

        function apply(obj)
            if 1 == obj.PopupmenuPathLUT.Value
                obj.hResource.PathFileLUT = '';
            else
                obj.hResource.PathFileLUT = obj.PopupmenuPathLUT.String{obj.PopupmenuPathLUT.Value};
            end

            obj.hResource.IndexBoard = [];
            for i = 1:numel(obj.FlowBoardSelect.Children)
                radioButton = obj.FlowBoardSelect.Children(i);
                if radioButton.Max == radioButton.Value
                    obj.hResource.IndexBoard = i;
                    break;
                end
            end
            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end

        function remove(obj)
            obj.hResource.deleteAndRemoveMdfHeading();
        end
    end

    methods (Access = private)
        function callbackButtonPushBrowse(obj, ~, ~)
            if isempty(obj) || ~isvalid(obj)
                return;
            end
            if 1 == obj.PopupmenuPathLUT.Value
                dirDefault = fileparts(which('scanimage'));
            else
                dirDefault = fileparts(obj.PopupmenuPathLUT.String{obj.PopupmenuPathLUT.Value});
            end
            [fileName, dirLocation] = uigetfile({'*.lut', '*.LUT'} ...
                , 'Select a valid LUT file to load into the SLM.', dirDefault);
            pathFileLUT = fullfile(dirLocation, fileName);
            maskLutExists = contains(obj.PopupmenuPathLUT.String, pathFileLUT);
            if any(maskLutExists)
                obj.PopupmenuPathLUT.Value = find(maskLutExists, 1);
                return;
            end
            obj.PopupmenuPathLUT.String{end+1} = pathFileLUT;
            obj.PopupmenuPathLUT.Value = numel(obj.PopupmenuPathLUT.String);
        end

        function callbackSelectBoard(obj, selected, ~)
            if isempty(obj) || ~isvalid(obj)
                return;
            end
            for i = 1:numel(obj.FlowBoardSelect.Children)
                radioButton = obj.FlowBoardSelect.Children(i);
                if radioButton.Value == radioButton.Max
                    if selected == radioButton
                        continue;
                    end
                    radioButton.Value = radioButton.Min;
                end
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

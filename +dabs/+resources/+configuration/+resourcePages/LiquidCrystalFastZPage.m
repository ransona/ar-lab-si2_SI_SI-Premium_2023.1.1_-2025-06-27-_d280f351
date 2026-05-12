classdef LiquidCrystalFastZPage < dabs.resources.configuration.ResourcePage
    properties
        pmhAOControl
        pmObjective
        hTable
        tableDataStruct
        etDistanceVoltsOffset
        etParkPosition
    end
    
    methods
        function obj = LiquidCrystalFastZPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)	
                most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [20 55 120 20],'Tag','txhAOControl','String','Control Channel','HorizontalAlignment','right');
                obj.pmhAOControl  = most.gui.uicontrol('Parent',hParent,'Style','popupmenu','String',{''},'RelPosition', [150 52 120 20],'Tag','pmhAOControl');

                most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [20 77 120 20],'Tag','txObjective','String','Objective','HorizontalAlignment','right');
                obj.pmObjective  = most.gui.uicontrol('Parent',hParent,'Style','popupmenu','String',{''},'RelPosition', [150 77 120 20],'Tag','pmObjective','callback',@(src,evt)obj.objectiveChanged(src,evt));

                ttStr = sprintf('Values loaded in table are default for the four available objectives.\n Table can be edited if user does their own calibration\n\n E.g. with pollen slide moving stage while doing a fastZ stack to record pollen slide depths at different slices.');
                most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [20.6666666666667 100.666666666667 170 13],'Tag','txTable','String','Calibrated Position Table (optional)','HorizontalAlignment','right','tooltip',ttStr);
                obj.hTable = most.gui.uicontrol('Parent',hParent,'Style','uitable','ColumnFormat',{'numeric','numeric'},'ColumnEditable',[false,true,true,false],'ColumnName',{'Slice #' 'Position [um]','Voltage [V]' 'Delete',},...
                    'ColumnWidth',{50 80 80 40},'RowName',[],'RelPosition', [24.0000000000004 218.333333333333 270 110],'Tag','tablePositions',...
                    'CellSelectionCallback',@(src,evt)obj.tableCellSelection(src,evt),'CellEditCallback',@(src,evt)obj.tableCellEdit(src,evt));

                obj.tableDataStruct = obj.hResource.data;

                most.gui.uicontrol('Parent',hParent,'Style','text','RelPosition', [13.3333333333333 250 120 20],'Tag','txParkPosition','String','Park position [um]','HorizontalAlignment','right');
                toolTipString = sprintf(['Position where the actuator should be when not acquiring.\n\nIt is highly recommended to leave this at zero microns and\n set travel range and voltage offset such that\n' ...
                    '0 um is the middle of the actuator''s range']);
                obj.etParkPosition = most.gui.uicontrol('Parent',hParent,'Style','edit','RelPosition', [150 247 120 20],'Tag','etParkPosition','tooltip',toolTipString);           
        end
        
        function redraw(obj)
            hAOs = obj.hResourceStore.filterByClass(?dabs.resources.ios.AO);
            obj.pmhAOControl.String = [{''}, hAOs];
            obj.pmhAOControl.pmValue = obj.hResource.hAOControl;

            obj.pmObjective.String = obj.hResource.OBJECTIVES;
            obj.pmObjective.pmValue = obj.hResource.objective;

            data = obj.hResource.data;
            obj.redrawTable(data);

            obj.etParkPosition.String = num2str(obj.hResource.parkPosition);
        end

        function tableCellSelection(obj,src,evt)
            if isempty(evt.Indices)
                return;
            end

            row = evt.Indices(1);
            column = evt.Indices(2);
            numRows = size(src.Data,1);
            numColumns = size(src.Data,2);

            if column == numColumns
                src.Data(row,:) = [];
                obj.tableDataStruct.(obj.pmObjective.pmValue).slicePositions = [obj.hTable.Data{:,2}];
                obj.tableDataStruct.(obj.pmObjective.pmValue).sliceVoltages = [obj.hTable.Data{:,3}];
            end

            if row == numRows
                src.Data(end,:) = [{sprintf('Slice %g',numRows)} {[]} {[]} {most.constants.Unicode.ballot_x}];
                src.Data(end+1,:) = [{'+'} {[]} {[]} {[]}];
                return;
            end
        end
        
        function tableCellEdit(obj,src,evt)
            obj.tableDataStruct.(obj.pmObjective.pmValue).slicePositions = [obj.hTable.Data{:,2}];
            obj.tableDataStruct.(obj.pmObjective.pmValue).sliceVoltages = [obj.hTable.Data{:,3}];
        end

        function redrawTable(obj,data)
            data = data.(obj.pmObjective.pmValue);
            numVoltages = length(data.sliceVoltages);
            numPositions = length(data.slicePositions);
            maxNum = max(numVoltages,numPositions);
            data_ = {cell(maxNum+1,4)};
            for idx = 1:maxNum
                data_{idx,1} = sprintf('Slice %g',idx);

                if idx <= numPositions
                    data_{idx,2} = data.slicePositions(idx);
                else
                    data_{idx,2} = [];
                end

                if idx <= numVoltages
                    data_{idx,3} = data.sliceVoltages(idx);
                else
                    data_{idx,3} = [];
                end

                data_{idx,4} = most.constants.Unicode.ballot_x;
            end
            data_(end+1,:) = [{'+'} {[]} {[]} {[]}];
            obj.hTable.Data = data_;
        end

        function objectiveChanged(obj,src,evt)
            obj.redrawTable(obj.tableDataStruct);
        end

        function apply(obj)           
            most.idioms.safeSetProp(obj.hResource,'hAOControl',obj.pmhAOControl.pmValue);
            most.idioms.safeSetProp(obj.hResource,'objective',obj.pmObjective.pmValue);

            most.idioms.safeSetProp(obj.hResource,'data',obj.tableDataStruct);

            most.idioms.safeSetProp(obj.hResource,'parkPosition',str2double(obj.etParkPosition.String));
                        
            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end
        
        function remove(obj)
            obj.hResource.deleteAndRemoveMdfHeading();
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

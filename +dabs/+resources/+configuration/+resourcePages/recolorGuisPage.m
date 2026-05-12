classdef recolorGuisPage < dabs.resources.configuration.ResourcePage
    properties
        tableColors
        previewPanel
        chosenColors = {}
    end
    
    methods
        function obj = recolorGuisPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            obj.tableColors = most.gui.uicontrol('Parent',hParent,'Style','uitable','ColumnFormat',{'char','char'},'ColumnEditable',[false,false],'ColumnName',{'Scanner','Color',},'ColumnWidth',{100 270},'RowName',[],'RelPosition', [5 228 372 227],'Tag','tableColors','CellSelectionCallback', @obj.cellSelectionCallback);
            obj.previewPanel = uipanel('Parent',hParent,'Tag','previewPanel','Position',[0 0 1 0.2]);
        end
        
        function redraw(obj)
            [allScanners,allScannerNames] = obj.hResourceStore.filterByClass('scanimage.components.Scan2D');
            try
                for scannerIdx = 1:numel(allScannerNames)
                    scannerName = allScannerNames{scannerIdx};
                    if obj.hResource.colorMap.isKey(allScannerNames{scannerIdx})
                        obj.chosenColors{scannerIdx} = obj.hResource.colorMap(scannerName);
                    else
                        obj.chosenColors{scannerIdx} = [0.9 0.9 0.9];
                    end
                    
                    colors(scannerIdx) = most.util.rgb('xkcd',obj.chosenColors{scannerIdx});
                end
                
                obj.tableColors.Data = most.idioms.horzcellcat(allScannerNames,colors);
            catch 
                colors = cellfun(@(scanner) 'Grey', allScannerNames, 'UniformOutput', false);
                for i = 1:numel(allScannerNames)
                    obj.chosenColors{i} = [0.9 0.9 0.9];
                end
                obj.tableColors.Data = most.idioms.horzcellcat(allScannerNames',colors');
            end
        end
        
        function apply(obj)
            scannerNames = obj.tableColors.Data(:,1);
            if isempty(scannerNames)
                most.idioms.safeSetProp(obj.hResource,'colorMap',containers.Map.empty(0,1));
            else
                most.idioms.safeSetProp(obj.hResource,'colorMap',containers.Map(scannerNames, obj.chosenColors));
            end
            
            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end
        
        function cellSelectionCallback(obj,~,evt)
            try
                if ~isempty(evt.Indices)
                    row = evt.Indices(1);
                    column = evt.Indices(2);
                    
                    switch column
                        case 1
                            %No-op
                        case 2
                            rgb = uisetcolor;
                            
                            if ~isscalar(rgb)
                                colorStr = most.util.rgb('xkcd',rgb);
                                
                                obj.chosenColors{row} = rgb;
                                obj.tableColors.Data{row,column} = colorStr{1};
                            else
                                return;
                            end
                        otherwise
                            %No-op
                    end
                    obj.previewColor(row,2);
                end
            catch ME
                most.ErrorHandler.logAndReportError(ME);
                warndlg(ME.message);
            end
        end
        
        function previewColor(obj,row,column)
            color = obj.chosenColors{row};
            obj.previewPanel.BackgroundColor = color;
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

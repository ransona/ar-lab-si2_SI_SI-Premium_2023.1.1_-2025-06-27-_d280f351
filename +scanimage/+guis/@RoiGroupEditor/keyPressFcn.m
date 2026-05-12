function keyPressFcn(obj,~,evt)
    if ~isempty(evt.Modifier)
        return
    end

    switch lower(evt.Key)
        case {'a' 'insert'}
            if obj.createMode && obj.cellPickOn
                obj.endCellPick(true);
            elseif obj.createMode && obj.canDrawArray
                obj.drawArray = ~obj.drawArray;
            elseif obj.editorModeIsSlm && obj.slmPatternTypeIsBitmap
                obj.slmBitmapBrushEnable = true;
            else
                obj.newRoi();
            end

        case 'm'
            if obj.createMode
                if obj.cellPickOn
                    [tf, idx] = ismember(obj.cellPickMode,obj.cellPickModes);
                    if ~tf || idx == numel(obj.cellPickModes)
                        obj.cellPickMode = obj.cellPickModes{1};
                    else
                        obj.cellPickMode = obj.cellPickModes{idx + 1};
                    end
                else
                    obj.drawMultipleRois = ~obj.drawMultipleRois;
                end
            end

        case 'c'
            obj.newRoiDrawMode = 'cell picker';
            if ~obj.createMode
                obj.newRoi();
            end

        case 'r'
            if obj.createMode
                switch obj.newRoiDrawMode
                    case {'cell picker' 'center point rectangle'}
                        obj.newRoiDrawMode = 'top left rectangle';

                    case 'top left rectangle'
                        obj.newRoiDrawMode = 'center point rectangle';
                end
            end

        case 'd'
            if obj.createMode && obj.cellPickOn
                obj.pbDilateCell()
            else
                obj.delSelection();
            end

        case 'e'
            if obj.createMode && obj.cellPickOn
                obj.pbErodeCell();
            end

        case 'delete'
            if obj.createMode && obj.cellPickOn
                obj.pbDeleteCell()
            else
                obj.delSelection();
            end

        case 'p'
            if obj.editorModeIsStim
                obj.quickAddPause();
            end

        case 'k'
            if obj.editorModeIsStim
                obj.quickAddPark();
            end

        case {'escape'}
            obj.changeSelection();
            obj.fixTableCheck();

            if obj.editorModeIsSlm && obj.slmPatternTypeIsBitmap
                obj.slmBitmapBrushEnable = false;
            end
        case {'pagedown'}
            j = obj.selectedObjRoiIdx + 1;

            if j > numel(obj.tblData(:,1))
                j = 1;
            end

            obj.tblData(:,1) = {false};
            obj.tblData{j,1} = true;
            obj.roiTable.Data = obj.tblData;

            parObj = obj.tblMapping{j,2};
            if isnumeric(parObj)
                parObj = obj.tblMapping{parObj,1};
            end
            obj.changeSelection(obj.tblMapping{j,1},parObj);
        case {'pageup'}
            j = obj.selectedObjRoiIdx - 1;

            if j < 1
                j = numel(obj.tblData(:,1));
            end

            obj.tblData(:,1) = {false};
            obj.tblData{j,1} = true;
            obj.roiTable.Data = obj.tblData;

            parObj = obj.tblMapping{j,2};
            if isnumeric(parObj)
                parObj = obj.tblMapping{parObj,1};
            end
            obj.changeSelection(obj.tblMapping{j,1},parObj);
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

function roiTableCB(obj,~,evt)
    diff = cellfun(@cmp,obj.tblData,obj.roiTable.Data);

    [j,i] = ind2sub(size(diff),find(~diff,1));
    reset = true;

    if ~isempty(i)
        if i == 1
            % selection column. clear other selections and toggle this one
            if obj.tblData{j,1}
                % Toggling the selected ROI to an unselected ROI
                obj.changeSelection();
                obj.fixTableCheck();
            else
                %Toggling an unselectec ROI to the selected ROI
                obj.tblData(:,1) = {false};
                obj.tblData{j,1} = true;
                obj.roiTable.Data = obj.tblData;

                parObj = obj.tblMapping{j,2};
                if isnumeric(parObj)
                    parObj = obj.tblMapping{parObj,1};
                end
                obj.changeSelection(obj.tblMapping{j,1},parObj);
                reset = false;
            end
        elseif obj.editorModeIsSlm
            switch i
                case 3
                    % X column
                    if ~isnan(evt.NewData)
                        obj.enableListeners = false;
                        obj.editingGroup.rois(j).scanfields.centerXY(1) = evt.NewData / obj.xyUnitFactor;
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        obj.updateSlmPattern();
                        reset = false;
                    end

                case 4
                    % Y column
                    if ~isnan(evt.NewData)
                        obj.enableListeners = false;
                        obj.editingGroup.rois(j).scanfields.centerXY(2) = evt.NewData / obj.xyUnitFactor;
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        obj.updateSlmPattern();
                        reset = false;
                    end

                case 5
                    % Z column
                    if ~isnan(evt.NewData)
                        obj.enableListeners = false;
                        obj.editingGroup.rois(j).moveSfById(1,evt.NewData);
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        obj.updateSlmPattern();
                        reset = false;
                    end

                case 6
                    % Wt column
                    if ~isnan(evt.NewData)
                        obj.enableListeners = false;
                        obj.editingGroup.rois(j).scanfields.powers = evt.NewData;
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        obj.updateSlmPattern();
                        reset = false;
                    end
            end
        elseif obj.editorModeIsStim
            switch i
                case 4
                    % duration
                    d = str2double(evt.NewData);
                    if ~isnan(d)
                        obj.enableListeners = false;
                        obj.editingGroup.rois(j).scanfields.duration = d/1000;
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        obj.selectedObjChanged();
                        reset = false;
                    end

                case 5
                    % reps
                    if ~isnan(evt.NewData)
                        obj.enableListeners = false;
                        obj.editingGroup.rois(j).scanfields.repetitions = evt.NewData;
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        obj.selectedObjChanged();
                        reset = false;
                    end

                case 6
                    % power
                    if ~isnan(evt.NewData)
                        if ischar(evt.NewData)
                            newPowers = str2num(evt.NewData);
                        else
                            newPowers = evt.NewData;
                        end
                        obj.enableListeners = false;
                        obj.editingGroup.rois(j).scanfields.powers = newPowers;
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        obj.selectedObjChanged();
                        reset = false;
                    end

                case 7
                    % z
                    if ~isnan(evt.NewData)
                        obj.enableListeners = false;
                        obj.editingGroup.rois(j).moveSfById(1,evt.NewData);
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        obj.selectedObjChanged();
                        reset = false;
                    end
            end
        else % editor mode is imaging
            switch i
                case 5
                    % enable column

                case 6
                    % display column

                case 7
                    % z column
                    areZsValid = all(~isnan(evt.NewData));
                    if areZsValid && isa(obj.tblMapping{j,1},'scanimage.mroi.scanfield.ScanField')
                        roiIdx = obj.tblMapping{j,2};
                        roi = obj.tblMapping{roiIdx,1};
                        sf = obj.tblMapping{j,1};
                        sfIdx = find(sf == roi.scanfields);

                        obj.enableListeners = false;
                        roi.moveSfById(sfIdx,evt.NewData);
                        obj.enableListeners = true;
                        obj.updateTable();
                        obj.updateScanPathCache();
                        obj.updateDisplay();
                        reset = false;
                    end
            end
        end
    end

    if reset
        obj.roiTable.Data = obj.tblData;
    end
end

function e = cmp(a,b)
    e = strcmp(class(a),class(b));
    if e
        if ischar(a)
            e = strcmp(a,b);
        else
            e = (isempty(a) && (numel(a) == numel(b))) || a == b;
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

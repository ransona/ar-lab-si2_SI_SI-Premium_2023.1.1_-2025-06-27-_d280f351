function updateTable(obj)
    %get the current selection and reapply it
    newSel = 0;

    obj.tblData = {};
    obj.tblMapping = {};
    if most.idioms.isValidObj(obj.editingGroup)
        idx = 1;
        for i = 1:numel(obj.editingGroup.rois)
            if obj.selectedObj == obj.editingGroup.rois(i)
                newSel = idx;
            end

            obj.tblData{idx,1} = newSel == idx;
            obj.tblMapping{idx,1} = obj.editingGroup.rois(i);
            obj.tblMapping{idx,2} = idx;
            obj.tblMapping{idx,3} = obj.editingGroup.rois(i).uuiduint64;

            if obj.editorModeIsSlm
                if ~isempty(obj.editingGroup.rois(i).scanfields)
                    sf = obj.editingGroup.rois(i).scanfields(1);

                    if obj.selectedObj == sf
                        obj.tblData{idx,1} = true;
                        newSel = idx;
                    end

                    obj.tblData{idx,2} = idx;
                    obj.tblData{idx,3} = sf.centerXY(1) * obj.xyUnitFactor;
                    obj.tblData{idx,4} = sf.centerXY(2) * obj.xyUnitFactor;
                    obj.tblData{idx,5} = obj.editingGroup.rois(i).zs(1);
                    obj.tblData{idx,6} = sf.powers(1);
                end
                idx = idx+1;
            else
                obj.tblData{idx,2} = i;
                tlIdx = idx;

                if obj.editorModeIsStim
                    if ~isempty(obj.editingGroup.rois(i).scanfields)
                        sf = obj.editingGroup.rois(i).scanfields(1);

                        if obj.selectedObj == sf
                            obj.tblData{idx,1} = true;
                            newSel = idx;
                        end

                        if ~isempty(sf.slmPattern)
                            obj.tblData{idx,3} = 'SLM Pattern';
                            stimfcnname = regexpi(func2str(sf.stimfcnhdl),'[^\.]*$','match');
                            if ~strcmp(stimfcnname{1},'point')
                                obj.tblData{idx,3} = [obj.tblData{idx,3} ' + ' stimfcnname{1}];
                            end
                        else
                            obj.tblData{idx,3} = sf.shortDescription(7:end);
                        end
                        obj.tblData{idx,4} = sprintf('%.3f',obj.scannerSet.scanTime(sf)*1000);
                        obj.tblData{idx,5} = sf.repetitions;
                        obj.tblData{idx,6} = num2str(sf.powers);
                        obj.tblData{idx,7} = obj.editingGroup.rois(i).zs(1);
                        obj.tblMapping{idx,2} = sf;
                    end
                    idx = idx+1;
                elseif strcmp(obj.editorMode, 'analysis')
                    if ~isempty(obj.editingGroup.rois(i).scanfields)
                        zs = obj.editingGroup.rois(i).zs;
                        sf = obj.editingGroup.rois(i).scanfields(1);

                        obj.tblData{idx,3} = 'Integration';
                        obj.tblData{idx,4} = sf.channel;
                        obj.tblData{idx,5} = sf.threshold;
                        obj.tblData{idx,6} = upper(sf.processor);
                        obj.tblData{idx,7} = ['[' num2str(min(zs)) '  ' num2str(max(zs)) ']'];
                        tlIdx = idx;

                        for j = 1:numel(zs)
                            z = zs(j);
                            sf = obj.editingGroup.rois(i).get(z);
                            idx = idx+1;

                            if obj.selectedObj == sf
                                newSel = idx;
                            end

                            obj.tblData{idx,1} = newSel == idx;
                            obj.tblData{idx,2} = '';
                            obj.tblData{idx,3} = '     Integration Plane';
                            obj.tblData{idx,4} = '';
                            obj.tblData{idx,5} = '';
                            obj.tblData{idx,6} = '';
                            obj.tblData{idx,7} = z;
                            obj.tblMapping{idx,1} = sf;
                            obj.tblMapping{idx,2} = tlIdx;
                            obj.tblMapping{idx,3} = sf.uuiduint64;
                        end
                    else
                        obj.tblData{idx,3} = '';
                        obj.tblData{idx,4} = '';
                        obj.tblData{idx,5} = '';
                        obj.tblData{idx,6} = '';
                        obj.tblData{idx,7} = '';
                    end
                    idx = idx+1;
                else
                    obj.tblData{idx,3} = obj.editingGroup.rois(i).name;

                    obj.tblData{idx,5} = most.gui.OnOff(obj.editingGroup.rois(i).enable);
                    obj.tblData{idx,6} = most.gui.OnOff(obj.editingGroup.rois(i).display);

                    zs = obj.editingGroup.rois(i).zs;

                    if obj.editingGroup.rois(i).discretePlaneMode || (numel(zs) > 1)
                        obj.tblData{idx,7} = ['[' num2str(min(zs)) '  ' num2str(max(zs)) ']'];
                    else
                        obj.tblData{idx,7} = '[-inf  inf]';
                    end
                    idx = idx+1;

                    maxt = 0;
                    for j = 1:numel(zs)
                        z = zs(j);
                        sf = obj.editingGroup.rois(i).get(z);
                        tim = obj.scannerSet.scanTime(sf)*1000;

                        if obj.selectedObj == sf
                            newSel = idx;
                        end

                        if ~isempty(sf)
                            obj.tblData{idx,1} = newSel == idx;
                            obj.tblData{idx,2} = '';
                            obj.tblData{idx,3} = ['     ' sf.shortDescription];
                            obj.tblData{idx,4} = sprintf('%.3f',tim);
                            obj.tblData{idx,5} = '';
                            obj.tblData{idx,6} = '';
                            obj.tblData{idx,7} = z;
                            obj.tblMapping{idx,1} = sf;
                            obj.tblMapping{idx,2} = tlIdx;
                            obj.tblMapping{idx,3} = sf.uuiduint64;
                        else
                            obj.tblData{idx,1} = false;
                            obj.tblData{idx,2} = '';
                            obj.tblData{idx,3} = '';
                            obj.tblData{idx,4} = '';
                            obj.tblData{idx,5} = '';
                            obj.tblData{idx,6} = '';
                            obj.tblData{idx,7} = '';
                            obj.tblMapping{idx,1} = [];
                            obj.tblMapping{idx,2} = tlIdx;
                            obj.tblMapping{idx,3} = [];
                        end
                        idx = idx+1;

                        maxt = max(maxt,tim);
                    end

                    obj.tblData{tlIdx,4} = sprintf('%.3f',maxt);
                end
            end
        end
    end
    obj.roiTable.Data = obj.tblData;

    if ~obj.createMode && newSel < 1
        obj.changeSelection();
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

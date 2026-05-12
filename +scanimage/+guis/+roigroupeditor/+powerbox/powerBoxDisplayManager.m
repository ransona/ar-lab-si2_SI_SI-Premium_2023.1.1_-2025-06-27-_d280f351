classdef powerBoxDisplayManager < handle
    properties
        hRoiGroupEditor
        
        powerBoxDisplays = scanimage.guis.roigroupeditor.powerbox.PowerBoxDisplay.empty
    end
    
    properties (Hidden)
        hListeners = event.listener.empty(0,1);
    end
    
    methods
        function obj = powerBoxDisplayManager(hRoiGroupEditor)
            obj.hRoiGroupEditor = hRoiGroupEditor;
            
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hRoiGroupEditor.hModel.hBeams,'powerBoxes','PostSet',@obj.update);
            
            obj.update();
            obj.setAllVisibility(hRoiGroupEditor.showPowerBoxes);
        end
        
        function delete(obj)
            for idx = 1:numel(obj.powerBoxDisplays)
                powerBoxDisplay = obj.powerBoxDisplays(idx);
                if most.idioms.isValidObj(powerBoxDisplay)
                    powerBoxDisplay.delete();
                end
            end
            obj.powerBoxDisplays = scanimage.guis.roigroupeditor.powerbox.PowerBoxDisplay.empty();
            
            for idx = 1:numel(obj.hListeners)
                hListener = obj.hListeners(idx);
                if most.idioms.isValidObj(hListener)
                    hListener.delete();
                end
            end
            obj.hListeners = event.listener.empty(0,1);
        end
        
        function update(obj, varargin)
            powerBoxes = obj.hRoiGroupEditor.hModel.hBeams.powerBoxes;
            
            %eliminate displays without matching powerboxes
            for pbdIdx = 1:numel(obj.powerBoxDisplays)
                pbd = obj.powerBoxDisplays(pbdIdx);
                
                if ~most.idioms.isValidObj(pbd)
                    continue;
                end
                
                pbdMatch = pbd.powerBoxUuid == [powerBoxes.uuiduint64];
                if ~any(pbdMatch)
                    pbd.delete();
                    continue;
                elseif ~powerBoxes(pbdMatch).useSampleAbsolute && isa(pbd,'scanimage.guis.roigroupeditor.powerbox.SamplePowerBox')
                    pbd.delete();
                    continue;
                end
                
                if isa(pbd,'scanimage.guis.roigroupeditor.powerbox.FocusPowerBox')
                    rois = obj.hRoiGroupEditor.editingGroup.imagingRois;
                    
                    if isempty(rois)
                        pbd.delete();
                        continue;
                    end
                    
                    if ~any(pbd.roiUuid == [rois.uuiduint64])
                        pbd.delete();
                        continue;
                    end
                    
                    if pbd.hPowerBox.useSampleAbsolute
                        pbd.delete();
                    end
                end
            end
            
            invalidMask = ~arrayfun(@(pbd)isempty(pbd),obj.powerBoxDisplays) & ~arrayfun(@(pbd)most.idioms.isValidObj(pbd),obj.powerBoxDisplays);
            obj.powerBoxDisplays(invalidMask) = [];
            
            %Add displays for unmatched powerboxes and/or unmatched ROIs for
            %focus powerboxes
            for pbIdx = 1:numel(powerBoxes)
                pb = powerBoxes(pbIdx);
                
                if pb.useSampleAbsolute
                    if isempty(obj.powerBoxDisplays)
                        obj.powerBoxDisplays(end+1) = scanimage.guis.roigroupeditor.powerbox.SamplePowerBox(obj.hRoiGroupEditor, obj, pb);
                        continue;
                    end
                    
                    if ~any(pb.uuiduint64 == [obj.powerBoxDisplays.powerBoxUuid])
                        obj.powerBoxDisplays(end+1) = scanimage.guis.roigroupeditor.powerbox.SamplePowerBox(obj.hRoiGroupEditor, obj, pb);
                    end
                else
                    focusPBDMask = arrayfun(@(pbd)~isempty(pbd),obj.powerBoxDisplays) &...
                        arrayfun(@(pbd)isa(pbd,'scanimage.guis.roigroupeditor.powerbox.FocusPowerBox'),obj.powerBoxDisplays);
                    focusPBDs = obj.powerBoxDisplays(focusPBDMask);
                    hRoiGroup = obj.hRoiGroupEditor.hModel.hRoiManager.currentRoiGroup;
                    for roiIdx = 1:numel(hRoiGroup.imagingRois)
                        roi = hRoiGroup.imagingRois(roiIdx);
                        
                        if isempty(focusPBDs)
                            obj.powerBoxDisplays(end+1) = scanimage.guis.roigroupeditor.powerbox.FocusPowerBox(obj.hRoiGroupEditor, obj, pb, roi);
                            obj.powerBoxDisplays(end).setVisibility(obj.hRoiGroupEditor.showPowerBoxes);
                            focusPBDs = obj.powerBoxDisplays(end);
                            continue;
                        else
                            roiMask = [focusPBDs.roiUuid] == roi.uuiduint64;
                            roiPBDs = focusPBDs(roiMask);
                            pbMask = [roiPBDs.powerBoxUuid] == pb.uuiduint64;
                            PBD = roiPBDs(pbMask);
                            if isempty(PBD)
                                obj.powerBoxDisplays(end+1) = scanimage.guis.roigroupeditor.powerbox.FocusPowerBox(obj.hRoiGroupEditor, obj, pb, roi);
                                obj.powerBoxDisplays(end).setVisibility(obj.hRoiGroupEditor.showPowerBoxes);
                            end
                        end
                    end
                end
            end
            
            %Update power box pane
            if ~isempty(obj.hRoiGroupEditor.selectedPowerBoxDisplay) && ~most.idioms.isValidObj(obj.hRoiGroupEditor.selectedPowerBoxDisplay) %This condition is ture case if the selected PowerBox's isSampleAbsolute property changed.
                pb = obj.hRoiGroupEditor.selectedPowerBox;
                pbdMask = arrayfun(@(pbd)pbd.powerBoxUuid==pb.uuiduint64,obj.powerBoxDisplays);
                pbds = obj.powerBoxDisplays(pbdMask);
                
                if isempty(pbds)
                    if strcmpi(obj.hRoiGroupEditor.hSamplePowerBoxFlow.Visible, 'on')
                        obj.hRoiGroupEditor.finishPowerBoxEdit();
                    end
                else
                    obj.hRoiGroupEditor.selectedPowerBoxDisplay = pbds(1);
                    obj.hRoiGroupEditor.redrawPowerBoxPane();
                end
            end
            
            %Update the Legend
            pbNames = arrayfun(@(pb)pb.name,obj.hRoiGroupEditor.hModel.hBeams.powerBoxes,'UniformOutput',false);
            obj.hRoiGroupEditor.pmSelectedPowerBox.String = [{''},pbNames];
        end
        
        function setAllVisibility(obj, tf)
            for pbd = obj.powerBoxDisplays
                pbd.setVisibility(tf);
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

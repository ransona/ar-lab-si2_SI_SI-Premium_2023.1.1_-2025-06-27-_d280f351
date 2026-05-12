function changeSelection(obj, selObj, selObjParent)
    obj.createMode = false;
    most.idioms.safeDeleteObj(obj.hSelectedObjectListeners);
    set([obj.hBlankPanel, ...
        obj.hNewImagingRoiPanel,...
        obj.hNewStimRoiPanel,...
        obj.hNewAnalysisRoiPanel,...
        obj.hImagingRoiPropsPanel,...
        obj.hGlobalImagingSfPropsPanel,...
        obj.hImagingSfPropsPanel,...
        obj.hStimRoiPropsPanel,...
        obj.hAnalysisRoiPropsPanel,...
        obj.hAnalysisSfPropsPanel,...
        obj.hStimOptimizationPanel], 'Visible', 'off');

    if (nargin > 1) && most.idioms.isValidObj(selObj)
        obj.selectedObj = selObj;
        obj.selectedObjParent = selObjParent;
        obj.hSelectedObjectListeners = [most.util.DelayedEventListener(0.5,selObj,'changed',@(varargin)obj.selectedObjChanged())...
            most.util.DelayedEventListener(0.5,selObj,'ObjectBeingDestroyed',@(varargin)obj.changeSelection())];

        obj.updateMoveButtons();

        switch class(selObj)
            case 'scanimage.mroi.Roi'
                switch obj.editorMode
                    case 'imaging'
                        obj.hImagingRoiPropsPanel.Visible = 'on';
                        obj.activePanelUpdateFcn = @obj.roiPropsPanelUpdate;
                        obj.editorZ = obj.editorZ;

                    case {'stimulation' 'slm'}
                        obj.activePanelUpdateFcn = [];
                        if ~isempty(selObj.scanfields)
                            obj.changeSelection(selObj.scanfields(1), selObj)
                            obj.fixTableCheck();
                        end

                    case 'analysis'
                        obj.hAnalysisRoiPropsPanel.Visible = 'on';
                        obj.activePanelUpdateFcn = @obj.analysisRoiPropsPanelUpdate;
                        obj.editorZ = obj.editorZ;
                end

            case 'scanimage.mroi.scanfield.fields.StimulusField'
                if obj.editorModeIsStim
                    obj.hStimRoiPropsPanel.Visible = 'on';
                    obj.activePanelUpdateFcn = @obj.stimRoiPropsPanelUpdate;
                elseif obj.editorModeIsSlm
                    obj.activePanelUpdateFcn = @obj.updateTable;
                end

                obj.selectedObjRoiIdx = obj.editingGroup.idToIndex(selObjParent.uuiduint64);

                if ~selObj.isPause
                    obj.editorZ = selObjParent.zs(1);
                else
                    obj.editorZ = obj.editorZ;
                end

            case 'scanimage.mroi.scanfield.fields.RotatedRectangle'
                obj.hImagingSfPropsPanel.Visible = 'on';
                obj.activePanelUpdateFcn = @obj.imagingSfPropsPanelUpdate;
                obj.selectedObjRoiIdx = obj.editingGroup.idToIndex(selObjParent.uuiduint64);
                obj.editorZ = selObjParent.zs(selObjParent.scanfields == selObj);

            case 'scanimage.mroi.scanfield.fields.IntegrationField'
                obj.hAnalysisSfPropsPanel.Visible = 'on';
                obj.activePanelUpdateFcn = @obj.analysisSfPropsPanelUpdate;
                obj.selectedObjRoiIdx = obj.editingGroup.idToIndex(selObjParent.uuiduint64);
                obj.editorZ = selObjParent.zs(selObjParent.scanfields == selObj);
        end

        obj.selectedObjChanged();

        obj.pbDel.Enable = 'on';
    else
        obj.selectedObj = [];
        obj.selectedObjParent = [];
        obj.selectedObjRoiIdx = 0;
        obj.activePanelUpdateFcn = [];
        obj.hSelectedObjectListeners = [];
        if obj.editorModeIsStim && isa(obj.scannerSet,'scanimage.mroi.scannerset.GalvoGalvo')
            obj.hStimOptimizationPanel.Visible = 'on';
        elseif obj.editorModeIsImaging
            obj.hGlobalImagingSfPropsPanel.Visible = 'on';
            obj.updateGlobalPanel();
        elseif ~obj.editorModeIsSlm
            obj.hBlankPanel.Visible = 'on';
        end
        obj.pbMoveBottom.Enable = 'off';
        obj.pbMoveDown.Enable = 'off';
        obj.pbMoveUp.Enable = 'off';
        obj.pbMoveTop.Enable = 'off';
        obj.pbDel.Enable = 'off';
        obj.updateDisplay();
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

function stimRoiPropsPanelUpdate(obj)
    obj.hStimRoiPropsPanelCtls.etZ.hCtl.String = obj.selectedObjParent.zs(1);
    if most.idioms.isValidObj(obj.selectedObj)
        obj.hStimRoiPropsPanelCtls.etCenterX.hCtl.String = obj.selectedObj.centerXY(1) * obj.xyUnitFactor + obj.xyUnitOffset(1);
        obj.hStimRoiPropsPanelCtls.etCenterY.hCtl.String = obj.selectedObj.centerXY(2) * obj.xyUnitFactor + obj.xyUnitOffset(2);
        obj.hStimRoiPropsPanelCtls.etWidth.hCtl.String = obj.selectedObj.sizeXY(1) * obj.xyUnitFactor;
        obj.hStimRoiPropsPanelCtls.etHeight.hCtl.String = obj.selectedObj.sizeXY(2) * obj.xyUnitFactor;
        obj.hStimRoiPropsPanelCtls.etRotation.hCtl.String = obj.selectedObj.rotation;

        stimFunctionName = regexpi(func2str(obj.selectedObj.stimfcnhdl),'[^\.]*$','match');
        stimFunctionOptions = obj.hStimRoiPropsPanelCtls.pmFunction.hCtl.String;

        [~,obj.hStimRoiPropsPanelCtls.pmFunction.hCtl.Value] = ismember(stimFunctionName,stimFunctionOptions);
        obj.hStimRoiPropsPanelCtls.etArgs.ParameterOptions = obj.getStimParamOptions(stimFunctionName{1});
        obj.hStimRoiPropsPanelCtls.etArgs.Value = obj.selectedObj.stimparams;

        hasSlmScannerset = isa(obj.scannerSet,'scanimage.mroi.scannerset.SLM') || ~isempty(obj.scannerSet.slm);
        showSlm = hasSlmScannerset && ~ismember(stimFunctionName, {'pause' 'park' 'waypoint'});
        obj.hStimRoiPropsPanelCtls.slmFlow.Visible = most.gui.OnOff(showSlm);
        if showSlm
            h = 164;
        else
            h = 144;
        end
        obj.hStimRoiPropsPanelCtls.paramPanel.HeightLimits = [h h];

        if isempty(obj.selectedObj.slmPattern)
            obj.hStimRoiPropsPanelCtls.pbEditSlm.String = 'Create';
            obj.hStimRoiPropsPanelCtls.etPattern.String = 'None';
        else
            obj.hStimRoiPropsPanelCtls.pbEditSlm.String = 'Clear';
            if size(obj.selectedObj.slmPattern,2) > 4
                obj.hStimRoiPropsPanelCtls.etPattern.String = 'Bitmap';
            else
                obj.hStimRoiPropsPanelCtls.etPattern.String = 'Points';
            end
        end

        obj.hStimRoiPropsPanelCtls.etDuration.hCtl.String = obj.selectedObj.duration*1000;
        obj.hStimRoiPropsPanelCtls.etReps.hCtl.String = obj.selectedObj.repetitions;
        obj.hStimRoiPropsPanelCtls.etPower.hCtl.String = num2str(obj.selectedObj.powers);
    else
        obj.hStimRoiPropsPanelCtls.etCenterX.hCtl.String = '';
        obj.hStimRoiPropsPanelCtls.etCenterY.hCtl.String = '';
        obj.hStimRoiPropsPanelCtls.etWidth.hCtl.String = '';
        obj.hStimRoiPropsPanelCtls.etHeight.hCtl.String = '';
        obj.hStimRoiPropsPanelCtls.etRotation.hCtl.String = '';

        obj.hStimRoiPropsPanelCtls.etArgs.Value = {};
        obj.hStimRoiPropsPanelCtls.etDuration.hCtl.String = '';
        obj.hStimRoiPropsPanelCtls.etReps.hCtl.String = '';
        obj.hStimRoiPropsPanelCtls.etPower.hCtl.String = '';
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

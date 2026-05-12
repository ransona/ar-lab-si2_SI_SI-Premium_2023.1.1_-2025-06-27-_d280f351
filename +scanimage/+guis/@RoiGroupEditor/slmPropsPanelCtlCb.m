function slmPropsPanelCtlCb(obj,src,~)
    obj.enableListeners = false;
    updateAll = false;
    switch src.Tag
        case 'pmFunction'
            stimfcnname = obj.slmScanOptions{src.Value};
            var = 'stimfcnhdl';
            val = str2func(['scanimage.mroi.stimulusfunctions.' stimfcnname]);
            obj.slmPatternSfParent.stimfcnhdl = val;
            updateAll = true;

        case 'etArgs'
            var = 'stimparams';
            val = src.Value;

        case 'etWidth'
            etwidth = str2num(src.String);

            if ~isempty(etwidth) && ~isnan(etwidth) && ~isinf(etwidth)
                obj.slmPatternSfParent.sizeXY(1) = etwidth / obj.xyUnitFactor;
                var = 'sizeXY';
                val = obj.slmPatternSfParent.sizeXY;
                updateAll = true;
            else
                most.idioms.warn('NaN and Inf are not allowed for width. Resetting to previous value.');
            end

        case 'etHeight'
            etheight = str2num(src.String);

            if ~isempty(etheight) && ~isnan(etheight) && ~isinf(etheight)
                obj.slmPatternSfParent.sizeXY(2) = etheight / obj.xyUnitFactor;
                var = 'sizeXY';
                val = obj.slmPatternSfParent.sizeXY;
                updateAll = true;
            else
                most.idioms.warn('NaN and Inf is not allowed for height. Resetting to previous value.');
            end

        case 'etRotation'
            etrotation = str2num(src.String);

            if ~isempty(etrotation) && ~isnan(etrotation) && ~isinf(etrotation)
                obj.slmPatternSfParent.rotation = etrotation;
                var = 'rotation';
                val = etrotation;
                updateAll = true;
            else
                most.idioms.warn('Rotation value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etDuration'
            etduration = str2num(src.String);

            if ~isempty(etduration) && ~isnan(etduration) && ~isinf(etduration) && (etduration > 0)
                obj.slmPatternSfParent.duration = etduration/1000;
            else
                most.idioms.warn('Duration value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etReps'
            etreps = str2num(src.String);

            if ~isempty(etreps) && ~isnan(etreps) && ~isinf(etreps) && (etreps > 0) && (round(etreps) == etreps)
                obj.slmPatternSfParent.repetitions = etreps;
            else
                most.idioms.warn('Repetitions must be a valid positive integer. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPower'
            etpower = str2num(src.String);

            if ~isempty(etpower) && ~isnan(etpower) && ~isinf(etpower)
                obj.slmPatternSfParent.powers = etpower;
            else
                most.idioms.warn('Beam Power must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end
    end

    if updateAll
        for roi = obj.editingGroup.rois
            if ~isempty(roi.scanfields)
                roi.scanfields(1).(var) = val;
            end
        end
    end

    obj.enableListeners = true;
    obj.updateScanPathCache();
    obj.updateDisplay();
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

function stimRoiPropsPanelCtlCb(obj,src,~)
    obj.enableListeners = false;
    dud = false;
    switch(src.Tag)
        case 'etZ'
            z = str2num(src.String);
            if ~isempty(z) && ~isnan(z) && ~isinf(z)
                obj.selectedObjParent.moveSfById(1,z);
                if ~obj.selectedObj.isPause
                    obj.updateScanPathCache();
                    obj.editorZ = z;
                    dud = true;
                end
            else
                most.idioms.warn('Z value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etCenterX'
            centerX = str2num(src.String);

            if ~isempty(obj.xyUnitFactor) && (obj.xyUnitFactor ~= 0)
                if ~isempty(centerX) && ~isnan(centerX) && ~isinf(centerX)
                    obj.selectedObj.centerXY(1) = (centerX - obj.xyUnitOffset(1)) / obj.xyUnitFactor;
                else
                    most.idioms.warn('Center X value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
                end
            else
                most.idioms.warn('XY UnitFactor must contain a numeric, non-zero value. Resetting Center X to previous value.');
            end

        case 'etCenterY'
            centerY = str2num(src.String);

            if ~isempty(obj.xyUnitFactor) && (obj.xyUnitFactor ~= 0)
                if ~isempty(centerY) && ~isnan(centerY) && ~isinf(centerY)
                    obj.selectedObj.centerXY(2) = (centerY - obj.xyUnitOffset(2)) / obj.xyUnitFactor;
                else
                    most.idioms.warn('Center Y value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
                end
            else
                most.idioms.warn('XY UnitFactor must contain a numeric, non-zero value. Resetting Center Y to previous value.');
            end

        case 'etWidth'
            etwidth = str2num(src.String);

            if ~isempty(obj.xyUnitFactor) && (obj.xyUnitFactor ~= 0)
                if ~isempty(etwidth) && ~isnan(etwidth) && ~isinf(etwidth)
                    obj.selectedObj.sizeXY(1) = etwidth / obj.xyUnitFactor;
                else
                    most.idioms.warn('NaN and Inf are not allowed for width. Resetting to previous value.');
                end
            else
                most.idioms.warn('XY UnitFactor must contain a numeric, non-zero value. Resetting Width to previous value.');
            end

        case 'etHeight'
            etheight = str2num(src.String);

            if ~isempty(obj.xyUnitFactor) && (obj.xyUnitFactor ~= 0)
                if ~isempty(etheight) && ~isnan(etheight) && ~isinf(etheight)
                    obj.selectedObj.sizeXY(2) = etheight / obj.xyUnitFactor;
                else
                    most.idioms.warn('NaN and Inf is not allowed for height. Resetting to previous value.');
                end
            else
                most.idioms.warn('XY UnitFactor must contain a numeric, non-zero value. Resetting Height to previous value.');
            end

        case 'etRotation'
            etrotation = str2num(src.String);

            if ~isempty(etrotation) && ~isnan(etrotation) && ~isinf(etrotation)
                obj.selectedObj.rotation = etrotation;
            else
                most.idioms.warn('Rotation value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'pmFunction'
            options = src.String;
            fn = options{src.Value};
            stimfcnname = sprintf('scanimage.mroi.stimulusfunctions.%s',fn);
            obj.selectedObj.stimfcnhdl  = str2func(stimfcnname);
            if ismember(fn, {'pause' 'park' 'waypoint'})
                obj.selectedObj.slmPattern = [];
            end

        case 'etArgs'
            obj.selectedObj.stimparams = src.Value;

        case 'etDuration'
            etduration = str2num(src.String);

            if ~isempty(etduration) && ~isnan(etduration) && ~isinf(etduration) && (etduration > 0)
                obj.selectedObj.duration = etduration/1000;
            else
                most.idioms.warn('Duration value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etReps'
            etreps = str2num(src.String);

            if ~isempty(etreps) && ~isnan(etreps) && ~isinf(etreps) && (etreps > 0) && (round(etreps) == etreps)
                obj.selectedObj.repetitions = etreps;
            else
                most.idioms.warn('Repetitions must be a valid positive integer. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPower'
            etpower = str2num(src.String);

            if ~isempty(etpower) && ~any(isinf(etpower))
                obj.selectedObj.powers = etpower;
            else
                most.idioms.warn('Beam Power must be a valid number or vector. Inf is not allowed. Resetting to previous value.');
            end
    end
    obj.enableListeners = true;
    obj.stimRoiPropsPanelUpdate();
    obj.satisfyConstraints(obj.selectedObj);
    obj.updateTable();
    obj.setZProjectionLimits();

    if ~dud
        obj.updateScanPathCache();
        obj.updateDisplay();
    end
    %most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
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

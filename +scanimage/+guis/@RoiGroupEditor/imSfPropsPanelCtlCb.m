function imSfPropsPanelCtlCb(obj,src,~)
    obj.enableListeners = false;
    switch(src.Tag)
        case 'etZ'
            z = str2num(src.String);
            if ~isempty(z) && ~isnan(z) && ~isinf(z)
                obj.selectedObjParent.moveSfById(find(obj.selectedObjParent.scanfields == obj.selectedObj),z);
                obj.editorZ = z;

                %                         most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
            else
                most.idioms.warn('Z value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etCenterX'
            centerX = str2num(src.String);

            if ~isempty(obj.xyUnitFactor) && (obj.xyUnitFactor ~= 0)
                if ~isempty(centerX) && ~isnan(centerX) && ~isinf(centerX)
                    obj.selectedObj.centerXY(1) = (centerX - obj.xyUnitOffset(1)) / obj.xyUnitFactor;
                    %                             most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
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
                    %                             most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
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
                    orat = obj.selectedObj.pixelRatio(1);
                    nsz = etwidth / obj.xyUnitFactor;

                    if obj.hModel.hScan2D.isPolygonalScanning
                        obj.hModel.hScan2D.fillFractionSpatial = nsz(1)/obj.scannerSet.scanners{1}.fullAngleDegrees;
                    end

                    obj.selectedObj.sizeXY(1) = nsz;
                    if strcmp(obj.scanfieldResizeMaintainPixelProp, 'ratio')
                        obj.selectedObj.pixelResolutionXY(1) = obj.cleanResolutionRatioValue(orat * nsz);    %%%orat * nsz;
                    end
                    %                             most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
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
                    orat = obj.selectedObj.pixelRatio(2);
                    nsz = etheight / obj.xyUnitFactor;
                    obj.selectedObj.sizeXY(2) = nsz;
                    if strcmp(obj.scanfieldResizeMaintainPixelProp, 'ratio')
                        obj.selectedObj.pixelResolutionXY(2) = obj.cleanResolutionRatioValue(orat * nsz);     %%%orat * nsz;
                    end
                    %                             most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
                else
                    most.idioms.warn('NaN and Inf are not allowed for height. Resetting to previous value.');
                end
            else
                most.idioms.warn('XY UnitFactor must contain a numeric, non-zero value. Resetting Height to previous value.');
            end

        case 'etRotation'
            etrotation = str2num(src.String);

            if ~isempty(etrotation) && ~isnan(etrotation) && ~isinf(etrotation)
                obj.selectedObj.degrees = etrotation;
                %                        most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
            else
                most.idioms.warn('Rotation value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPixCountX'
            pixCountX = str2num(src.String);

            if ~isempty(pixCountX) && ~isnan(pixCountX) && ~isinf(pixCountX) && (pixCountX > 0) && (round(pixCountX) == pixCountX)
                obj.selectedObj.pixelResolution(1) = pixCountX;
                %                         most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
            else
                most.idioms.warn('Pixel Count X must be a valid positive integer value. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPixCountY'
            pixCountY = str2num(src.String);

            if ~isempty(pixCountY) && ~isnan(pixCountY) && ~isinf(pixCountY) && (pixCountY > 0) && (round(pixCountY) == pixCountY)
                obj.selectedObj.pixelResolution(2) = pixCountY;
                %                         most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
            else
                most.idioms.warn('Pixel Count Y must be a valid positive integer. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPixRatioX'
            pixRatioX = str2num(src.String);

            if ~isempty(pixRatioX) && ~isnan(pixRatioX) && ~isinf(pixRatioX) && (pixRatioX ~= 0)
                obj.selectedObj.pixelRatio(1) = obj.cleanResolutionRatioValue(pixRatioX * obj.xyUnitFactor);
                %                         most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
            else
                most.idioms.warn('Pixel Ratio X must be a valid non-zero number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPixRatioY'
            pixRatioY = str2num(src.String);

            if ~isempty(pixRatioY) && ~isnan(pixRatioY) && ~isinf(pixRatioY) && (pixRatioY ~= 0)
                obj.selectedObj.pixelRatio(2) = obj.cleanResolutionRatioValue(pixRatioY * obj.xyUnitFactor);
                %                         most.idioms.info('ROI position/size data typed directly into edit fields may have been altered due to contraints based on your scanner system.');
            else
                most.idioms.warn('Pixel Ratio Y must be a valid non-zero number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'rbMaintainPixCount'
            obj.scanfieldResizeMaintainPixelProp = 'count';

        case 'rbMaintainPixRatio'
            obj.scanfieldResizeMaintainPixelProp = 'ratio';
    end
    obj.enableListeners = true;
    obj.imagingSfPropsPanelUpdate();
    obj.satisfyConstraints(obj.selectedObj);
    obj.updateTable();
    obj.setZProjectionLimits();
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

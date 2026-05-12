function newRoiPropsPanelCtlCb(obj,src,~)
    switch(src.Tag)
        case 'pbCancel'
            obj.changeSelection();

        case 'pbCreateDefault'
            if obj.cellPickOn
                obj.endCellPick(true);
            else
                obj.createRoi();
            end

        case 'etCenterX'
            centerX = str2num(src.String);

            if ~isempty(obj.xyUnitFactor) && (obj.xyUnitFactor ~= 0)
                if ~isempty(centerX) && ~isnan(centerX) && ~isinf(centerX)
                    obj.defaultRoiPositionX = (centerX - obj.xyUnitOffset(1)) / obj.xyUnitFactor;
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
                    obj.defaultRoiPositionY = (centerY - obj.xyUnitOffset(2)) / obj.xyUnitFactor;
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
                    obj.defaultRoiWidth = etwidth / obj.xyUnitFactor;
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
                    obj.defaultRoiHeight = etheight / obj.xyUnitFactor;
                else
                    most.idioms.warn('NaN and Inf are not allowed for height. Resetting to previous value.');
                end
            else
                most.idioms.warn('XY UnitFactor must contain a numeric, non-zero value. Resetting Height to previous value.');
            end

        case 'etRotation'
            etrotation = str2num(src.String);

            if ~isempty(etrotation) && ~isnan(etrotation) && ~isinf(etrotation)
                obj.defaultRoiRotation = etrotation;
            else
                most.idioms.warn('Rotation value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPixCountX'
            pixCountX = str2num(src.String);

            if ~isempty(pixCountX) && ~isnan(pixCountX) && ~isinf(pixCountX) && (pixCountX > 0) && (round(pixCountX) == pixCountX)
                obj.defaultRoiPixelCountX = pixCountX;
            else
                most.idioms.warn('Pixel Count X value must be a valid positive integer. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPixCountY'
            pixCountY = str2num(src.String);

            if ~isempty(pixCountY) && ~isnan(pixCountY) && ~isinf(pixCountY) && (pixCountY > 0) && (round(pixCountY) == pixCountY)
                obj.defaultRoiPixelCountY = pixCountY;
            else
                most.idioms.warn('Pixel Count Y must be a valid positive integer. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPixRatioX'
            pixRatioX = str2num(src.String);

            if ~isempty(pixRatioX) && ~isnan(pixRatioX) && ~isinf(pixRatioX) && (pixRatioX ~= 0)
                obj.defaultRoiPixelRatioX = pixRatioX * obj.xyUnitFactor;
            else
                most.idioms.warn('Pixel Ratio X must be a valid non-zero number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etPixRatioY'
            pixRatioY = str2num(src.String);

            if ~isempty(pixRatioY) && ~isnan(pixRatioY) && ~isinf(pixRatioY) && (pixRatioY ~= 0)
                obj.defaultRoiPixelRatioY = pixRatioY * obj.xyUnitFactor;
            else
                most.idioms.warn('Pixel Ratio Y value must be a valid non-zero number. NaN and Inf are not allowed. Resetting to previous value.');
            end

        case 'etMargin'
            etmargin = str2num(src.String);

            if ~isempty(obj.xyUnitFactor) && (obj.xyUnitFactor ~= 0)
                if ~isempty(etmargin) && ~isnan(etmargin) && ~isinf(etmargin)
                    obj.cellPickRoiMargin = etmargin / obj.xyUnitFactor;
                else
                    most.idioms.warn('Margin value must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
                end
            else
                most.idioms.warn('XY UnitFactor must contain a numeric, non-zero value. Resetting Margin to previous value.');
            end
    end

    obj.newRoiPropsPanelUpdate();
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

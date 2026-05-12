function setPowerBoxLocation(obj, ~, ~)
    if ~obj.selectedPowerBox.useSampleAbsolute
        return;
    end

    if any(strcmpi({obj.hContextImages(:).name}, obj.pmPowerBoxLocation.pmValue))
        contextName = obj.pmPowerBoxLocation.pmValue;
        contextImageIndex = strcmpi({obj.hContextImages(:).name}, contextName);
        contextImage = obj.hContextImages(contextImageIndex);

        currentZ = contextImage.currZIdx;
        zCornerPoints = contextImage.roiCPs;

        isValidContextImage = ~isempty(currentZ)...
            && length(zCornerPoints) >= currentZ...
            && ~isempty(zCornerPoints{contextImage.currZIdx});
        if ~isValidContextImage
            % unset power box location
            obj.pmPowerBoxLocation.Value = 1;
            most.ErrorHandler.logAndReportError(['Could not retrieve corner points for context `%s`. ' ...
            'Forming corner points may require a live acquisition before setting this powerbox location.'], ...
            contextName);
            return;
        end

        roiCPs = zCornerPoints{contextImage.currZIdx}{1};

    elseif any(strcmpi({obj.editingGroup.rois.name},obj.pmPowerBoxLocation.pmValue))
        roiIndex = strcmpi({obj.editingGroup.rois.name}, obj.pmPowerBoxLocation.pmValue);
        roi = obj.editingGroup.rois(roiIndex);
        roiCPs = roi.scanfields.cornerpoints;
    else
        %No-op. User selected neither a context image nor
        %an ROI.
        return;
    end
    hMotors = obj.hModel.hMotors;
    posAbs_um = hMotors.getPosition(hMotors.hCSSampleAbsolute);
    sizeFOV = max(diff(obj.hModel.hScan2D.nominalFovCornerPoints));
    obj.selectedPowerBox.sampleAbsoluteLocation(1:2) = posAbs_um.points(:,1:2) + mean(roiCPs) * obj.hModel.objectiveResolution;
    obj.selectedPowerBox.rect(3:4) = max(diff(roiCPs)) ./ sizeFOV;
    obj.selectedPowerBoxDisplay.calculatePosition();
    obj.hModel.hBeams.calculateSampleAbsolutePowerBoxRect();
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

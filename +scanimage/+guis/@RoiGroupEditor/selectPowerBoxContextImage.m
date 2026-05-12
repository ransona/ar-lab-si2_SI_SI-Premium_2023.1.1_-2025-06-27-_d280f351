function selectPowerBoxContextImage(obj, ~, ~)
    if isempty(obj.pmPowerBoxContextImage.pmValue)
        return;
    end

    hContextImageIndex = strcmpi({obj.hContextImages(:).name}, obj.pmPowerBoxContextImage.pmValue);
    contextImage = obj.hContextImages(hContextImageIndex);

    % Get ROI Index
    locationName = obj.pmPowerBoxLocation.pmValue;
    roiIdx = 1;
    if ~isempty(locationName)
        rois = obj.editingGroup.rois;
        roiNames = arrayfun(@(roi)roi.name,rois,'UniformOutput',false);
        roiNameMatchMask = strcmpi(locationName, roiNames);
        if any(roiNameMatchMask)
            roiIdx = find(roiNameMatchMask, 1);
        end
    end

    contextName = obj.pmPowerBoxContextImage.pmValue;
    if isa(contextImage,'scanimage.guis.roigroupeditor.LiveContextImage')
        ContextSurfaces = contextImage.hSurfs;
        if length(ContextSurfaces) < roiIdx
            obj.pmPowerBoxContextImage.Value = 1; % unset context image dropdown.
            most.ErrorHandler.logAndReportError(['Unable to select context image `%s` as mask reference. ' ...
                'No image data found. Try starting an acquisition before selecting this context image.'], ...
                contextName);
            return;
        end
        image = rgb2gray(contextImage.hSurfs(roiIdx).CData);
    else
        ContextSurfaces = contextImage.imgs{contextImage.currZIdx};
        if length(ContextSurfaces) < roiIdx
            obj.pmPowerBoxContextImage.Value = 1; % unset context image dropdown.
            most.ErrorHandler.logAndReportError(['Unable to select context image `%s` as mask reference. ' ...
                'No image data found.'], ...
                contextName);
            return;
        end
        image = contextImage.imgs{contextImage.currZIdx}{roiIdx}{contextImage.channelSelIdx};
    end

    image = double(fliplr(image));
    obj.hPowerBoxMaskImage.CData = image;
    obj.slPowerBoxContextImageThreshold.min = min(image(:));
    obj.slPowerBoxContextImageThreshold.max = max(image(:));
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

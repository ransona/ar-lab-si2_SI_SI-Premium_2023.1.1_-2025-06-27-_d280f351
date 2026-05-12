function sf = createSf(obj,centerXY,sizeXY,power)
    if nargin < 2 || isempty(centerXY)
        centerXY = [obj.defaultRoiPositionX obj.defaultRoiPositionY];
    end
    if nargin < 3 || isempty(sizeXY)
        sizeXY = [obj.defaultRoiWidth obj.defaultRoiHeight];
    end

    switch obj.editorMode
        case 'imaging'
            switch obj.newRoiDefaultResolutionMode
                case 'pixel count'
                    pixRes = [obj.defaultRoiPixelCountX obj.defaultRoiPixelCountY];

                case 'pixel ratio'
                    pixRes = sizeXY .* [obj.defaultRoiPixelRatioX obj.defaultRoiPixelRatioY];
            end

            adjustedPixRes = abs(round(pixRes));

            for dx = 1:numel(pixRes)
                if isnan(adjustedPixRes(dx)) || isinf(adjustedPixRes(dx)) || (adjustedPixRes(dx) == 0)
                    adjustedPixRes(dx) = 1;
                    most.idioms.warn('Pixel Resolution element cannot be NaN, Inf or 0. Setting Pixel Resolution to 1.');
                end
            end

            pixRes = adjustedPixRes;

            sf=scanimage.mroi.scanfield.fields.RotatedRectangle([centerXY-sizeXY/2 sizeXY],obj.defaultRoiRotation,pixRes);

        case 'stimulation'
            sf = scanimage.mroi.scanfield.fields.StimulusField(sprintf('scanimage.mroi.stimulusfunctions.%s',obj.defaultStimFunction),obj.defaultStimFunctionArgs,obj.defaultStimDuration/1000,...
                obj.defaultStimRepetitions,centerXY,sizeXY/2,obj.defaultRoiRotation,obj.defaultStimPower);

        case 'analysis'
            sf = scanimage.mroi.scanfield.fields.IntegrationField();
            sf.centerXY = centerXY;
            sf.sizeXY = sizeXY;
            sf.rotationDegrees = obj.defaultRoiRotation;
            sf.threshold = obj.defaultAnalysisRoiThreshold;
            sf.channel = obj.defaultAnalysisRoiChannel;
            sf.processor = obj.defaultAnalysisRoiProcessor;

        case 'slm'
            if nargin < 4
                power = 1;
            end
            sf = scanimage.mroi.scanfield.fields.StimulusField(obj.slmPatternSfParent.stimfcnhdl,{},obj.defaultStimDuration/1000,...
                obj.defaultStimRepetitions,centerXY,sizeXY/2,obj.defaultRoiRotation,power);
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

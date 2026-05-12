function updatePowerBoxContextImageValue(obj, src, ~)
    if isa(src,'most.gui.constrastSlider')
        obj.etPbCIBgValue.String = num2str(obj.slPowerBoxContextImageValue.value(1));
        obj.etPbCIFgValue.String = num2str(obj.slPowerBoxContextImageValue.value(2));
    else
        obj.pbCIValue = [str2double(obj.etPbCIBgValue.String) str2double(obj.etPbCIFgValue.String)];
    end

    switch obj.pmPowerBoxMaskBackground.pmValue
        case 'Use beam controls'
            obj.selectedPowerBoxDisplay.background = nan;
            BarColorInterpolant = griddedInterpolant([0, 1], [0.3, 0.7]);
            barColorScale = BarColorInterpolant(obj.hModel.hBeams.powerFractions(1));
            obj.slPowerBoxContextImageThreshold.hBarL.FaceColor = most.constants.Colors.orange .* barColorScale;
        case 'Zero'
            obj.selectedPowerBoxDisplay.background = 0;
            obj.slPowerBoxContextImageThreshold.hBarL.FaceColor = most.constants.Colors.darkRed;
        otherwise
    end

    CarColorInterpolant = griddedInterpolant([0, 1], [0.3, 0.9]);
    carColorScale = [CarColorInterpolant(obj.pbCIValue(1)); CarColorInterpolant(obj.pbCIValue(2))];
    carColors = most.constants.Colors.red .* carColorScale;
    obj.slPowerBoxContextImageThreshold.setCarColors(carColors(1,:), carColors(2,:));
    obj.slPowerBoxContextImageThreshold.hCarL.FaceColor = carColors(1,:);   
    obj.slPowerBoxContextImageThreshold.hCarH.FaceColor = carColors(2,:);
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

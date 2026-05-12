function setCustomSLMPowerFunction(fcn)
    rs = dabs.resources.ResourceStore();
    hSI = rs.filterByName('ScanImage');
    if isempty(hSI)
        error('Need to launch ScanImage first');
    end

    hSlm = hSI.hPhotostim.hScan.hSlmScan.hSlm;
    try
        hCSFunction = scanimage.mroi.coordinates.CSFunction('SLM Diffraction Efficiency Function',3,hSlm.hCoordinateSystem);
        hCSFunction.fromParentFunction = @newFunctionUsingSlmCSAsInput;
        hSlm.setCSDiffractionEfficiency(hCSFunction);
    catch ME
        most.idioms.warn('Diffraction Efficiency function not added.');
        most.ErrorHandler.logAndReportError(ME);

        if exist('hCSFunction','var') && most.idioms.isValidObj(hCSFunction)
            hCSFunction.delete();
        end
    end

    function efficiency = newFunctionUsingSlmCSAsInput(pts)
        %Convert to SLM Objective from what user was expecting (microns XYZ
        %with lateral zero centered on FOV focal plane for Z.

        hPoints = scanimage.mroi.coordinates.Points(hSlm.hCoordinateSystem,pts);
        hPointsXY = hPoints.transform(hSI.hCoordinateSystems.hCSReference);
        hPointsZ = hPoints.transform(hSI.hCoordinateSystems.hCSFocus);

        x_um = hPointsXY.points(:,1) .* hSI.objectiveResolution;
        y_um = hPointsXY.points(:,2) .* hSI.objectiveResolution;
        z_um = hPointsZ.points(:,3);

        %Calculate power
        efficiency_ = fcn(x_um,y_um,z_um);
        assert(isvector(efficiency_) || isscalar(efficiency_) && ~iscell(efficiency_),'function needs to produce a vector or scalar of an efficiency value given XYZ coordinates.')

        if isrow(efficiency_)
            efficiency_ = efficiency_';
        end

        %Format output to be a matrix with ndimensions columns even though
        %only the first is used.
        efficiency = zeros(size(efficiency_,1),3);
        efficiency(:,1) = efficiency_;
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

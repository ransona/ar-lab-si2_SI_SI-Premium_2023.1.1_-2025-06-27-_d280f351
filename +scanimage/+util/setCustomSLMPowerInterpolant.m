function setCustomSLMPowerInterpolant(fcn,numPoints,ranges_um,zeroOrderBlockRadius_um)
rs = dabs.resources.ResourceStore();
hSI = rs.filterByName('ScanImage');
if isempty(hSI)
    error('Need to launch ScanImage first');
end

[points_um, points_SLMUnits] = createCalibrationPointSet('grid',numPoints,ranges_um,zeroOrderBlockRadius_um);
efficiencies = zeros(size(points_um,1),1);
for pointIdx = 1:size(points_um,1)
    %Here, we will just set directly the diffraction efficiency: ratio of
    %actual power to expected power at each point.

    % In this example, I just set all efficiencies to 0.5

    efficiencies(pointIdx,1) = fcn(points_um(pointIdx,1),points_um(pointIdx,2), points_um(pointIdx,3));
end

%Then create the interpolant with the points
E = createEfficiencyInterpolant(points_SLMUnits,efficiencies);

% Plot the interpolant
% most.math.InterpolantPlot3D(E,[],'Excitation intensity',{'SLM X [um]','SLM Y [um]','SLM Z [um]','Intensity'});

%Then assign the interpolant to the appropriate property in ScanImage

hSI.hPhotostim.hScan.hSlmScan.hSlm.hCSDiffractionEfficiency.fromParentInterpolant{1} = E;


    function [pts_um, pts_slm] = createCalibrationPointSet(type,numPoints,ranges_um,zeroOrderBlockRadius)
    switch lower(type)
        case 'grid'
            pts_um = grid();
        case 'random'
            pts_um = randomSet();
        otherwise
            error('Unknown point type: %s',type);
    end

    hPointsXY = scanimage.mroi.coordinates.Points(hSI.hCoordinateSystems.hCSReference,pts_um ./ hSI.objectiveResolution);
    hPointsZ = scanimage.mroi.coordinates.Points(hSI.hCoordinateSystems.hCSReference,pts_um);

    hPointsXY = hPointsXY.transform(hSI.hPhotostim.hScan.hSlmScan.hSlm.hCoordinateSystem);
    hPointsZ  = hPointsZ.transform(hSI.hPhotostim.hScan.hSlmScan.hSlm.hCoordinateSystem);

    pts_slm = zeros(size(hPointsXY.points,1),3);
    pts_slm(:,1:2) = hPointsXY.points(:,[1 2]);
    pts_slm(:,3) = hPointsZ.points(:,3);

    function pts = randomSet()
        pts = zeros(0,3);

        while size(pts,1) < numPoints
            pts_ = rand(numPoints-size(pts,1),3);
            pts_ = pts_ .* diff(ranges_um,1,2)' + ranges_um(:,1)';
            pts_ = round(pts_);

            % mask out zeroOrderDiameter
            if zeroOrderBlockRadius
                d = sqrt(sum(pts_.^2,2));
                mask = d <= zeroOrderBlockRadius;
                pts_(mask,:) = [];
            end
            pts = vertcat(pts,pts_);
        end

        % sort in z direction
        [~,idxs] = sort(pts(:,3));
        pts = pts(idxs,:);
    end

    function pts = grid()
        if isscalar(numPoints)
            numPoints = repmat(numPoints,1,3);
        end

        xx = linspace(ranges_um(1,1),ranges_um(1,2),numPoints(1));
        yy = linspace(ranges_um(2,1),ranges_um(2,2),numPoints(2));
        zz = linspace(ranges_um(3,1),ranges_um(3,2),numPoints(3));

        [xx,yy,zz] = ndgrid(xx,yy,zz);
        pts = [xx(:), yy(:), zz(:)];

        if zeroOrderBlockRadius
            d = sqrt(sum(pts.^2,2));
            mask = d <= zeroOrderBlockRadius;
            pts(mask,:) = [];
        end
    end
end

function E = createEfficiencyInterpolant(points,efficiencies)            
    % convert to double for better calculation of gradients during
    % gradient ascent
    slmXYZs = double(vertcat(points));
    efficiencies = double(vertcat(efficiencies));

    modelterms = [...
        0 0 0; 1 0 0; 0 1 0; 0 0 1;...
        1 1 0; 1 0 1; 0 1 1; 1 1 1; 2 0 0; 0 2 0; 0 0 2];

    E = most.math.polynomialInterpolant(...
        slmXYZs,efficiencies,modelterms);

    E.Points = single(E.Points);
    E.Values = single(E.Values); 
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

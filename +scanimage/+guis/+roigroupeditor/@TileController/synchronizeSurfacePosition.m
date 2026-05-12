function synchronizeSurfacePosition(obj)
    MotorControl = obj.TileManager.hSI.hMotors;
    
    if ~isvalid(MotorControl)
        return;
    end
    motorOffset = MotorControl.samplePosition(1:2);
    micronToDegreeAffine = MotorControl.hCSMicron.toParentAffine;
    for iSurface = 1:length(obj.Surfaces)
        iTile = obj.tileIndices(iSurface);
        tileCornerPoints = obj.TileManager.hScanTiles(iTile).tileCornerPts;
        relativeCornerPoints = tileCornerPoints - repmat(motorOffset, size(tileCornerPoints, 1), 1);
        relativeCornerPoints = [relativeCornerPoints .';ones(2,size(relativeCornerPoints, 1))];
        degreeCornerPoints = micronToDegreeAffine * relativeCornerPoints;
        xMesh = linspace(min(degreeCornerPoints(1,:)), max(degreeCornerPoints(1,:)), 2);
        yMesh = linspace(min(degreeCornerPoints(2,:)), max(degreeCornerPoints(2,:)), 2);
        [xData, yData, zData] = meshgrid(xMesh, yMesh, 0.1);
        set(obj.Surfaces(iSurface), ...
            'XData', xData, ...
            'YData', yData, ...
            'ZData', zData);
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

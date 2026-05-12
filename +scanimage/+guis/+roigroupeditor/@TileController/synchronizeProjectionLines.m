function synchronizeProjectionLines(obj)
    most.idioms.safeDeleteObj(obj.ProjectionLines);
    obj.ProjectionLines = matlab.graphics.primitive.Line.empty();
    
    MotorControl = obj.TileManager.hSI.hMotors;

    if ~isvalid(obj.ProjectionAxes) || ~isvalid(MotorControl)
        return;
    end

    projectionDim = obj.RoiGroupEditor.projectionDim;
    motorOffset = MotorControl.samplePosition(projectionDim);
    
    % A poor man's mapping between approximate z locations and x points.
    % lineZs is a vector whose indices equals lineXs which is a cell vector
    % containing vectors of line x-data.
    lineZs = [];
    lineXs = {};
    for iTile = 1:length(obj.TileManager.hScanTiles)
        Tile = obj.TileManager.hScanTiles(iTile);
        if ~isvalid(Tile)
            continue;
        end

        projectedPoints = Tile.tileCornerPts(:, projectionDim) - motorOffset;
        iLineZs = find(most.floatingpoint.fuzzyEquals(lineZs, Tile.zPos));
        assert(isempty(iLineZs) || isscalar(iLineZs), ...
            'ScanImage:RoiGroupEditor:TileController:FuzzyEqualsFailure', ...
            ['Internal error involving most.floatingpoint.fuzzyEquals function. ' ...
            'Inconsistent Z comparisons detected! Please contact support with this message.']);
        if isempty(iLineZs)
            lineZs(end+1) = Tile.zPos;
            lineXs(end+1) = {projectedPoints};
        else
            lineXs{iLineZs} = [lineXs{iLineZs}; projectedPoints];
        end
    end

    for iZ = 1:length(lineZs)
        xs = unique(lineXs{iZ});
        x = [min(xs, [], 'all'), max(xs, [], 'all'), NaN];
        y = repmat(lineZs(iZ), size(x));
        z = repmat(0.3, size(x));
        obj.ProjectionLines(end+1) = line(x, y, z, ...
            'Parent', obj.ProjectionAxes, ...
            'HitTest', 'off', ...
            'Visible', most.gui.OnOff(obj.isVisible), ...
            'Color', most.constants.Colors.cyan, ...
            'LineWidth', 1);
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

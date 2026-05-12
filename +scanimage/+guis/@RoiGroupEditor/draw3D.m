function draw3D(obj,~)
    obj.deleteDrawData();

    minz = min(obj.interestingZs);
    maxz = max(obj.interestingZs);

    if ~isempty(obj.scanPathCache)
        if isfield(obj.scanPathCache, 'Z')
            minz = min([minz; obj.scanPathCache.Z(:)]);
            maxz = max([maxz; obj.scanPathCache.Z(:)]);
        end

        if isfield(obj.scanPathCache,'SLM')
            SLMPoints = {obj.scanPathCache.SLM.pattern};
            ptMask = cellfun(@(p)size(p,2)==4,SLMPoints); % filter out bitmaps
            SLMPoints = SLMPoints(ptMask);
            SLMPoints = vertcat(SLMPoints{:});

            if ~isempty(SLMPoints)
                minz = min([minz; SLMPoints(:,3)]);
                maxz = max([maxz; SLMPoints(:,3)]);
            end
        end
    end

    d = max(maxz - minz,10)/20;
    zRange = [minz maxz] + [-d d];

    hasNonPauseRois = (obj.editorModeIsStim || obj.editorModeIsSlm) ...
        && obj.editingGroup.getNumNonPause() > 0;
    Unit = struct('xyFactor', obj.xyUnitFactor, 'xyOffset', obj.xyUnitOffset);
    for iRoi = 1:numel(obj.editingGroup.rois)
        if obj.selectedObjRoiIdx == iRoi
            color = 'g';
            shouldDraw = obj.showSelectedRoi;
        else
            color = 'r';
            shouldDraw = obj.showOtherRois;
        end

        if ~shouldDraw
            continue;
        end
        
        if obj.editorModeIsStim || obj.editorModeIsSlm
            if hasNonPauseRois
                Roi = obj.editingGroup.rois(iRoi);
                obj.drawData{iRoi} = drawStim( ...
                    Roi, ...
                    obj.getStimPts(iRoi, Roi.scanfields(1)), ...
                    'Color', color, ...
                    'Unit', Unit);
            else
                obj.drawData{iRoi} = {};
            end
        else
            Roi = obj.editingGroup.rois(iRoi);
            obj.drawData{iRoi} = drawRoi(obj.editingGroup.rois(iRoi), color, Unit);
        end

        drawData = obj.drawData{iRoi};
        for iGraphic = 1:length(drawData)
            graphic = drawData{iGraphic};
            graphic.Parent = obj.h3DViewAxes;
            graphic.ButtonDownFcn = @obj.roiHit;
            graphic.UserData = Roi.uuiduint64;
        end
    end

    if isempty(obj.drawData)
        obj.drawData = {{}};
    end

    fov = [-1 1] * obj.mainViewFovLim/2;
    FovMesh = convertMeshByUnit(newMesh(fov, fov), Unit);
    obj.h3DViewAxes.XLim = FovMesh.xx;
    obj.h3DViewAxes.YLim = FovMesh.yy;
    obj.h3DViewAxes.ZLim = zRange;

    set(obj.h3DImagingPlaneSurfs, 'XData', obj.h3DViewAxes.XLim);
    set(obj.h3DImagingPlaneSurfs, 'YData', obj.h3DViewAxes.YLim);
end

function handles = drawRoi(roi, color, Unit)
    zs = roi.zs;

    PreviousMesh = convertMeshByUnit(getSfMesh(roi.get(zs(1))), Unit);
    handles = {drawBase(PreviousMesh, zs(1), color)};

    for i = 2:numel(zs)
        scanfield = roi.get(zs(i));
        Mesh = convertMeshByUnit(getSfMesh(scanfield), Unit);

        handles = [handles drawBaseAndSides(roi, [Mesh, PreviousMesh], zs(i+[0, -1]), color)];
        PreviousMesh = Mesh;
    end
end

function handles = drawBaseAndSides(roi, Meshes, zs, color)
    handles = {drawBase(Meshes(1), zs(1), color)};

    if roi.discretePlaneMode
        if numel(roi.scanfields) > 1
            handles{2} = drawGuideline(Meshes, zs, color);
        end
    else
        handles = [handles struct2cell(drawPlaneInterpolation(Meshes, zs, color))'];
    end
end

function h = drawBase(Mesh, currentZ, color)
    h = surface(Mesh.xx, Mesh.yy, currentZ * ones(2), ...
        'FaceColor',color, ...
        'facealpha',.5, ...
        'edgecolor',color, ...
        'linewidth',2);
end

function h = drawGuideline(Meshes, zs, color)
    CenterMeshes = [getMeshCenterMesh(Meshes(1)), getMeshCenterMesh(Meshes(end))];
    h = line( ...
        [CenterMeshes(1).xx CenterMeshes(2).xx], ...
        [CenterMeshes(1).yy CenterMeshes(2).yy], ...
        [zs(1), zs(end)], ...
        'linewidth',1, ...
        'linestyle',':', ...
        'color', color);
end

function Prism = drawPlaneInterpolation(Meshes, zs, color)
    sideprops = { ...
        'FaceColor',color, ...
        'facealpha',.1, ...
        'edgecolor', color,...
        'linewidth',2,...
        'LineStyle','--'};

    surfaceZs = [zs(1), zs(1); zs(end), zs(end)];
    %top side
    Top = surface( ...
        [Meshes(1).xx(1,:);Meshes(2).xx(1,:)], ...
        [Meshes(1).yy(1,:);Meshes(2).yy(1,:)], ...
        surfaceZs, ...
        sideprops{:});
    %bottom side
    Bottom = surface( ...
        [Meshes(1).xx(2,:);Meshes(2).xx(2,:)], ...
        [Meshes(1).yy(2,:);Meshes(2).yy(2,:)], ...
        surfaceZs, ...
        sideprops{:});
    %left side
    Left = surface( ...
        [Meshes(1).xx(:,1),Meshes(2).xx(:,1)]', ...
        [Meshes(1).yy(:,1),Meshes(2).yy(:,1)]', ...
        surfaceZs, ...
        sideprops{:});
    %right side
    Right = surface( ...
        [Meshes(1).xx(:,2),Meshes(2).xx(:,2)]', ...
        [Meshes(1).yy(:,2),Meshes(2).yy(:,2)]', ...
        surfaceZs, ...
        sideprops{:});
    Prism = struct('Top', Top, 'Bottom', Bottom, 'Left', Left, 'Right', Right);
end

function handles = drawStim(roi, path, varargin)
    handles = {};
    p = inputParser;
    p.addParameter('Color', []);
    p.addParameter('Unit', struct());
    p.parse(varargin{:});
    assert(isempty(p.UsingDefaults));

    lxpts = path.G(:,1);
    lypts = path.G(:,2);
    lzpts = path.Z;

    if roi.scanfields(1).isPause || roi.scanfields(1).isPark
        drawCornerPoints = false;
        linestyle = ':';
        numSlmPoints = 0;
    else
        linestyle = '-';
        drawCornerPoints = all(lxpts == lxpts(end)) ...
            && all(lypts == lypts(end)) ...
            && all(lzpts == lzpts(end));

        slmPattern = roi.scanfields(1).slmPattern;
        if 4 == size(slmPattern, 2)
            numSlmPoints = size(slmPattern,1);
        else
            numSlmPoints = 0; % ignore bitmap
        end
    end

    if numSlmPoints > 0
        lxptsSlm = repmat(lxpts,1,numSlmPoints);
        lyptsSlm = repmat(lypts,1,numSlmPoints);
        lzptsSlm = repmat(lzpts,1,numSlmPoints) * 0;

        zeroOrderXYZ = [roi.scanfields(1).centerXY(:)' 0];
        lxptsSlm = lxptsSlm + slmPattern(:,1)' - zeroOrderXYZ(1);
        lyptsSlm = lyptsSlm + slmPattern(:,2)' - zeroOrderXYZ(2);
        lzptsSlm = lzptsSlm + slmPattern(:,3)' - zeroOrderXYZ(3);

        lxptsSlm(end+1,:) = NaN;
        lyptsSlm(end+1,:) = NaN;
        lzptsSlm(end+1,:) = NaN;

        % draw zero order
        ZeroOrderMesh = convertMeshByUnit(newMesh(zeroOrderXYZ(1), zeroOrderXYZ(2)), p.Results.Unit);
        handles{1} = line( ...
            ZeroOrderMesh.xx, ...
            ZeroOrderMesh.yy, ...
            zeroOrderXYZ(3),...
            'linestyle','none', ...
            'Marker','p', ...
            'MarkerEdgeColor', p.Results.Color, ...
            'MarkerFaceColor', p.Results.Color, ...
            'Markersize',10, ...
            'UserData', roi.uuiduint64);

        % draw patterns
        LinePatternMesh = convertMeshByUnit(newMesh(lxptsSlm(:), lyptsSlm(:)), p.Results.Unit);
        handles{2} = line( ...
            LinePatternMesh.xx, ...
            LinePatternMesh.yy, ...
            lzptsSlm(:),...
            'color', p.Results.Color, ...
            'linewidth',2, ...
            'linestyle',linestyle, ...
            'UserData',roi.uuiduint64);

        if drawCornerPoints
            CornerMesh = convertMeshByUnit(newMesh(lxptsSlm(1,:), lyptsSlm(1,:)), p.Results.Unit);
            handles{3} = line( ...
                CornerMesh.xx, ...
                CornerMesh.yy, ...
                lzptsSlm(1,:),...
                'linestyle','none', ...
                'Marker','o', ...
                'MarkerEdgeColor', p.Results.Color, ...
                'MarkerFaceColor', p.Results.Color, ...
                'Markersize',10, ...
                'UserData',roi.uuiduint64);
        end
    else
        LineMesh = convertMeshByUnit(newMesh(lxpts, lypts), p.Results.Unit);
        handles{1} = line( ...
            LineMesh.xx, ...
            LineMesh.yy, ...
            lzpts,...
            'color', p.Results.Color, ...
            'linewidth',2, ...
            'linestyle',linestyle, ...
            'UserData',roi.uuiduint64);

        if drawCornerPoints
            CornerMesh = convertMeshByUnit(newMesh(lxpts(end), lypts(end)), p.Results.Unit);
            handles{2} = line( ...
                CornerMesh.xx, ...
                CornerMesh.yy, ...
                lzpts(end),...
                'linestyle','none', ...
                'Marker','o', ...
                'MarkerEdgeColor', p.Results.Color, ...
                'MarkerFaceColor', p.Results.Color, ...
                'Markersize',10, ...
                'UserData',roi.uuiduint64);
        end
    end
end

function CenterMesh = getMeshCenterMesh(Mesh)
    CenterMesh = struct( ...
        'xx', (Mesh.xx(1) + Mesh.xx(end)) / 2, ...
        'yy', (Mesh.yy(1) + Mesh.yy(end)) / 2);
end

function Mesh = newMesh(xx, yy)
    Mesh = struct('xx', xx, 'yy', yy);
end

function Mesh = getSfMesh(sf)
    [xx,yy] = sf.meshgridOutline(2);
    Mesh = struct('xx', xx, 'yy', yy);
end

function Mesh = convertMeshByUnit(Mesh, Unit)
    Mesh.xx = Mesh.xx * Unit.xyFactor + Unit.xyOffset(1);
    Mesh.yy = Mesh.yy * Unit.xyFactor + Unit.xyOffset(2);
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

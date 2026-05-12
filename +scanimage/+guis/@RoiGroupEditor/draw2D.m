function draw2D(obj, roiIndices)
    nRois = numel(obj.editingGroup.rois);
    isSelectedRoiDrawn = ~ismember(inf, roiIndices);

    if ~isSelectedRoiDrawn
        roiIndices = 1:nRois;
    elseif obj.editorModeIsStim
        roiIndices = unique([roiIndices, (roiIndices-1), (roiIndices+1)]);
        roiIndices(roiIndices<1) = roiIndices(roiIndices<1) + nRois;
        roiIndices(roiIndices>nRois) = roiIndices(roiIndices>nRois) - nRois;
    end

    obj.drawData(end+1:numel(obj.editingGroup.rois)+1) = {{}};
    obj.drawDataProj(end+1:numel(obj.editingGroup.rois)+1) = {{}};

    hasNonPauseRois = obj.editorModeIsStim && 0 < obj.editingGroup.getNumNonPause();

    handleLen = diff(obj.h2DMainViewAxes.YLim) / 40;
    infRg = 1000000;
    nInf = obj.zProjectionRange(1) - infRg;
    pInf = obj.zProjectionRange(2) + infRg;

    for iRoi = roiIndices
        hRoi = obj.editingGroup.rois(iRoi);
        scanfield = hRoi.get(obj.editorZ);

        if iRoi == obj.selectedObjRoiIdx
            if hRoi.enable
                color = [0 1 0];
            else
                color = [0 0.25 0];
            end
                        
            vistf = obj.showSelectedRoi;
            lnz = .6;
        else
            if hRoi.enable
                color = [1 0 0];
            else
                color = [0.25 0 0];
            end
            
            vistf = obj.showOtherRois;
            lnz = .5;
        end
        vis = most.gui.OnOff(vistf);

        wayxpts = nan;
        wayypts = nan;
        waylnz = .4;

        pslmx = [];
        pslmz = [];

        if ~isempty(scanfield)
            if obj.editorModeIsStim || obj.editorModeIsSlm
                % only draw box for selected, non park, non pause
                if iRoi ~= obj.selectedObjRoiIdx || scanfield.isPause || scanfield.isPark
                    surflinestyle = 'none';
                    col1 = color;
                else
                    surflinestyle = '-';
                    col1 = obj.makeToolBoxColor;
                end
                linelinestyle = '-';
                linemkrstyle = 'none';
            else
                % always draw box for imaging rois. solid for
                % defined sf, dotted for interpolated
                if ismember(obj.editorZ, hRoi.zs)
                    surflinestyle = '-';
                else
                    surflinestyle = '--';
                end
                col1 = color;
                linelinestyle = 'none';
                linemkrstyle = 'x';
            end

            ctr = scanfield.centerXY;
            hsz = scanfield.sizeXY / 2;
            rot = scanfield.rotation;
        else
            surflinestyle = '-';
            linelinestyle = 'none';
            linemkrstyle = 'x';
            col1 = 'none';
            ctr = [0 0];
            hsz = [1 1];
            rot = 0;
        end
        col2 = col1;

        pts = [-hsz; -hsz(1) hsz(2); hsz(1) -hsz(2); hsz; 0 0; 0 -hsz(2)-handleLen];
        rot = -rot * pi / 180;
        R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
        pts = scanimage.mroi.util.xformPoints(pts,R);
        pts = pts + repmat(ctr,6,1);

        xx = [pts(1:2,1) pts(3:4,1)];
        yy = [pts(1:2,2) pts(3:4,2)];
        slmx = [];
        slmy = [];

        if obj.editorModeIsStim || obj.editorModeIsSlm
            for scanfieldIdx = 1:numel(hRoi.scanfields)
                scanfield = hRoi.scanfields(scanfieldIdx);
                for ii = 1:size(scanfield.slmPattern,1)
                    if ~isempty(scanfield.slmPattern) && size(scanfield.slmPattern, 2) == 4
                        ctr = scanfield.centerXY;
                        pslmx = [pslmx ctr(1) ctr(1)+scanfield.slmPattern(ii,1) nan];
                        pslmz = [pslmz hRoi.zs(1) scanfield.slmPattern(ii,3) nan];
                    end
                end
            end
        else
            pslmx = [];
            pslmz = [];
        end

        mk3 = 'h';
        ms3 = 10;

        if obj.editorModeIsStim || obj.editorModeIsSlm
            lxpts = [];
            lypts = [];

            if ~isempty(hRoi.scanfields) && (hRoi.scanfields(1).isPause || hRoi.scanfields(1).isPark)
                if hasNonPauseRois
                    path = obj.getStimPts(iRoi,hRoi.scanfields(1));

                    prevRoiZ = obj.editingGroup.rois(iRoi).zs(1);
                    nextRoiZ = prevRoiZ;

                    for iPrevZ = (iRoi-1):-1:1
                        hSearchRoi = obj.editingGroup.rois(iPrevZ);
                        if ~hSearchRoi.scanfields(1).isPause
                            prevRoiZ = hSearchRoi.zs(1);
                            break;
                        end
                    end

                    for iNextZ = (iRoi+1):nRois
                        hSearchRoi = obj.editingGroup.rois(iNextZ);
                        if ~hSearchRoi.scanfields(1).isPause
                            nextRoiZ = hSearchRoi.zs(1);
                            break;
                        end
                    end

                    zs = [prevRoiZ nextRoiZ path.Z(1) path.Z(end)];
                    minz = min(zs);
                    maxz = max(zs);

                    % show if it is the selected roi and the editor
                    % z is within its range OR the editor z is at
                    % the same plane this transition starts or ends
                    % at
                    if (obj.editorZ >= (minz-.01)) && (obj.editorZ <= (maxz+.01))
                        lxpts = path.G(:,1);
                        lypts = path.G(:,2);
                        linelinestyle = '--';
                    end
                end
            elseif ~isempty(scanfield)
                [path, waypath] = obj.getStimPts(iRoi,scanfield);
                lxpts = path.G(:,1);
                lypts = path.G(:,2);

                % if it is a single point, make the marker bigger
                if all(lxpts == lxpts(1)) && all(lypts == lypts(1))
                    linemkrstyle = 'o';
                    col2 = color;
                end

                if ~isempty(waypath)
                    % add a solid line through the waypoint
                    wayxpts = waypath.G(:,1);
                    wayypts = waypath.G(:,2);
                end

                if obj.editorModeIsStim
                    if 4 < size(scanfield.slmPattern, 2)
                        mk3 = 'square';
                        ms3 = 50;
                        slmx = ctr(1);
                        slmy = ctr(2);
                    elseif ~isempty(scanfield.slmPattern)
                        for ii = 1:size(scanfield.slmPattern,1)
                            slmx = [slmx ctr(1) ctr(1)+scanfield.slmPattern(ii,1) nan];
                            slmy = [slmy ctr(2) ctr(2)+scanfield.slmPattern(ii,2) nan];
                        end
                    end
                end
            end
            adata = 1;
            faceCol = 'none';
            cdata = [];
        else
            if isa(scanfield,'scanimage.mroi.scanfield.fields.IntegrationField') && 1 < numel(scanfield.mask)
                adata = scanfield.mask *.5 / max(scanfield.mask(:));
                faceCol = 'texturemap';
                cdata = [];
                cdata(1,1,:) = uint8(color*255);
                cdata = repmat(cdata,size(adata));
            else
                adata = 1;
                faceCol = 'none';
                cdata = [];
            end

            lxpts = pts(5,1);
            lypts = pts(5,2);
        end

        if iRoi == obj.selectedObjRoiIdx...
                && ~isempty(scanfield)...
                && obj.showSelectedRoi...
                && (~isStimulusField(scanfield) || (~scanfield.isPark && ~scanfield.isPause))
            isSelectedRoiDrawn = true;

            % special handling of line stimulus function to make it easier to draw
            if isStimulusField(scanfield) && strcmp(func2str(scanfield.stimfcnhdl), 'scanimage.mroi.stimulusfunctions.line')
                pt1 = pts(2,:);
                pt2 = pts(3,:);
                z = 2;
                obj.hSelObjHandles{1}.MarkerFaceColor = [.3 0 0];
                obj.hSelObjHandles{3}.MarkerFaceColor = obj.makeToolBoxColor * .5;
                xx(:) = nan;
                yy(:) = nan;

                obj.hSelObjHandles{2}.Visible = 'off';
            else
                pt1 = pts(4,:);
                pt2 = pts(6,:);
                z = 1;
                obj.hSelObjHandles{1}.MarkerFaceColor = obj.makeToolBoxColor * .5;
                obj.hSelObjHandles{3}.MarkerFaceColor = 'none';

                obj.hSelObjHandles{2}.XData = pts(5:6,1);
                obj.hSelObjHandles{2}.YData = pts(5:6,2);
                obj.hSelObjHandles{2}.Visible = most.gui.OnOff(obj.showHandles);
            end

            obj.hSelObjHandles{1}.XData = pt1(1);
            obj.hSelObjHandles{1}.YData = pt1(2);
            obj.hSelObjHandles{1}.ZData = z;
            obj.hSelObjHandles{1}.Visible = most.gui.OnOff(obj.showHandles);

            obj.hSelObjHandles{3}.XData = pt2(1);
            obj.hSelObjHandles{3}.YData = pt2(2);
            obj.hSelObjHandles{3}.ZData = z;
            obj.hSelObjHandles{3}.Visible = most.gui.OnOff(obj.showHandles);
        end

        if isempty(obj.drawData{iRoi})
            drawDat = {};
            drawDat{1} = surface(xx, yy, lnz * ones(2), ...
                'FaceColor',faceCol, ...
                'AlphaData',adata, ...
                'edgecolor',col1, ...
                'linestyle',surflinestyle, ...
                'linewidth',2,...
                'parent',obj.h2DMainViewAxes, ...
                'visible',vis, ...
                'ButtonDownFcn',@obj.roiHit, ...
                'UserData',hRoi.uuiduint64, ...
                'FaceAlpha','texturemap', ...
                'CData',cdata);
            drawDat{2} = line('XData',lxpts,'YData',lypts,'ZData',lnz*ones(size(lxpts)), ...
                'Parent',obj.h2DMainViewAxes, ...
                'LineStyle',linelinestyle, ...
                'Color',color,...
                'Marker',linemkrstyle, ...
                'MarkerFaceColor',col2, ...
                'MarkerEdgeColor',col2, ...
                'Markersize',10, ...
                'LineWidth',1.5, ...
                'visible',vis, ...
                'ButtonDownFcn',@obj.roiHit, ...
                'UserData',hRoi.uuiduint64);
            drawDat{3} = line('XData',slmx,'YData',slmy,'ZData',lnz*ones(size(slmx)), ...
                'Parent',obj.h2DMainViewAxes, ...
                'LineStyle',':', ...
                'Color',color,...
                'Marker',mk3, ...
                'MarkerFaceColor','none', ...
                'MarkerEdgeColor',color, ...
                'Markersize',ms3, ...
                'LineWidth',1, ...
                'visible',vis, ...
                'ButtonDownFcn',@obj.roiHit, ...
                'UserData',hRoi.uuiduint64);
            drawDat{4} = line('XData',wayxpts,'YData',wayypts,'ZData',waylnz*ones(size(wayxpts)), ...
                'Parent',obj.h2DMainViewAxes, ...
                'Color',color,...
                'LineWidth',1, ...
                'Hittest','off', ...
                'color',color);

            obj.drawData{iRoi} = drawDat;
        else
            obj.drawData{iRoi}{1}.EdgeColor = col1;
            obj.drawData{iRoi}{2}.MarkerEdgeColor = col2;
            obj.drawData{iRoi}{2}.MarkerFaceColor = col2;
            obj.drawData{iRoi}{2}.Color = color;

            obj.drawData{iRoi}{1}.UserData = hRoi.uuiduint64;
            obj.drawData{iRoi}{2}.UserData = hRoi.uuiduint64;

            obj.drawData{iRoi}{1}.XData = xx;
            obj.drawData{iRoi}{1}.YData = yy;
            obj.drawData{iRoi}{1}.ZData = lnz*ones(2);
            obj.drawData{iRoi}{1}.LineStyle = surflinestyle;
            obj.drawData{iRoi}{1}.Visible = vis;
            obj.drawData{iRoi}{1}.FaceColor = faceCol;
            obj.drawData{iRoi}{1}.AlphaData = adata;
            obj.drawData{iRoi}{1}.CData = cdata;

            obj.drawData{iRoi}{2}.XData = lxpts;
            obj.drawData{iRoi}{2}.YData = lypts;
            obj.drawData{iRoi}{2}.ZData = lnz*ones(size(lxpts));
            obj.drawData{iRoi}{2}.Visible = vis;

            obj.drawData{iRoi}{2}.LineStyle = linelinestyle;
            obj.drawData{iRoi}{2}.Marker = linemkrstyle;

            obj.drawData{iRoi}{3}.XData = slmx;
            obj.drawData{iRoi}{3}.YData = slmy;
            obj.drawData{iRoi}{3}.ZData = lnz*ones(size(slmx));
            obj.drawData{iRoi}{3}.Color = color;
            obj.drawData{iRoi}{3}.Marker = mk3;
            obj.drawData{iRoi}{3}.MarkerSize = ms3;
            obj.drawData{iRoi}{3}.MarkerEdgeColor = col2;
            obj.drawData{iRoi}{3}.LineStyle = linelinestyle;
            obj.drawData{iRoi}{3}.UserData = hRoi.uuiduint64;

            obj.drawData{iRoi}{4}.XData = wayxpts;
            obj.drawData{iRoi}{4}.YData = wayypts;
            obj.drawData{iRoi}{4}.ZData = waylnz*ones(size(wayxpts));
            obj.drawData{iRoi}{4}.Color = color;
        end

        if numel(hRoi.zs) < 1
            patchXData = [0 1];
            patchYData = [0 1];
            surfaceLineXData = [0 1];
            surfaceLineYData = [0 1];
            normalLineXData = [];
            normalLineYData = [];
            color = 'none';
            isPlaneVisible = false;
            patchMarker = 'none';
        else
            patchXData = [];
            pxdataE = [];
            patchYData = [];
            surfaceLineXData = [];
            surfaceLineYData = [];
            normalLineXData = [];
            normalLineYData = [];
            patchMarker = 'none';

            if obj.editorModeIsStim || obj.editorModeIsSlm
                if hRoi.scanfields(1).isPause
                    if hasNonPauseRois
                        path = obj.getStimPts(iRoi,hRoi.scanfields(1));

                        normalLineXData = [normalLineXData path.G(1,obj.projectionDim), ...
                            path.G(end,obj.projectionDim) nan];
                        normalLineYData = [normalLineYData path.Z(1) path.Z(end) nan];
                    end
                else
                    path = obj.getStimPts(iRoi,hRoi.scanfields(1));
                    pts = path.G(:,obj.projectionDim);

                    mnpts = min(pts);
                    mxpts = max(pts);

                    if hRoi.scanfields(1).isPark
                        normalLineXData = [normalLineXData pts(1) pts(end) nan];
                        normalLineYData = [normalLineYData path.Z(1) path.Z(end) nan];
                        mxpts = pts(end);
                        mnpts = mxpts - .00001;
                    end

                    if mnpts == mxpts
                        patchMarker = '.';
                        mnpts = mnpts - .00001;
                        surfaceLineXData = mnpts;
                        surfaceLineYData = hRoi.zs(1);
                    else
                        surfaceLineXData = [mnpts mxpts nan];
                        surfaceLineYData = [hRoi.zs(1) hRoi.zs(1) nan];
                    end
                end

                isPlaneVisible = false;
            else
                for iRoiZ = numel(hRoi.zs):-1:1
                    z = hRoi.zs(iRoiZ);

                    if isnan(z)
                        continue;
                    end

                    scanfield = hRoi.get(z);
                    if isa(scanfield, 'scanimage.mroi.scanfield.fields.IntegrationField')
                        hsz = scanfield.sizeXY / 2;
                        pts = [-hsz; -hsz(1) hsz(2); hsz(1) -hsz(2); hsz];
                        rot = -scanfield.rotationDegrees * pi / 180;
                        R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
                        pts = scanimage.mroi.util.xformPoints(pts,R) + repmat(scanfield.centerXY,4,1);
                    else
                        pts = scanfield.cornerpoints();
                    end
                    pts = pts(:,obj.projectionDim);

                    patchXData(iRoiZ) = min(pts);
                    pxdataE(iRoiZ) = max(pts);
                    patchYData(iRoiZ) = z;
                    surfaceLineXData = [surfaceLineXData patchXData(iRoiZ) pxdataE(iRoiZ) nan];
                    surfaceLineYData = [surfaceLineYData z z nan];
                end

                if hRoi.discretePlaneMode
                    isPlaneVisible = false;
                else
                    isPlaneVisible = vistf;
                    if numel(hRoi.zs) == 1
                        patchXData = repmat(patchXData,1,2);
                        pxdataE = repmat(pxdataE,1,2);
                        patchYData = [nInf pInf];
                    end
                end

                %light dotted line down the middle
                if ~(obj.editorModeIsStim || obj.editorModeIsSlm)
                    normalLineXData = (patchXData + pxdataE) * .5;
                    normalLineYData = patchYData;
                end

                patchXData = [patchXData fliplr(pxdataE)];
                patchYData = [patchYData fliplr(patchYData)];
            end
        end

        if ~isPlaneVisible
            patchXData = [];
            patchYData = [];
        end
        planeVisibilityFlag = most.gui.OnOff(isPlaneVisible);

        if isempty(obj.drawDataProj{iRoi})
            Patch = patch( ...
                'xdata',patchXData,'ydata',patchYData,'zdata',.45*ones(size(patchXData)), ...
                'FaceColor','none', ...
                'edgecolor',color,...
                'linestyle','--','linewidth',2, ...
                'parent',obj.h2DProjectionViewAxes, ...
                'visible',planeVisibilityFlag, ...
                'UserData',hRoi.uuiduint64, ...
                'ButtonDownFcn',@obj.roiProjPatchHit);
            SurfaceLine = line( ...
                'xdata',surfaceLineXData,'ydata',surfaceLineYData,'zdata',lnz*ones(size(surfaceLineXData)), ...
                'Color',color,...
                'Parent',obj.h2DProjectionViewAxes, ...
                'linewidth',4, ...
                'visible',vis, ...
                'UserData',hRoi.uuiduint64, ...
                'ButtonDownFcn',@obj.roiProjLineHit);
            SurfaceNormalLine = line( ...
                'xdata',normalLineXData,'ydata',normalLineYData,'zdata',.4*ones(size(normalLineXData)), ...
                'Color',color, ...
                'linestyle',':',...
                'Parent',obj.h2DProjectionViewAxes, ...
                'linewidth',1, ...
                'visible',vis, ...
                'UserData',hRoi.uuiduint64, ...
                'ButtonDownFcn',@obj.roiProjPatchHit);

            SlmStimPoint = line('XData',pslmx,'YData',pslmz,'ZData',lnz*ones(size(pslmx)), ...
                'Parent',obj.h2DProjectionViewAxes, ...
                'LineStyle',':', ...
                'Color',color,...
                'Marker','h', ...
                'MarkerFaceColor','k', ...
                'MarkerEdgeColor',color, ...
                'Markersize',ms3, ...
                'LineWidth',1, ...
                'visible',vis, ...
                'ButtonDownFcn',@obj.slmPointProjHit, ...
                'UserData',hRoi.uuiduint64);

            obj.drawDataProj{iRoi} = {Patch, SurfaceLine, SurfaceNormalLine, SlmStimPoint};
        else
            Patch = obj.drawDataProj{iRoi}{1};
            SurfaceLine = obj.drawDataProj{iRoi}{2};
            SurfaceNormalLine = obj.drawDataProj{iRoi}{3};
            SlmStimPoint = obj.drawDataProj{iRoi}{4};

            set(Patch, 'EdgeColor', color);
            set([SurfaceLine, SurfaceNormalLine, SlmStimPoint], 'Color', color);

            set([Patch, SurfaceLine, SurfaceNormalLine,SlmStimPoint], 'UserData', hRoi.uuiduint64);

            set(Patch, ...
                'XData', patchXData, ...
                'YData', patchYData, ...
                'ZData', .45 * ones(size(patchXData)), ...
                'Visible', planeVisibilityFlag);

            set(SurfaceLine, ...
                'XData', surfaceLineXData, ...
                'YData', surfaceLineYData, ...
                'ZData', lnz * ones(size(surfaceLineXData)), ...
                'Visible', vis, ...
                'Marker', patchMarker, ...
                'MarkerSize', 20);

            set(SurfaceNormalLine, ...
                'XData', normalLineXData, ...
                'YData', normalLineYData, ...
                'ZData', .4 * ones(size(normalLineXData)), ...
                'Visible', vis);

            set(SlmStimPoint, ...
                'XData', pslmx, ...
                'YData', pslmz, ...
                'ZData', .45 * ones(size(pslmx)), ...
                'Visible', 'on',...
                'MarkerEdgeColor',color,...
                'MarkerFaceColor','k');
        end
    end

    if ~isSelectedRoiDrawn
        cellfun(@(x)set(x,'Visible','off'),obj.hSelObjHandles);
    end

    if numel(obj.drawData) > nRois
        cellfun(@delete, horzcat(obj.drawData{nRois+1:end}));
        cellfun(@delete, horzcat(obj.drawDataProj{nRois+1:end}));

        obj.drawData(nRois+1:end) = [];
        obj.drawDataProj(nRois+1:end) = [];

        obj.drawData(end+1) = {{}};
        obj.drawDataProj(end+1) = {{}};
    end
end

function tf = isStimulusField(sf)
    tf = ~isempty(sf) && isa(sf,'scanimage.mroi.scanfield.fields.StimulusField');
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

function roiManip(obj,stop,varargin)
    persistent op;
    persistent ppt;
    persistent orat;
    persistent nPattern;
    persistent objs;
    persistent allRoiMove;
    persistent xsnaps;
    persistent ysnaps;
    persistent unSnappedPos;

    if nargin > 2
        if obj.editorModeIsStim && isa(obj.scannerSet,'scanimage.mroi.scannerset.SLM')
            % slm patterns can't move. do nothing
            return;
        end

        %make sure the scanfield is selected, not the roi
        if ~(obj.editorModeIsStim || obj.editorModeIsSlm)
            if isa(obj.selectedObj, 'scanimage.mroi.Roi')
                if ismember(obj.editorZ, obj.selectedObj.zs)
                    obj.changeSelection(obj.selectedObj.get(obj.editorZ),obj.selectedObj);
                    obj.fixTableCheck();
                else
                    obj.editOrCreateScanfieldAtZ();
                end
            end
        end

        op = stop.UserData;
        ppt = most.gui.getPointerLocation(obj.h2DMainViewAxes);

        modif = get(obj.hFig, 'currentModifier');
        fullRoiMove = false;
        allRoiMove = false;
        if ismember('shift', modif)
            fullRoiMove = true;
        elseif ismember('control', modif) && strcmp(op,'move')
            r = obj.selectedObjParent.copy;

            obj.enableListeners = false;
            obj.editingGroup.add(r);
            obj.enableListeners = true;

            if obj.editorModeIsStim
                obj.updateScanPathCache();
            end
            obj.changeSelection(r.get(obj.editorZ),r);
            fullRoiMove = true;
        elseif ismember('alt', modif) && strcmp(op,'move')
            allRoiMove = true;
        end

        if fullRoiMove
            objs = obj.selectedObjParent.scanfields;
        elseif allRoiMove
            objs = [obj.editingGroup.rois.scanfields];
        else
            objs = obj.selectedObj;
        end

        xsnaps = [];
        ysnaps = [];
        unSnappedPos = obj.selectedObj.centerXY;
        % special handling of line stimulus function to make it easier to draw
        if isa(obj.selectedObj, 'scanimage.mroi.scanfield.fields.StimulusField') ...
                && strcmp(func2str(obj.selectedObj.stimfcnhdl), 'scanimage.mroi.stimulusfunctions.line')
            switch op
                case 'move'

                case 'size' % size is the bottom left corner handle for line function
                    op = 'bottomLeft';

                    % store the top right coords. this point should stay fixed
                    rot = -obj.selectedObj.rotationDegrees * pi / 180;
                    R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
                    orat = obj.selectedObj.centerXY + (scanimage.mroi.util.xformPoints(obj.selectedObj.sizeXY .* [.5 -.5],R));

                case 'rotate' % rotate is the top right corner handle for line function
                    op = 'topRight';

                    % store the bottom left coords. this point should stay fixed
                    rot = -obj.selectedObj.rotationDegrees * pi / 180;
                    R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
                    orat = obj.selectedObj.centerXY + (scanimage.mroi.util.xformPoints(obj.selectedObj.sizeXY .* [-.5 .5],R));
            end
        else
            switch op
                case 'move'
                    % come up with a list of interesting points that the drag operatoin should snap to
                    % for each dimension, the snap points are in the following logical format:
                    % when dragging in dimension X, when Y in within range [rl rh], snap when approaching s1

                    % only snap when there is no rotation
                    rot = obj.selectedObj.rotationDegrees;
                    if ~mod(rot,90)
                        hsz = obj.selectedObj.sizeXY/2;
                        if mod(rot, 180)
                            % if rotated 90 deg, reverse xy size to
                            % snap properly
                            hsz = fliplr(hsz);
                        end

                        tol = obj.mainViewFov/100;

                        % snap to FOV edges and center
                        xsnaps = addSnap(xsnaps,[-inf inf],obj.fovGridxx(1)+hsz(1),obj.fovGridxx(1));
                        xsnaps = addSnap(xsnaps,[-inf inf],obj.fovGridxx(3)-hsz(1),obj.fovGridxx(3));
                        m = (obj.fovGridxx(1)+obj.fovGridxx(3))/2;
                        xsnaps = addSnap(xsnaps,[-inf inf],m,m);

                        ysnaps = addSnap(ysnaps,[-inf inf],obj.fovGridyy(1)+hsz(2),obj.fovGridyy(1));
                        ysnaps = addSnap(ysnaps,[-inf inf],obj.fovGridyy(2)-hsz(2),obj.fovGridyy(2));
                        m = (obj.fovGridyy(1)+obj.fovGridyy(2))/2;
                        ysnaps = addSnap(ysnaps,[-inf inf],m,m);

                        % snap to other rois
                        for r = obj.editingGroup.rois
                            s = r.get(obj.editorZ);
                            if ~isempty(s) && ~ismember(s,objs) && ~mod(s.rotationDegrees,90) && (~obj.editorModeIsStim || ~(s.isPause || s.isPark)) && ~obj.editorModeIsSlm
                                shsz = 0.5 * s.sizeXY;
                                if mod(s.rotationDegrees, 180)
                                    % if rotated 90 deg, reverse xy size to
                                    % snap properly
                                    shsz = fliplr(shsz);
                                end

                                % X
                                rng = s.centerXY(2) + (shsz(2) + hsz(2)) * [-1 1] - [tol -tol];
                                % adjacent edges
                                xsnaps = addSnap(xsnaps,rng,s.centerXY(1)+shsz(1)+hsz(1),s.centerXY(1)+shsz(1));
                                xsnaps = addSnap(xsnaps,rng,s.centerXY(1)-shsz(1)-hsz(1),s.centerXY(1)-shsz(1));
                                % center
                                xsnaps = addSnap(xsnaps,rng,s.centerXY(1),s.centerXY(1));
                                % matching edges (only needed if size is not identical)
                                xsnaps = addSnap(xsnaps,rng,s.centerXY(1)-shsz(1)+hsz(1),s.centerXY(1)-shsz(1));
                                xsnaps = addSnap(xsnaps,rng,s.centerXY(1)+shsz(1)-hsz(1),s.centerXY(1)+shsz(1));

                                % X
                                rng = s.centerXY(1) + (shsz(1) + hsz(1)) * [-1 1] - [tol -tol];
                                % adjacent edges
                                ysnaps = addSnap(ysnaps,rng,s.centerXY(2)+shsz(2)+hsz(2),s.centerXY(2)+shsz(2));
                                ysnaps = addSnap(ysnaps,rng,s.centerXY(2)-shsz(2)-hsz(2),s.centerXY(2)-shsz(2));
                                % center
                                ysnaps = addSnap(ysnaps,rng,s.centerXY(2),s.centerXY(2));
                                % matching edges (only needed if size is not identical)
                                ysnaps = addSnap(ysnaps,rng,s.centerXY(2)-shsz(2)+hsz(2),s.centerXY(2)-shsz(2));
                                ysnaps = addSnap(ysnaps,rng,s.centerXY(2)+shsz(2)-hsz(2),s.centerXY(2)+shsz(2));
                            end
                        end
                    end

                case 'size'
                    obj.hFig.Pointer = 'botr';
                    savePixRatio();

                case 'rotate'
                    obj.hFig.Pointer = 'cross';
            end
        end

        % this is for maintaining slm points while dragging galvo position. dont do this if the pattern is a bitmap
        nPattern = isa(obj.selectedObj, 'scanimage.mroi.scanfield.fields.StimulusField') ...
            && ~isempty(obj.selectedObj.slmPattern) ...
            && (size(obj.selectedObj.slmPattern,2) < 5);
        if nPattern
            nPattern = size(obj.selectedObj.slmPattern,1);
        end

        set(obj.hFig,'WindowButtonMotionFcn',@(varargin)obj.roiManip(false),'WindowButtonUpFcn',@(varargin)obj.roiManip(true));
        waitfor(obj.hFig,'WindowButtonMotionFcn',[]);
    elseif stop
        set(obj.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
        if ~obj.createMode
            obj.hFig.Pointer = 'arrow';
        end

        obj.enableListeners = false;
        obj.satisfyConstraints(obj.selectedObj);
        coercePixRatio();

        if obj.editorModeIsSlm
            obj.updateSlmPattern();
        end

        obj.hSnapLineX.Visible = 'off';
        obj.hSnapLineY.Visible = 'off';
        obj.hSnapLineR.Visible = 'off';

        obj.enableListeners = true;
        obj.rgChangedPar();
        obj.selectedObjChanged();
    else
        nwpt = most.gui.getPointerLocation(obj.h2DMainViewAxes);
        obj.enableListeners = false;
        switch op
            case 'move'
                %snap
                delt = nwpt - ppt;
                unSnappedPos = unSnappedPos + delt;
                npos = unSnappedPos;
                tol = obj.mainViewFov/100;

                dontSnap = ismember('alt', get(obj.hFig, 'currentModifier'));

                if ~isempty(xsnaps) && ~dontSnap
                    ac = arrayfun(@(sn)(npos(2) >= sn.range(1))&&(npos(2) <= sn.range(2)),xsnaps);
                    acsnaps = xsnaps(ac);
                    dists = abs(npos(1) - [acsnaps.point]);
                    [d,i] = min(dists);

                    if d < tol
                        npos(1) = acsnaps(i).point;
                        msnaps = abs([acsnaps.point] - npos(1)) < 1e-10;

                        clns = [acsnaps(msnaps).contextLine];
                        clns = [clns; clns; nan(size(clns))];

                        ys = nan(size(clns));
                        ys(1,:) = -999999;
                        ys(2,:) = 999999;

                        zs = 2*ones(size(ys));

                        obj.hSnapLineX.Visible = 'on';
                        obj.hSnapLineX.XData = clns(:);
                        obj.hSnapLineX.YData = ys(:);
                        obj.hSnapLineX.ZData = zs(:);
                    else
                        obj.hSnapLineX.Visible = 'off';
                    end
                else
                    obj.hSnapLineX.Visible = 'off';
                end

                if ~isempty(ysnaps) && ~dontSnap
                    ac = arrayfun(@(sn)(npos(1) >= sn.range(1))&&(npos(1) <= sn.range(2)),ysnaps);
                    acsnaps = ysnaps(ac);
                    dists = abs(npos(2) - [acsnaps.point]);
                    [d,i] = min(dists);

                    if d < tol
                        npos(2) = acsnaps(i).point;
                        msnaps = abs([acsnaps.point] - npos(2)) < 1e-10;

                        clns = [acsnaps(msnaps).contextLine];
                        clns = [clns; clns; nan(size(clns))];

                        xs = nan(size(clns));
                        xs(1,:) = -999999;
                        xs(2,:) = 999999;

                        zs = 2*ones(size(xs));

                        obj.hSnapLineY.Visible = 'on';
                        obj.hSnapLineY.XData = xs(:);
                        obj.hSnapLineY.YData = clns(:);
                        obj.hSnapLineY.ZData = zs(:);
                    else
                        obj.hSnapLineY.Visible = 'off';
                    end
                else
                    obj.hSnapLineY.Visible = 'off';
                end

                delt = npos - obj.selectedObj.centerXY;

                arrayfun(@(ob)setposdel(ob, delt),objs);
                if nPattern && ~ismember('shift', get(obj.hFig, 'currentModifier'))
                    obj.selectedObj.slmPattern(:,1:2) = obj.selectedObj.slmPattern(:,1:2) - repmat(delt,nPattern,1);
                end
                ppt = nwpt;

            case 'size'
                c = obj.selectedObj.centerXY;

                rot = obj.selectedObj.rotationDegrees * pi / 180;
                R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
                nsz = (scanimage.mroi.util.xformPoints(nwpt-c,R)) * 2;

                if isa(obj.scannerSet,'scanimage.mroi.scannerset.ResonantGalvoGalvo')
                    if obj.hModel.hScan2D.isPolygonalScanning
                        obj.hModel.hScan2D.fillFractionSpatial = nsz(1)/obj.scannerSet.scanners{1}.fullAngleDegrees;
                    else
                        nsz(1) = min(nsz(1), obj.scannerSet.scanners{1}.fullAngleDegrees*obj.scannerSet.scanners{1}.fillFractionSpatial);
                    end
                end

                obj.selectedObj.sizeXY(~obj.locks) = nsz(~obj.locks);
                if obj.editorModeIsSlm
                    for roi = obj.editingGroup.rois
                        if ~isempty(roi.scanfields)
                            roi.scanfields(1).sizeXY = nsz;
                        end
                    end
                    obj.slmPatternSfParent.sizeXY = nsz;
                end
                coercePixRatio();

            case 'rotate'
                xy = nwpt-obj.selectedObj.centerXY;
                th = atand(-xy(1)/xy(2));

                if xy(2) < 0
                    th = floor(th);
                else
                    th = floor(180+th);
                end
                if ~ismember('alt', get(obj.hFig, 'currentModifier'))
                    m = th / 15;

                    if abs(m - round(m)) < 0.3
                        th = round(m) * 15;

                        thd = th-90;
                        p1 = obj.selectedObj.centerXY;
                        p2 = p1 + 9999999*[cosd(thd) sind(thd)];
                        obj.hSnapLineR.XData = [p1(1) p2(1)];
                        obj.hSnapLineR.YData = [p1(2) p2(2)];
                        obj.hSnapLineR.Visible = 'on';
                    else
                        obj.hSnapLineR.Visible = 'off';
                    end
                else
                    obj.hSnapLineR.Visible = 'off';
                end

                obj.selectedObj.rotation = th;

                obj.hSelObjHandles{2}.XData(2) = nwpt(1);
                obj.hSelObjHandles{2}.YData(2) = nwpt(2);
                obj.hSelObjHandles{3}.XData = nwpt(1);
                obj.hSelObjHandles{3}.YData = nwpt(2);

            case 'bottomLeft'
                obj.selectedObj.centerXY = (orat + nwpt) / 2;
                obj.selectedObj.sizeXY = (orat - nwpt) .* [1 -1];
                obj.selectedObj.rotation = 0;

            case 'topRight'
                obj.selectedObj.centerXY = (orat + nwpt) / 2;
                obj.selectedObj.sizeXY = (orat - nwpt) .* [-1 1];
                obj.selectedObj.rotation = 0;
        end

        if allRoiMove
            upInds = {};
        else
            upInds = {obj.selectedObjRoiIdx};
        end

        obj.updateScanPathCache(upInds{:});
        obj.updateDisplay(upInds{:});
        obj.enableListeners = true;
        obj.selectedObjChanged();
    end

    function savePixRatio()
        if isa(obj.selectedObj, 'scanimage.mroi.scanfield.ImagingField') && ...
                strcmp(op, 'size') && strcmp(obj.scanfieldResizeMaintainPixelProp, 'ratio')
            orat = obj.selectedObj.pixelRatio;
        end
    end

    function coercePixRatio()
        if isa(obj.selectedObj, 'scanimage.mroi.scanfield.ImagingField') && ...
                strcmp(op, 'size') && strcmp(obj.scanfieldResizeMaintainPixelProp, 'ratio')
            obj.selectedObj.pixelRatio = orat;
            obj.selectedObj.pixelResolutionXY = ceil(obj.selectedObj.pixelResolutionXY/2)*2;
        end
    end
end

function setposdel(o,d)
    o.centerXY = o.centerXY + d;
end

function snaps = addSnap(snaps, range, point, contextLine)
    if isempty(snaps)
        snaps = struct('range',range,'point',point,'contextLine',contextLine);
    else
        mtch = find(arrayfun(@(sn)(all(sn.range == range) && (sn.point == point)),snaps),1);
        if isempty(mtch)
            snaps(end+1) = struct('range',range,'point',point,'contextLine',contextLine);
        else
            snaps(mtch).contextLine = union(snaps(mtch(1)).contextLine,contextLine);
        end
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

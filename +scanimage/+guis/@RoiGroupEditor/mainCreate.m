function mainCreate(obj,stop,varargin)
    persistent oppt;
    persistent ocenterxy;
    persistent centerxy;
    persistent hsz;
    persistent olocks;
    persistent hMakeToolSquare;
    persistent hMakeToolX;
    persistent hMakeToolO;
    persistent hMakeToolL;
    persistent hMakeToolR;
    persistent hMakeToolPath;
    persistent makeToolPathNomPts;

    if nargin > 2
        oppt = most.gui.getPointerLocation(obj.h2DMainViewAxes);

        if obj.editorModeIsSlm
            obj.createRoi(oppt,obj.slmPatternSfParent.sizeXY,obj.editorZ,1);
            obj.roiManip(struct('UserData','move'),[]);
        elseif obj.editorModeIsStim && strcmp(obj.defaultStimFunction, 'point') && obj.scannersetIsSlm
            obj.selectedObjParent = [];
            obj.editSlmPattern();
            obj.slmPatternRoiGroupParent.add(obj.slmPatternRoiParent);

            obj.newRoi();
            obj.createRoi(oppt,obj.defaultRoiSize);
            obj.roiManip(struct('UserData','move'),[]);
        else
            hsz = [obj.defaultRoiWidth obj.defaultRoiHeight]/2;
            switch obj.newRoiDrawMode
                case 'top left rectangle'
                    centerxy = hsz;

                case 'center point rectangle'
                    centerxy = [0 0];

                case 'cell picker'
                    return;
            end

            handleLen = diff(obj.h2DMainViewAxes.YLim) / 40;

            pts = [centerxy-hsz;...
                centerxy+[-hsz(1) hsz(2)];...
                centerxy+[hsz(1) -hsz(2)];...
                centerxy+hsz;...
                centerxy;...
                centerxy-[0 hsz(2)+handleLen]];
            rot = -obj.defaultRoiRotation * pi / 180;
            R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
            pts = scanimage.mroi.util.xformPoints(pts,R);
            pts = pts + repmat(oppt,6,1);
            ocenterxy = pts(5,:);
            centerxy = ocenterxy;

            xx = [pts(1:2,1) pts(3:4,1)];
            yy = [pts(1:2,2) pts(3:4,2)];
            hMakeToolSquare = surface(xx, yy, ones(2), ...
                'FaceColor','none', ...
                'edgecolor',obj.makeToolBoxColor, ...
                'linewidth',1, ...
                'parent',obj.h2DMainViewAxes);
            hMakeToolX = line(pts(5,1),pts(5,2),1, ...
                'Parent',obj.h2DMainViewAxes, ...
                'LineStyle','none', ...
                'Marker','x', ...
                'MarkerEdgeColor',obj.makeToolBoxColor, ...
                'Markersize',10, ...
                'LineWidth',1.5);
            hMakeToolO = line(pts(4,1),pts(4,2),1, ...
                'Parent',obj.h2DMainViewAxes, ...
                'LineStyle','none', ...
                'Marker','o', ...
                'MarkerEdgeColor',obj.makeToolBoxColor, ...
                'MarkerFaceColor',obj.makeToolBoxColor*.5, ...
                'Markersize',8, ...
                'LineWidth',1.5);
            hMakeToolL = line(pts(5:6,1), pts(5:6,2),[1;1], ...
                'Parent',obj.h2DMainViewAxes, ...
                'LineStyle','--', ...
                'Marker','none', ...
                'Color',obj.makeToolBoxColor, ...
                'Markersize',8, ...
                'LineWidth',1.5);
            hMakeToolR = line(pts(6,1),pts(6,2),1, ...
                'Parent',obj.h2DMainViewAxes, ...
                'LineStyle','none', ...
                'Marker','o', ...
                'MarkerEdgeColor',obj.makeToolBoxColor, ...
                'MarkerFaceColor',[0 0 0], ...
                'Markersize',8, ...
                'LineWidth',1.5);

            if obj.editorModeIsStim
                stimFunctionHandle = sprintf('scanimage.mroi.stimulusfunctions.%s', ...
                    obj.defaultStimFunction);
                stimDuration = obj.defaultStimDuration / 1000;
                numRepetitions = 1;
                fieldCenterPoint = [0 0];
                fieldScaling = [1 1];
                fieldRotationDegrees = 0;
                stimulationPowerPercent = 0;
                sf = scanimage.mroi.scanfield.fields.StimulusField( ...
                    stimFunctionHandle, ...
                    obj.defaultStimFunctionArgs, ...
                    stimDuration, ...
                    numRepetitions,...
                    fieldCenterPoint,...
                    fieldScaling,...
                    fieldRotationDegrees,...
                    stimulationPowerPercent);
                % dzdt is only used for beams generation at the moment, so it's not really
                % relevant here
                [path_FOV,~] = obj.scannerSet.scanPathStimulusFOV(sf,0,obj.editorZ,0, ...
                    false,false,obj.stimpathRenderMaxPoints);
                makeToolPathNomPts = path_FOV.G;

                pts = scanimage.mroi.util.xformPoints(makeToolPathNomPts,R);
                pts = [pts(:,1)*hsz(1) pts(:,2)*hsz(2)] + repmat(ocenterxy,length(pts),1);
                hMakeToolPath = line( ...
                    'XData',pts(:,1), ...
                    'YData',pts(:,2), ...
                    'ZData',1.1*ones(length(pts),1), ...
                    'Parent',obj.h2DMainViewAxes, ...
                    'LineStyle','-', ...
                    'Marker','none', ...
                    'Color',most.constants.Colors.green, ...
                    'LineWidth',1);
                delete(sf);
            end

            olocks = obj.locks & [~obj.drawArray true];

            set(obj.hFig,...
                'WindowButtonMotionFcn',@(varargin)obj.mainCreate(false),...
                'WindowButtonUpFcn',@(varargin)obj.mainCreate(true));
            waitfor(obj.hFig,'WindowButtonMotionFcn',[]);
        end
    elseif stop
        set(obj.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);

        most.idioms.safeDeleteObj(hMakeToolSquare);
        most.idioms.safeDeleteObj(hMakeToolX);
        most.idioms.safeDeleteObj(hMakeToolO);
        most.idioms.safeDeleteObj(hMakeToolL);
        most.idioms.safeDeleteObj(hMakeToolR);
        most.idioms.safeDeleteObj(hMakeToolPath);

        sz = hsz*2;
        sz(olocks) = obj.defaultRoiSize(olocks);
        if obj.canDrawArray && obj.drawArray
            if obj.locks(1)
                nsz = obj.defaultRoiWidth;
                N = ceil(sz(1) / nsz);
                sz(1) = nsz * N;
            else
                scannerInfo = obj.scannerSet.scanners{1};
                nsz = scannerInfo.fullAngleDegrees * scannerInfo.fillFractionSpatial;
                N = ceil(sz(1) / nsz);
                nsz = sz(1) / N;
            end

            fl = centerxy(1) - sz(1)/2 + nsz/2;
            sz(1) = nsz;
            for i = 0:(N-1)
                obj.createRoi([(fl + i*nsz) centerxy(2)],sz);
            end
        else
            obj.createRoi(centerxy,sz);
        end
    else
        nwpt = most.gui.getPointerLocation(obj.h2DMainViewAxes);

        % special handling of line stimulus function to make it easier to draw
        if obj.editorModeIsStim && strcmp(obj.defaultStimFunction, 'line')
            hMakeToolSquare.ZData(:) = nan;
            hMakeToolX.ZData(:) = nan;
            hMakeToolL.ZData(:) = nan;
            R = eye(3);
            switch obj.newRoiDrawMode
                case 'top left rectangle'
                    centerxy = (oppt+nwpt)/2;
                    hsz = [1 -1] .* (oppt-nwpt)/2;

                case 'center point rectangle'
                    centerxy = oppt;
                    hsz = [1 -1] .* (oppt-nwpt);
            end
            tl = centerxy+hsz.*[-1 1];
            br = centerxy-hsz.*[-1 1];
            hMakeToolO.XData = tl(1);
            hMakeToolO.YData = tl(2);
            hMakeToolO.ZData = 2;
            hMakeToolR.XData = br(1);
            hMakeToolR.YData = br(2);
            hMakeToolR.ZData = 2;
        else
            switch obj.newRoiDrawMode
                case 'top left rectangle'
                    centerxy = (oppt+nwpt)/2;

                case 'center point rectangle'
                    centerxy = oppt;
            end
            % unrotate to find desired xy size
            relpt = nwpt - centerxy;
            rot = -obj.defaultRoiRotation * pi / 180;
            R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
            hsz = abs(scanimage.mroi.util.xformPoints(relpt,R,true));

            % contrain minimum drag size
            if hsz < (diff(obj.h2DMainViewAxes.YLim) / 200);
                centerxy = ocenterxy;
                hsz = [obj.defaultRoiWidth obj.defaultRoiHeight]/2;
                flwMouse = false;
            else
                flwMouse = true;
            end

            % if resonant constrain maximum size
            if isa(obj.scannerSet,'scanimage.mroi.scannerset.ResonantGalvoGalvo') ...
                    && ~(obj.drawArray && obj.canDrawArray)
                scannerInfo = obj.scannerSet.scanners{1};
                hsz(1) = min(hsz(1), ...
                    scannerInfo.fullAngleDegrees * scannerInfo.fillFractionSpatial / 2);
            end

            hsz(olocks) = obj.defaultRoiSize(olocks)/2;
            centerxy(olocks) = ocenterxy(olocks);

            %find new points
            handleLen = diff(obj.h2DMainViewAxes.YLim) / 40;
            pts = [-hsz; -hsz(1) hsz(2); hsz(1) -hsz(2); hsz; 0 0; 0 -hsz(2)-handleLen];
            rot = -obj.defaultRoiRotation * pi / 180;
            R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
            pts = scanimage.mroi.util.xformPoints(pts,R);
            pts = pts + repmat(centerxy,6,1);

            xx = [pts(1:2,1) pts(3:4,1)];
            yy = [pts(1:2,2) pts(3:4,2)];
            hMakeToolSquare.XData = xx;
            hMakeToolSquare.YData = yy;
            hMakeToolX.XData = pts(5,1);
            hMakeToolX.YData = pts(5,2);
            if flwMouse
                hMakeToolO.XData = nwpt(1);
                hMakeToolO.YData = nwpt(2);
            else
                hMakeToolO.XData = pts(4,1);
                hMakeToolO.YData = pts(4,2);
            end
            hMakeToolL.XData = pts(5:6,1);
            hMakeToolL.YData = pts(5:6,2);
            hMakeToolR.XData = pts(6,1);
            hMakeToolR.YData = pts(6,2);
        end

        if obj.editorModeIsStim
            pts = [makeToolPathNomPts(:,1)*hsz(1) makeToolPathNomPts(:,2)*hsz(2)];
            pts = scanimage.mroi.util.xformPoints(pts,R) + repmat(centerxy,length(makeToolPathNomPts),1);

            hMakeToolPath.XData = pts(:,1);
            hMakeToolPath.YData = pts(:,2);
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

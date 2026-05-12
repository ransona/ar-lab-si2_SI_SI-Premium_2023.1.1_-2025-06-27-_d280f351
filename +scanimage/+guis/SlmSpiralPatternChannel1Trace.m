classdef SlmSpiralPatternChannel1Trace < handle
    properties (Access = private)
        hSI;
        center_um;
        center_index = [];
        diameter_um;
        enablePlot = false;
        maxPlotSamples = 1000;
        preallocSamples = 5000000;
        growthChunkSamples = 1000000;
        hFig;
        hAx;
        hLine;
        hTimer;
        mask;
        lastFrameNumber = -inf;
        t0;
        times = [];
        values = [];
        nSamples = 0;
        stimLines = [];
        stimTimes = [];
        ownsFigure = true;
    end

    methods
        function obj = SlmSpiralPatternChannel1Trace(hSI, center_um, diameter_um, hAx, center_index, enablePlot)
            obj.hSI = hSI;
            obj.center_um = center_um;
            obj.diameter_um = diameter_um;
            if nargin >= 5
                obj.center_index = center_index;
            end
            if nargin >= 6 && ~isempty(enablePlot)
                obj.enablePlot = logical(enablePlot);
            elseif nargin >= 4 && ~isempty(hAx) && isgraphics(hAx, 'axes')
                % Backward compatible behavior for legacy callers passing an axes handle only.
                obj.enablePlot = true;
            end

            if ~obj.enablePlot
                obj.ownsFigure = false;
                obj.hAx = [];
                obj.hFig = [];
                obj.hLine = [];
            elseif nargin >= 4 && ~isempty(hAx) && isgraphics(hAx, 'axes')
                obj.ownsFigure = false;
                obj.hAx = hAx;
                obj.hFig = ancestor(hAx, 'figure');
                cla(obj.hAx);
            else
                figName = sprintf('SLM Center Ch1 Timeseries (%.1f, %.1f)', center_um(1), center_um(2));
                obj.hFig = figure('Name',figName,'NumberTitle','off', ...
                    'Color','w','CloseRequestFcn',@(src,~)scanimage.guis.SlmSpiralPatternChannel1Trace.safeCloseFig(src, obj));
                obj.hAx = axes('Parent',obj.hFig);
            end
            if obj.enablePlot
                obj.hLine = plot(obj.hAx, nan, nan, 'b-');
                grid(obj.hAx,'on');
                xlabel(obj.hAx,'Time (s)');
                ylabel(obj.hAx,'Ch1 Mean (a.u.)');
                title(obj.hAx, sprintf('Center %.1f, %.1f um', center_um(1), center_um(2)));
            end
        end

        function start(obj, useInternalTimer, initializeMask)
            if nargin < 2 || isempty(useInternalTimer)
                useInternalTimer = true;
            end
            if nargin < 3 || isempty(initializeMask)
                initializeMask = true;
            end
            obj.stop();
            obj.resetData();
            if initializeMask
                obj.mask = obj.buildMask();
            else
                obj.mask = [];
            end
            obj.t0 = tic;
            if ~useInternalTimer
                return;
            end
            obj.hTimer = timer( ...
                'Name','SlmSpiralCh1Trace', ...
                'ExecutionMode','fixedSpacing', ...
                'Period',0.05, ...
                'TimerFcn',@(~,~)obj.onTick());
            start(obj.hTimer);
        end

        function stop(obj)
            try
                if ~isempty(obj.hTimer) && isvalid(obj.hTimer)
                    stop(obj.hTimer);
                    delete(obj.hTimer);
                end
            catch
            end
            obj.hTimer = [];
        end

        function t = markStim(obj, t, color)
            t = [];
            if nargin < 2 || isempty(t)
                if isempty(obj.t0)
                    return;
                end
                t = toc(obj.t0);
            end
            if nargin < 3 || isempty(color)
                color = [1 0 0];
            end
            obj.stimTimes(end+1,1) = t; %#ok<AGROW>
            if isempty(obj.hAx) || ~isvalid(obj.hAx)
                return;
            end
            yl = obj.hAx.YLim;
            h = line(obj.hAx, [t t], yl, 'Color',color, 'LineStyle','--', 'LineWidth',1);
            obj.stimLines = [obj.stimLines; h];
        end

        function delete(obj)
            obj.stop();
        end

        function closeFigure(obj)
            if obj.enablePlot && obj.ownsFigure
                scanimage.guis.SlmSpiralPatternChannel1Trace.safeCloseFig(obj.hFig, obj);
            else
                obj.stop();
            end
        end

        function data = getData(obj)
            data = struct();
            n = obj.nSamples;
            data.times_s = obj.times(1:n);
            data.values = obj.values(1:n);
            data.stim_times_s = obj.stimTimes;
            data.center_um = obj.center_um;
            data.center_index = obj.center_index;
            data.diameter_um = obj.diameter_um;
        end

        function processFrame(obj, frameNum, img, updatePlot)
            if nargin < 4 || isempty(updatePlot)
                updatePlot = true;
            end
            if nargin < 3 || isempty(img)
                return;
            end
            if nargin < 2 || isempty(frameNum) || ~isfinite(frameNum)
                return;
            end
            if frameNum == obj.lastFrameNumber
                return;
            end
            obj.lastFrameNumber = frameNum;

            if isempty(obj.mask) || ~isequal(size(img), size(obj.mask))
                if isequal(size(img), fliplr(size(obj.mask)))
                    obj.mask = obj.mask';
                else
                    obj.mask = obj.buildMask(size(img));
                end
            end

            if isempty(obj.mask) || ~isequal(size(img), size(obj.mask))
                return;
            end

            val = mean(double(img(obj.mask)),'omitnan');
            t = toc(obj.t0);

            nSamp = obj.nSamples + 1;
            if nSamp > numel(obj.times) || nSamp > numel(obj.values)
                newCap = max(nSamp, numel(obj.times) + obj.growthChunkSamples);
                obj.times(end+1:newCap,1) = nan;
                obj.values(end+1:newCap,1) = nan;
            end
            obj.times(nSamp,1) = t;
            obj.values(nSamp,1) = val;
            obj.nSamples = nSamp;
            if ~updatePlot
                return;
            end
            obj.refreshPlot(true);
        end

        function appendSample(obj, frameNum, t, val)
            if nargin < 2 || isempty(frameNum) || ~isfinite(frameNum)
                frameNum = NaN;
            end
            if nargin < 3 || isempty(t) || ~isfinite(t)
                if isempty(obj.t0)
                    return;
                end
                t = toc(obj.t0);
            end
            if nargin < 4 || isempty(val) || ~isfinite(val)
                return;
            end
            if ~isnan(frameNum) && frameNum == obj.lastFrameNumber
                return;
            end
            if ~isnan(frameNum)
                obj.lastFrameNumber = frameNum;
            end

            nSamp = obj.nSamples + 1;
            if nSamp > numel(obj.times) || nSamp > numel(obj.values)
                newCap = max(nSamp, numel(obj.times) + obj.growthChunkSamples);
                obj.times(end+1:newCap,1) = nan;
                obj.values(end+1:newCap,1) = nan;
            end
            obj.times(nSamp,1) = t;
            obj.values(nSamp,1) = val;
            obj.nSamples = nSamp;
        end

        function refreshPlot(obj, doDraw)
            if nargin < 2 || isempty(doDraw)
                doDraw = true;
            end
            nSamp = obj.nSamples;
            if nSamp < 1 || isempty(obj.hLine) || ~isvalid(obj.hLine) ...
                    || isempty(obj.hAx) || ~isvalid(obj.hAx)
                return;
            end
            firstIdx = max(1, nSamp - obj.maxPlotSamples + 1);
            xPlot = obj.times(firstIdx:nSamp);
            yPlot = obj.values(firstIdx:nSamp);
            set(obj.hLine,'XData',xPlot,'YData',yPlot);
            if numel(xPlot) >= 2 && xPlot(end) > xPlot(1)
                obj.hAx.XLim = [xPlot(1) xPlot(end)];
            end
            if ~isempty(obj.stimLines)
                yl = obj.hAx.YLim;
                for i = 1:numel(obj.stimLines)
                    if isvalid(obj.stimLines(i))
                        set(obj.stimLines(i), 'YData', yl);
                    end
                end
            end
            if doDraw
                drawnow limitrate nocallbacks;
            end
        end
    end

    methods (Static, Access = private)
        function safeCloseFig(hFig, hObj)
            try
                if ~isempty(hObj) && isvalid(hObj)
                    hObj.stop();
                end
            catch
            end

            if isempty(hFig) || ~isvalid(hFig)
                return;
            end
            try
                set(hFig,'CloseRequestFcn','');
            catch
            end
            try
                delete(hFig);
            catch
            end

            try
                if ~isempty(hObj) && isvalid(hObj)
                    hObj.hFig = [];
                end
            catch
            end
        end
    end

    methods (Access = private)
        function resetData(obj)
            if isempty(obj.times) || isempty(obj.values)
                obj.times = nan(obj.preallocSamples,1);
                obj.values = nan(obj.preallocSamples,1);
            elseif numel(obj.times) < obj.preallocSamples || numel(obj.values) < obj.preallocSamples
                obj.times(end+1:obj.preallocSamples,1) = nan;
                obj.values(end+1:obj.preallocSamples,1) = nan;
            end
            obj.nSamples = 0;
            obj.lastFrameNumber = -inf;
            obj.t0 = [];
            obj.mask = [];
            obj.stimTimes = [];
            try
                if ~isempty(obj.hLine) && isvalid(obj.hLine)
                    set(obj.hLine,'XData',nan,'YData',nan);
                end
            catch
            end
            if ~isempty(obj.stimLines)
                for i = 1:numel(obj.stimLines)
                    try
                        if isvalid(obj.stimLines(i))
                            delete(obj.stimLines(i));
                        end
                    catch
                    end
                end
            end
            obj.stimLines = [];
        end

        function onTick(obj)
            try
                if isempty(obj.hSI) || ~most.idioms.isValidObj(obj.hSI) ...
                        || isempty(obj.hSI.hDisplay) || ~most.idioms.isValidObj(obj.hSI.hDisplay)
                    return;
                end

                hDisp = obj.hSI.hDisplay;
                if isempty(hDisp.lastStripeData) || isempty(hDisp.lastStripeData.roiData)
                    return;
                end

                frameNum = hDisp.lastFrameNumber;
                if isempty(frameNum) || ~isfinite(frameNum)
                    return;
                end

                img = obj.getChannel1Frame(hDisp);
                if isempty(img)
                    return;
                end
                obj.processFrame(frameNum, img, false);
                obj.refreshPlot(true);
            catch
            end
        end

        function img = getChannel1Frame(~, hDisp)
            img = [];
            stripe = hDisp.lastStripeData;
            if isempty(stripe) || isempty(stripe.roiData)
                return;
            end

            rd = stripe.roiData{1};
            if isempty(rd.channels)
                return;
            end

            chIdx = find(rd.channels == 1, 1, 'first');
            if isempty(chIdx)
                return;
            end

            img = rd.imageData{chIdx};
            if iscell(img)
                img = img{1};
            end
            if rd.transposed
                img = img';
            end
        end

        function mask = buildMask(obj, imgSize)
            mask = [];
            try
                rg = obj.hSI.hRoiManager.currentRoiGroup;
                if isempty(rg) || isempty(rg.rois)
                    return;
                end
                sf = rg.rois(1).scanfields(1);
                pixRes = sf.pixelResolutionXY;
                if nargin >= 2 && numel(imgSize) >= 2
                    if ~isequal([imgSize(2) imgSize(1)], pixRes)
                        % If image size does not match scanfield, skip mask build.
                        return;
                    end
                end

                [xx,yy] = meshgrid(1:pixRes(1),1:pixRes(2));
                ptsRef = scanimage.mroi.util.xformPoints([xx(:) yy(:)], sf.pixelToRefTransform());

                res = obj.hSI.objectiveResolution;
                if isscalar(res)
                    res = [res res];
                end
                pts_um = ptsRef .* res;
                d2 = sum((pts_um - obj.center_um).^2,2);
                mask = reshape(d2 <= (obj.diameter_um/2)^2, pixRes(2), pixRes(1));
            catch
                mask = [];
            end
        end
    end
end

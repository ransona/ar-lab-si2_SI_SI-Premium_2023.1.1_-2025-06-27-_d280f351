function acquireSlmVolume(hSI)
% acquireSlmVolume Acquire interleaved single-frame SLM grabs across depths.
%
% Usage:
%   scanimage.util.acquireSlmVolume()
%   scanimage.util.acquireSlmVolume(hSI)

    if nargin < 1 || isempty(hSI)
        hSI = evalin('base','hSI');
    end

    validateattributes(hSI,{'scanimage.SI'},{'scalar'});
    assert(most.idioms.isValidObj(hSI.hSlmScan),'No active SLM scanner is available.');
    assert(strcmpi(hSI.acqState,'idle'),'ScanImage must be idle before starting SLM volume acquisition.');

    defaultOut = fullfile('F:\SLM', datestr(now,'yyyymmdd_HHMMSS'));
    opts = struct;
    opts.WindowStyle = 'normal';
    queries = { ...
        'Zoom factor', ...
        'Pixels per line', ...
        'Frames per depth', ...
        'SLM Z positions (MATLAB expression in um)', ...
        'Output folder'};
    defaults = { ...
        '1.2', ...
        '64', ...
        '50', ...
        '[-150:30:150]', ...
        defaultOut};
    fieldWidth = [1 80];

    answer = most.gui.inputdlgCentered(queries,'Acquire SLM Volume', ...
        repmat(fieldWidth,numel(queries),1),defaults,opts);
    if isempty(answer)
        return;
    end

    zoomFactor = str2double(answer{1});
    pixelsPerLine = str2double(answer{2});
    framesPerDepth = str2double(answer{3});
    slmZPositions = eval(answer{4}); %#ok<EVLDIR>
    outputFolder = answer{5};

    validateattributes(zoomFactor,{'numeric'},{'scalar','real','finite','positive'});
    validateattributes(pixelsPerLine,{'numeric'},{'scalar','real','finite','integer','positive'});
    validateattributes(framesPerDepth,{'numeric'},{'scalar','real','finite','integer','positive'});
    validateattributes(slmZPositions,{'numeric'},{'vector','real','finite','nonempty'});
    validateattributes(outputFolder,{'char','string'},{'nonempty'});
    outputFolder = char(outputFolder);

    if ~exist(outputFolder,'dir')
        mkdir(outputFolder);
    end

    state.imagingSystem = hSI.imagingSystem;
    state.zoomFactor = hSI.hRoiManager.scanZoomFactor;
    state.pixelsPerLine = hSI.hRoiManager.pixelsPerLine;
    state.linesPerFrame = hSI.hRoiManager.linesPerFrame;
    state.displayRollingAverageFactor = hSI.hDisplay.displayRollingAverageFactor;
    state.framesPerAcq = hSI.hScan2D.framesPerAcq;
    state.stackEnable = hSI.hStackManager.enable;
    state.framesPerSlice = hSI.hStackManager.framesPerSlice;
    state.loggingEnable = hSI.hChannels.loggingEnable;
    state.logFilePath = hSI.hScan2D.logFilePath;
    state.logFileStem = hSI.hScan2D.logFileStem;
    state.logFramesPerFile = hSI.hScan2D.logFramesPerFile;
    state.parkPosition = hSI.hSlmScan.parkPosition_um;
    abortRequested = false;
    abortFig = [];
    abortStatusText = [];
    liveFig = [];
    liveTileLayout = [];
    liveAxes = gobjects(0);
    liveImages = gobjects(0);
    liveTitles = gobjects(0);
    liveAvgSums = cell(0,1);
    liveAvgCounts = zeros(0,1);
    acquisitionStartTic = [];
    wasAborted = false;

    cleanupState = onCleanup(@()restoreState()); %#ok<NASGU>

    abortFig = createAbortControl();

    hSI.imagingSystem = hSI.hSlmScan.name;
    hSI.hRoiManager.scanZoomFactor = zoomFactor;
    hSI.hRoiManager.pixelsPerLine = pixelsPerLine;
    hSI.hRoiManager.linesPerFrame = pixelsPerLine;
    hSI.hDisplay.displayRollingAverageFactor = 10;
    hSI.hChannels.loggingEnable = true;
    setFramesPerAcqSafe(1);
    hSI.hScan2D.logFramesPerFile = inf;
    hSI.hScan2D.logFilePath = outputFolder;
    hSI.hScan2D.logFileStem = 'SLM';

    liveFig = createLiveAverageFigure(slmZPositions);
    acquisitionStartTic = tic;

    xy = hSI.hSlmScan.parkPosition_um(1:2);
    totalGrabs = framesPerDepth * numel(slmZPositions);
    grabCounter = 0;
    for repIdx = 1:framesPerDepth
        grabOrder = randperm(numel(slmZPositions));
        for orderIdx = 1:numel(grabOrder)
            depthIdx = grabOrder(orderIdx);
            if abortRequested
                wasAborted = true;
                break;
            end

            grabCounter = grabCounter + 1;
            updateAbortStatus(grabCounter, totalGrabs, slmZPositions(depthIdx), repIdx, framesPerDepth);
            hSI.hSlmScan.parkPosition_um = [xy slmZPositions(depthIdx)];
            pause(0.1);
            hSI.startGrab();
            waitForIdle();
            autoScaleEnabledChannels();
            updateLiveAverage(depthIdx);
        end

        if abortRequested
            wasAborted = true;
            break;
        end
    end

    closeAbortControlSafely();
    closeLiveFigureSafely();

    if wasAborted
        msgbox(sprintf('SLM volume acquisition aborted.\nOutput folder:\n%s',outputFolder), ...
            'Acquire SLM Volume','warn');
    else
        msgbox(sprintf('Completed SLM volume acquisition.\nOutput folder:\n%s',outputFolder), ...
            'Acquire SLM Volume','help');
    end

    function waitForIdle()
        while ~strcmpi(hSI.acqState,'idle')
            drawnow();
            if abortRequested
                wasAborted = true;
                hSI.abort();
            end
            pause(0.1);
        end
    end

    function fig = createAbortControl()
        fig = figure( ...
            'Name','SLM Volume Acquisition', ...
            'NumberTitle','off', ...
            'MenuBar','none', ...
            'ToolBar','none', ...
            'Resize','off', ...
            'WindowStyle','normal', ...
            'HandleVisibility','callback', ...
            'CloseRequestFcn',@abortCallback, ...
            'Position',[100 100 290 135]);

        abortStatusText = uicontrol(fig, ...
            'Style','text', ...
            'String','Preparing acquisition...', ...
            'HorizontalAlignment','center', ...
            'FontWeight','bold', ...
            'Position',[15 85 260 28]);

        uicontrol(fig, ...
            'Style','text', ...
            'String','Acquisition is running. Click to abort cleanly.', ...
            'HorizontalAlignment','center', ...
            'Position',[15 50 260 28]);

        uicontrol(fig, ...
            'Style','pushbutton', ...
            'String','Abort', ...
            'FontWeight','bold', ...
            'ForegroundColor',[0.6 0 0], ...
            'Position',[95 15 100 28], ...
            'Callback',@abortCallback);
    end

    function abortCallback(~,~)
        abortRequested = true;
        wasAborted = true;
        if strcmpi(hSI.acqState,'idle')
            closeAbortControlSafely();
        end
    end

    function deleteAbortControl()
        if ~isempty(abortFig) && ishghandle(abortFig)
            delete(abortFig);
        end
        abortFig = [];
        abortStatusText = [];
    end

    function closeAbortControlSafely()
        try
            deleteAbortControl();
        catch
        end
    end

    function fig = createLiveAverageFigure(zPositions)
        numDepths = numel(zPositions);
        liveAvgSums = cell(numDepths,1);
        liveAvgCounts = zeros(numDepths,1);

        nCols = ceil(sqrt(numDepths));
        nRows = ceil(numDepths / nCols);

        fig = figure( ...
            'Name','SLM Volume Depth Averages', ...
            'NumberTitle','off', ...
            'MenuBar','none', ...
            'ToolBar','none', ...
            'WindowStyle','normal', ...
            'Color','w', ...
            'Position',[420 80 max(520, 240*nCols) max(360, 220*nRows)]);
        liveTileLayout = tiledlayout(fig,nRows,nCols,'Padding','compact','TileSpacing','compact');
        liveAxes = gobjects(numDepths,1);
        liveImages = gobjects(numDepths,1);
        liveTitles = gobjects(numDepths,1);

        for tileIdx = 1:numDepths
            liveAxes(tileIdx) = nexttile(liveTileLayout);
            liveImages(tileIdx) = imagesc(liveAxes(tileIdx), nan(2));
            axis(liveAxes(tileIdx),'image');
            axis(liveAxes(tileIdx),'off');
            colormap(liveAxes(tileIdx),'gray');
            liveTitles(tileIdx) = title(liveAxes(tileIdx), ...
                sprintf('z = %.3g um\nn = 0', zPositions(tileIdx)));
        end
        drawnow();
    end

    function closeLiveFigureSafely()
        try
            if ~isempty(liveFig) && ishghandle(liveFig)
                delete(liveFig);
            end
        catch
        end
        try
            liveFig = [];
        catch
        end
        try
            liveTileLayout = [];
        catch
        end
        try
            liveAxes = gobjects(0);
        catch
        end
        try
            liveImages = gobjects(0);
        catch
        end
        try
            liveTitles = gobjects(0);
        catch
        end
    end

    function setFramesPerAcqSafe(nFrames)
        nFrames = max(1, round(double(nFrames)));
        assert(~isempty(hSI.hStackManager) && most.idioms.isValidObj(hSI.hStackManager), ...
            'No valid stack manager is available to configure frames per grab.');
        hSI.hStackManager.enable = false;
        hSI.hStackManager.framesPerSlice = nFrames;
    end

    function updateAbortStatus(idx, totalCount, zPos, repIdx, numReps)
        if ~isempty(abortStatusText) && ishghandle(abortStatusText)
            remainingStr = formatRemainingTime(idx,totalCount);
            abortStatusText.String = sprintf('%d/%d [depth %.3g um, rep %d/%d, ETA %s]', ...
                idx, totalCount, zPos, repIdx, numReps, remainingStr);
            drawnow();
        end
    end

    function remainingStr = formatRemainingTime(completedCount,totalCount)
        remainingStr = '--';
        try
            if isempty(acquisitionStartTic) || completedCount <= 1 || totalCount <= completedCount
                return;
            end
            elapsed_s = toc(acquisitionStartTic);
            avgPerGrab_s = elapsed_s / max(completedCount - 1, 1);
            remaining_s = max(0, avgPerGrab_s * (totalCount - completedCount));
            remainingStr = formatDuration(remaining_s);
        catch
        end
    end

    function str = formatDuration(duration_s)
        duration_s = max(0, round(double(duration_s)));
        hours = floor(duration_s / 3600);
        minutes = floor(mod(duration_s, 3600) / 60);
        seconds = mod(duration_s, 60);

        if hours > 0
            str = sprintf('%dh %02dm %02ds', hours, minutes, seconds);
        elseif minutes > 0
            str = sprintf('%dm %02ds', minutes, seconds);
        else
            str = sprintf('%ds', seconds);
        end
    end

    function autoScaleEnabledChannels()
        try
            activeChans = hSI.hChannels.channelsActive;
        catch
            activeChans = [];
        end

        for ch = 1:2
            if ismember(ch, activeChans)
                try
                    hSI.hDisplay.channelAutoScale(ch);
                catch
                end
            end
        end
    end

    function updateLiveAverage(depthIdx)
        frameImage = getLatestDisplayFrame();
        if isempty(frameImage)
            return;
        end

        frameImage = double(frameImage);
        if isempty(liveAvgSums{depthIdx})
            liveAvgSums{depthIdx} = zeros(size(frameImage));
        elseif ~isequal(size(liveAvgSums{depthIdx}), size(frameImage))
            return;
        end

        liveAvgSums{depthIdx} = liveAvgSums{depthIdx} + frameImage;
        liveAvgCounts(depthIdx) = liveAvgCounts(depthIdx) + 1;
        avgImage = liveAvgSums{depthIdx} ./ liveAvgCounts(depthIdx);

        try
            if depthIdx <= numel(liveImages) && ishghandle(liveImages(depthIdx))
                liveImages(depthIdx).CData = avgImage;
                clim = computePercentileClim(avgImage,[5 95]);
                if all(isfinite(clim)) && numel(clim) == 2
                    if diff(clim) <= 0
                        clim(2) = clim(1) + 1;
                    end
                    liveAxes(depthIdx).CLim = clim;
                end
                liveTitles(depthIdx).String = sprintf('z = %.3g um\nn = %d', ...
                    slmZPositions(depthIdx), liveAvgCounts(depthIdx));
                drawnow limitrate;
            end
        catch
        end
    end

    function frameImage = getLatestDisplayFrame()
        frameImage = [];
        try
            displayFrames = hSI.hDisplay.lastFrame;
            if isempty(displayFrames)
                return;
            end
            if iscell(displayFrames)
                frameImage = displayFrames{1};
            elseif isnumeric(displayFrames)
                if ndims(displayFrames) > 2
                    frameImage = displayFrames(:,:,1);
                else
                    frameImage = displayFrames;
                end
            end
        catch
        end
    end

    function clim = computePercentileClim(im, pct)
        clim = [nan nan];
        try
            vals = double(im(:));
            vals = vals(isfinite(vals));
            if isempty(vals)
                return;
            end
            clim = prctile(vals, pct);
        catch
        end
    end

    function restoreState()
        closeAbortControlSafely();
        closeLiveFigureSafely();

        try
            if ~strcmpi(hSI.acqState,'idle')
                hSI.abort();
                waitForIdle();
            end
        catch
        end

        try
            hSI.imagingSystem = state.imagingSystem;
        catch
        end

        try
            hSI.hRoiManager.scanZoomFactor = state.zoomFactor;
        catch
        end

        try
            hSI.hRoiManager.pixelsPerLine = state.pixelsPerLine;
            hSI.hRoiManager.linesPerFrame = state.linesPerFrame;
        catch
        end

        try
            hSI.hDisplay.displayRollingAverageFactor = state.displayRollingAverageFactor;
        catch
        end

        try
            setFramesPerAcqSafe(state.framesPerAcq);
        catch
        end

        try
            hSI.hStackManager.enable = state.stackEnable;
            hSI.hStackManager.framesPerSlice = state.framesPerSlice;
        catch
        end

        try
            hSI.hChannels.loggingEnable = state.loggingEnable;
        catch
        end

        try
            hSI.hScan2D.logFilePath = state.logFilePath;
            hSI.hScan2D.logFileStem = state.logFileStem;
            hSI.hScan2D.logFramesPerFile = state.logFramesPerFile;
        catch
        end

        try
            if most.idioms.isValidObj(hSI.hSlmScan)
                hSI.hSlmScan.parkPosition_um = state.parkPosition;
            end
        catch
        end
    end
end

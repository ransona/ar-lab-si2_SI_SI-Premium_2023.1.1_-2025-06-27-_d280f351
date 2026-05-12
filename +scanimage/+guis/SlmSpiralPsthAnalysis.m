function [results, hFig] = SlmSpiralPsthAnalysis(matPath, varargin)
% SlmSpiralPsthAnalysis  Plot PSTH for each power/duration condition.
%
% Usage:
%   scanimage.guis.SlmSpiralPsthAnalysis('path/to/file.mat')
%
% Optional name-value pairs:
%   'Window'       [tStart tEnd] in seconds (default [-0.5 1])
%   'Dt'           sample interval in seconds (ignored if UseFrameIndex=true)
%   'Show'         true/false (default true)
%   'CellIndex'    index or [] for all cells (default [])
%   'BaselineWindow' [tStart tEnd] in seconds (default [-0.5 0])
%   'BaselineSigma'  multiplier for std threshold (default 1.96)
%   'ConsecPoints'   number of consecutive points above threshold (default 2)
%   'UseFrameIndex'  true/false, use frame indices + nearest neighbor (default true)

    p = inputParser;
    p.addRequired('matPath', @(s)ischar(s) || isstring(s));
    p.addParameter('Window', [-0.5 1], @(v)isnumeric(v) && numel(v)==2 && all(isfinite(v)));
    p.addParameter('Dt', [], @(v)isnumeric(v) && (isempty(v) || (isscalar(v) && isfinite(v) && v>0)));
    p.addParameter('Show', true, @(v)islogical(v) && isscalar(v));
    p.addParameter('CellIndex', [], @(v)isnumeric(v) && (isempty(v) || all(isfinite(v))));
    p.addParameter('BaselineWindow', [], @(v)isnumeric(v) && (isempty(v) || (numel(v)==2 && all(isfinite(v)))));
    p.addParameter('BaselineSigma', 1.96, @(v)isnumeric(v) && isscalar(v) && isfinite(v) && v>=0);
    p.addParameter('ConsecPoints', 2, @(v)isnumeric(v) && isscalar(v) && isfinite(v) && v>=1);
    p.addParameter('UseFrameIndex', true, @(v)islogical(v) && isscalar(v));
    p.parse(matPath, varargin{:});

    matPath = char(p.Results.matPath);
    win = p.Results.Window(:).';
    dt = p.Results.Dt;
    doShow = p.Results.Show;
    cellIndex = p.Results.CellIndex;
    baseWin = p.Results.BaselineWindow;
    baseSigma = p.Results.BaselineSigma;
    consecPoints = round(p.Results.ConsecPoints);
    useFrameIndex = p.Results.UseFrameIndex;
    if isempty(baseWin)
        baseWin = [win(1) 0];
    else
        baseWin = baseWin(:).';
    end

    data = load(matPath);
    if ~isfield(data, 'stimData')
        error('No stimData found in %s.', matPath);
    end
    stimData = data.stimData;

    traces = {};
    if isfield(stimData, 'traces') && ~isempty(stimData.traces)
        traces = stimData.traces;
    elseif isfield(stimData, 'trace') && ~isempty(stimData.trace)
        traces = {stimData.trace};
    end
    if isempty(traces)
        error('Trace data missing in stimData.');
    end

    if isfield(stimData, 'stim_per_trigger') && ~isempty(stimData.stim_per_trigger)
        perTrigAll = stimData.stim_per_trigger;
    else
        perTrigAll = repmat(struct('power_pct', NaN, 'duration_ms', NaN, 'center_index', NaN), 0, 1);
    end

    [stimTimesAll, stimTimesSource] = resolveStimTriggerTimesForPsth(stimData);
    [stimSpanAll, stimSpanSource] = resolveStimSpanFlagsForPsth(stimData);

    if isempty(cellIndex)
        cellIndex = 1:numel(traces);
    end

    results = struct();
    results.file = matPath;
    results.window_s = win;
    results.dt_s = dt;
    results.use_frame_index = useFrameIndex;
    results.frame_dt_s = [];
    results.window_frames = [];
    results.stim_trigger_times_source = stimTimesSource;
    results.n_stim_triggers_total = numel(stimTimesAll);
    results.stim_span_source = stimSpanSource;
    results.cells = struct([]);

    hFig = [];
    figHandles = gobjects(0,1);
    tvec = [];
    nT = 0;
    frameDt = [];

    for cIdx = 1:numel(cellIndex)
        c = cellIndex(cIdx);
        if c < 1 || c > numel(traces)
            continue;
        end
        trace = traces{c};
        if ~isfield(trace, 'times_s') || ~isfield(trace, 'values')
            continue;
        end

        times = trace.times_s(:);
        values = trace.values(:);
        if numel(times) < 2
            continue;
        end

        if isempty(frameDt)
            d = diff(times);
            d = d(isfinite(d) & d > 0);
            if isempty(d)
                frameDt = 0.05;
            else
                frameDt = median(d);
            end
            results.frame_dt_s = frameDt;
            if useFrameIndex
                results.dt_s = 1;
                results.window_frames = round(win ./ frameDt);
            end
        end

        if ~useFrameIndex && isempty(dt)
            dt = frameDt;
            results.dt_s = dt;
        end

        if isempty(tvec)
            if useFrameIndex
                winFrames = round(win ./ frameDt);
                tvecFrames = winFrames(1):1:winFrames(2);
                tvec = tvecFrames; % used for indexing
            else
                tvec = win(1):dt:win(2);
            end
            nT = numel(tvec);
        end

        % Determine center index for this trace
        if isfield(trace, 'center_index') && ~isempty(trace.center_index)
            thisCenterIdx = trace.center_index;
        elseif isfield(stimData, 'centers_um') && isfield(trace, 'center_um')
            thisCenterIdx = find(all(abs(stimData.centers_um - trace.center_um(:).') < 1e-6,2), 1, 'first');
            if isempty(thisCenterIdx)
                thisCenterIdx = c;
            end
        else
            thisCenterIdx = c;
        end

        % Use only stim times where this center was stimulated
        nTrigAll = min(numel(stimTimesAll), numel(perTrigAll));
        stimTimes = stimTimesAll(1:nTrigAll);
        perTrig = perTrigAll(1:nTrigAll);
        stimSpan = true(nTrigAll,1);
        nSpan = min(numel(stimSpanAll), nTrigAll);
        if nSpan > 0
            stimSpan(1:nSpan) = logical(stimSpanAll(1:nSpan));
        end
        useMask = false(nTrigAll,1);
        for k = 1:nTrigAll
            if isfield(perTrig(k), 'center_index') && ~isempty(perTrig(k).center_index)
                useMask(k) = perTrig(k).center_index == thisCenterIdx;
            end
        end
        stimTimes = stimTimes(useMask);
        perTrig = perTrig(useMask);
        stimSpan = stimSpan(useMask);

        nTrig = numel(stimTimes);
        condKeys = cell(nTrig,1);
        pvals = nan(nTrig,1);
        dvals = nan(nTrig,1);
        for i = 1:nTrig
            pvals(i) = perTrig(i).power_pct;
            dvals(i) = perTrig(i).duration_ms;
            condKeys{i} = sprintf('P%.4g_D%.4g', pvals(i), dvals(i));
        end

        [uKeys, ~, keyIdx] = unique(condKeys, 'stable');
        nCond = numel(uKeys);

        cellRes = struct();
        cellRes.cell_index = thisCenterIdx;
        if isfield(trace,'center_um')
            cellRes.center_um = trace.center_um;
        else
            cellRes.center_um = [NaN NaN];
        end
        cellRes.power_values_pct = [];
        cellRes.duration_values_ms = [];
        cellRes.conditions = repmat(struct('key','', 'power_pct',[], 'duration_ms',[], ...
            'n_trials',0, 't_s',[], 't_frames',[], 'frame_dt_s',[], ...
            'mean',[], 'std',[], 'trials',[], ...
            'baseline_window_s',[], 'baseline_window_frames',[], ...
            'baseline_mean',[], 'baseline_std',[], ...
            'baseline_threshold',[], 'above_baseline_idx',[], 'above_baseline_mask',[]), nCond, 1);

        for cnd = 1:nCond
            idxC = find(keyIdx == cnd);
            trials = nan(numel(idxC), nT);
            if useFrameIndex
                frameIdx = (0:numel(times)-1).';
                stimFrames = floor(interp1(times, frameIdx, stimTimes, 'linear', 'extrap'));
            end
            for k = 1:numel(idxC)
                if useFrameIndex
                    t0 = stimFrames(idxC(k));
                    segF = t0 + tvec;
                    trialVals = interp1(frameIdx, values, segF, 'nearest', NaN);
                    spanMultiFrame = stimSpan(idxC(k));
                    trialVals = replaceStimArtifactFramesQuadratic(trialVals, values, t0, tvec, spanMultiFrame);
                else
                    t0 = stimTimes(idxC(k));
                    segT = t0 + tvec;
                    trialVals = interp1(times, values, segT, 'linear', NaN);
                end
                trials(k,:) = zscoreSegment(trialVals);
            end
            mu = mean(trials, 1, 'omitnan');
            sd = std(trials, 0, 1, 'omitnan');

            if useFrameIndex
                baseWinFrames = round(baseWin ./ frameDt);
                baseMask = tvec >= baseWinFrames(1) & tvec <= baseWinFrames(2);
            else
                baseMask = tvec >= baseWin(1) & tvec <= baseWin(2);
            end
            baseMean = mean(mu(baseMask), 'omitnan');
            baseStd = std(mu(baseMask), 0, 'omitnan');
            thresh = baseMean + baseSigma * baseStd;
            spanThresh = max(0, consecPoints - 1);
            [idxAbove, maskAbove] = consecAboveThresh(mu, thresh, spanThresh);

            cellRes.conditions(cnd).key = uKeys{cnd};
            cellRes.conditions(cnd).power_pct = pvals(idxC(1));
            cellRes.conditions(cnd).duration_ms = dvals(idxC(1));
            cellRes.conditions(cnd).n_trials = size(trials,1);
            if useFrameIndex
                cellRes.conditions(cnd).t_frames = tvec;
                cellRes.conditions(cnd).t_s = tvec .* frameDt;
                cellRes.conditions(cnd).baseline_window_frames = baseWinFrames;
                cellRes.conditions(cnd).frame_dt_s = frameDt;
            else
                cellRes.conditions(cnd).t_s = tvec;
            end
            cellRes.conditions(cnd).mean = mu;
            cellRes.conditions(cnd).std = sd;
            cellRes.conditions(cnd).trials = trials;
            cellRes.conditions(cnd).baseline_window_s = baseWin;
            cellRes.conditions(cnd).baseline_mean = baseMean;
            cellRes.conditions(cnd).baseline_std = baseStd;
            cellRes.conditions(cnd).baseline_threshold = thresh;
            cellRes.conditions(cnd).above_baseline_idx = idxAbove;
            cellRes.conditions(cnd).above_baseline_mask = maskAbove;
        end

        results.cells = [results.cells; cellRes]; %#ok<AGROW>

        if doShow && nCond > 0
            powVals = unique([cellRes.conditions.power_pct]);
            durVals = unique([cellRes.conditions.duration_ms]);
            powVals = powVals(isfinite(powVals));
            durVals = durVals(isfinite(durVals));
            powVals = sort(powVals);
            durVals = sort(durVals);
            cellRes.power_values_pct = powVals;
            cellRes.duration_values_ms = durVals;

            nRows = max(1, numel(powVals));
            nCols = max(1, numel(durVals));
            figName = sprintf('SLM PSTH Cell %d (%.1f, %.1f)', cellRes.cell_index, cellRes.center_um(1), cellRes.center_um(2));
            hFigLocal = figure('Name',figName,'Color','w');
            figHandles(end+1,1) = hFigLocal; %#ok<AGROW>
            for r = 1:nRows
                for col = 1:nCols
                    pow = powVals(r);
                    dur = durVals(col);
                    condIdx = find(arrayfun(@(x)approxEq(x.power_pct, pow) && approxEq(x.duration_ms, dur), cellRes.conditions), 1, 'first');
                    subplot(nRows, nCols, (r-1)*nCols + col);
                    hold on;
                    if isempty(condIdx)
                        text(0.5, 0.5, 'n/a', 'HorizontalAlignment','center', 'Units','normalized');
                    else
                        if useFrameIndex
                            t = cellRes.conditions(condIdx).t_frames;
                        else
                            t = cellRes.conditions(condIdx).t_s;
                        end
                        mu = cellRes.conditions(condIdx).mean;
                        sd = cellRes.conditions(condIdx).std;
                        if any(isfinite(sd))
                            x = [t fliplr(t)];
                            y = [mu - sd, fliplr(mu + sd)];
                            fill(x, y, [0.2 0.6 1], 'FaceAlpha',0.2, 'EdgeColor','none');
                        end
                        plot(t, mu, 'b-', 'LineWidth',1.5);
                        if ~isempty(cellRes.conditions(condIdx).above_baseline_mask)
                            ab = cellRes.conditions(condIdx).above_baseline_mask(:).' > 0;
                            plot(t(ab), mu(ab), 'r.', 'MarkerSize',6);
                        end
                        yl = ylim;
                        plot([0 0], yl, 'k--');
                        ylim(yl);
                    end
                    if r == 1
                        title(sprintf('D %.3g ms', dur));
                    end
                    if col == 1
                        ylabel(sprintf('P %.3g%%\nCh1 Mean', pow));
                    elseif r == nRows
                        ylabel('Ch1 Mean');
                    end
                    if r == nRows
                        if useFrameIndex
                            xlabel('Time (frames)');
                        else
                            xlabel('Time (s)');
                        end
                    end
                    grid on;
                    hold off;
                end
            end
        end
    end

    if doShow
        hFig = figHandles;
    end
end

function [index, logicArray] = consecAboveThresh(inputVector, amplThreshold, spanThreshold)
% Finds n consecutive values above a certain threshold

    if size(inputVector,2) == 1
        inputVector = inputVector';
    end

    aboveThreshold = (inputVector > amplThreshold);
    aboveThreshold = [false, aboveThreshold, false];
    edges = diff(aboveThreshold);
    rising = find(edges==1);
    falling = find(edges==-1);
    spanWidth = falling - rising;
    wideEnough = spanWidth > spanThreshold;
    startPos = rising(wideEnough);
    endPos = falling(wideEnough)-1;
    index = cell2mat(arrayfun(@(x,y) x:1:y, startPos, endPos, 'uni', false));
    logicArray = zeros(length(inputVector),1);
    logicArray(index)=1;
end

function tf = approxEq(a,b)
    tf = abs(a-b) < 1e-9;
end

function [stimTimes, source] = resolveStimTriggerTimesForPsth(stimData)
% Prefer hardware trigger times when available.

    stimTimes = [];
    source = 'none';

    if isfield(stimData, 'stim_trigger_times_hw_s') && ~isempty(stimData.stim_trigger_times_hw_s)
        stimTimes = stimData.stim_trigger_times_hw_s(:);
        source = 'stim_trigger_times_hw_s';
    elseif isfield(stimData, 'stim_timing') && isstruct(stimData.stim_timing) ...
            && isfield(stimData.stim_timing, 'hardware_times_s') && ~isempty(stimData.stim_timing.hardware_times_s)
        stimTimes = stimData.stim_timing.hardware_times_s(:);
        source = 'stim_timing.hardware_times_s';
    elseif isfield(stimData, 'stim_trigger_times_s') && ~isempty(stimData.stim_trigger_times_s)
        stimTimes = stimData.stim_trigger_times_s(:);
        source = 'stim_trigger_times_s';
    end

    if isempty(stimTimes)
        return;
    end

    stimTimes = double(stimTimes(:));
    stimTimes = stimTimes(isfinite(stimTimes));
end

function [spanFlags, source] = resolveStimSpanFlagsForPsth(stimData)
% Span flag indicates whether each trigger spanned multiple imaging frames.
% true  -> interpolate frame 0 and +1
% false -> interpolate frame 0 only

    spanFlags = [];
    source = 'none';

    if isfield(stimData, 'stim_trigger_times_hw_spans_multiple_frames') && ...
            ~isempty(stimData.stim_trigger_times_hw_spans_multiple_frames)
        spanFlags = logical(stimData.stim_trigger_times_hw_spans_multiple_frames(:));
        source = 'stim_trigger_times_hw_spans_multiple_frames';
        return;
    end

    if isfield(stimData, 'stim_timing') && isstruct(stimData.stim_timing) && ...
            isfield(stimData.stim_timing, 'hardware_spans_multiple_frames') && ...
            ~isempty(stimData.stim_timing.hardware_spans_multiple_frames)
        spanFlags = logical(stimData.stim_timing.hardware_spans_multiple_frames(:));
        source = 'stim_timing.hardware_spans_multiple_frames';
        return;
    end

    if isfield(stimData, 'stim_trigger_times_hw_frame_index') && ...
            isfield(stimData, 'stim_trigger_times_hw_end_frame_index') && ...
            ~isempty(stimData.stim_trigger_times_hw_frame_index) && ...
            ~isempty(stimData.stim_trigger_times_hw_end_frame_index)
        s = double(stimData.stim_trigger_times_hw_frame_index(:));
        e = double(stimData.stim_trigger_times_hw_end_frame_index(:));
        n = min(numel(s), numel(e));
        if n > 0
            spanFlags = (e(1:n) > s(1:n));
            source = 'stim_trigger_times_hw_frame_index_delta';
        end
    end
end

function trialVals = replaceStimArtifactFramesQuadratic(trialVals, traceValues, stimFrame, tvec, spanMultiFrame)
% Replace stimulation artifact frames using quadratic fit from clean
% neighbors (-3, -2, -1, +2, +3).
% Single-frame stim: replace frame 0 only.
% Multi-frame stim: replace frames 0 and +1.

    if nargin < 5 || isempty(spanMultiFrame)
        spanMultiFrame = true;
    end

    if ~isfinite(stimFrame)
        return;
    end

    fitRel = [-3 -2 -1 2 3];
    if spanMultiFrame
        targetRel = [0 1];
    else
        targetRel = 0;
    end
    nTrace = numel(traceValues);

    srcFrames = stimFrame + fitRel;
    if any(srcFrames < 0) || any(srcFrames > (nTrace - 1))
        return;
    end

    srcVals = traceValues(srcFrames + 1);
    if any(~isfinite(srcVals))
        return;
    end

    p = polyfit(fitRel, srcVals(:).', 2);
    fillVals = polyval(p, targetRel);

    [tf, loc] = ismember(targetRel, tvec);
    if any(tf)
        trialVals(loc(tf)) = fillVals(tf);
    end
end

function zVals = zscoreSegment(vals)
% Z-score one extracted trial segment with NaN-safe statistics.

    zVals = vals;
    mu = mean(vals, 'omitnan');
    sigma = std(vals, 0, 'omitnan');

    if ~isfinite(mu)
        return;
    end
    if ~isfinite(sigma) || sigma <= 0
        zVals = vals - mu;
        return;
    end

    zVals = (vals - mu) ./ sigma;
end

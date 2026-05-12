function wvfmBuf = TurnaroundBlankClock(sampleRate, wvfmParams)
% TurnaroundBlankClock
% Digital blanking waveform:
%   - LOW during resonant acquisition window (line fill fraction)
%   - HIGH during resonant turnaround
%
% Uses linePeriodAcq / linePeriodScan from ScanImage.
% startDelay_Sec is applied as a circular phase shift within one line.
% Positive delays move the gate later in the line; negative delays wrap and
% move it earlier.
%
% This waveform is intentionally one-line-only. Use a line trigger such as
% D3.4 when replaying it. period_Sec is ignored.

    acq = wvfmParams.linePeriodAcq;
    scan = wvfmParams.linePeriodScan;
    linesPerFrame = wvfmParams.linesPerFrame;

    % TTL-like levels for DO task (>0 == HIGH).
    lowVal = 0;
    highVal = 1;

    if ~isfinite(acq) || ~isfinite(scan) || ~isfinite(linesPerFrame) || ...
            acq <= 0 || scan <= 0 || acq > scan || linesPerFrame < 1
        % Failsafe: keep gate LOW if timing is unavailable.
        wvfmBuf = lowVal;
        return;
    end

    nLine = max(1, round(sampleRate * scan));
    nAcq = min(nLine, max(1, round(sampleRate * acq)));
    nTurn = nLine - nAcq;
    nTurnPre = floor(nTurn / 2);
    nTurnPost = nTurn - nTurnPre;

    % Optional narrowing of turnaround stimulation to the center of each
    % flyback half. dutyCycle=100 keeps full turnaround ON.
    centerFrac = 1;
    if isprop(wvfmParams, 'dutyCycle') && isfinite(wvfmParams.dutyCycle)
        centerFrac = max(0, min(1, double(wvfmParams.dutyCycle) / 100));
    end

    preLine = lowVal * ones(1, nTurnPre);
    postLine = lowVal * ones(1, nTurnPost);
    nPreOn = round(nTurnPre * centerFrac);
    nPostOn = round(nTurnPost * centerFrac);
    if nPreOn > 0 && nTurnPre > 0
        iStart = floor((nTurnPre - nPreOn) / 2) + 1;
        preLine(iStart:(iStart + nPreOn - 1)) = highVal;
    end
    if nPostOn > 0 && nTurnPost > 0
        iStart = floor((nTurnPost - nPostOn) / 2) + 1;
        postLine(iStart:(iStart + nPostOn - 1)) = highVal;
    end

    acqLine = lowVal * ones(1, nAcq);
    lineBuf = [preLine acqLine postLine];

    % Optional phase alignment knob (seconds -> samples, wrapped per line).
    delayOddSamp = 0;
    if isprop(wvfmParams, 'startDelay_Sec') && isfinite(wvfmParams.startDelay_Sec) && ...
            ~isempty(lineBuf)
        delayOddSamp = localWrapDelaySamples(sampleRate, wvfmParams.startDelay_Sec, numel(lineBuf));
    end
    lineBufOdd = lineBuf;
    if delayOddSamp > 0
        lineBufOdd = circshift(lineBufOdd, [0 delayOddSamp]);
    end

    % One trigger event emits one line's worth of blanking waveform.
    wvfmBuf = lineBufOdd(:);
end

function delaySamp = localWrapDelaySamples(sampleRate, delaySec, nLineSamples)
    delaySamp = 0;
    if nargin < 3 || isempty(nLineSamples) || (nLineSamples < 1) || ...
            ~isfinite(nLineSamples)
        return;
    end
    if nargin < 2 || isempty(delaySec) || ~isfinite(delaySec)
        return;
    end
    if nargin < 1 || isempty(sampleRate) || ~isfinite(sampleRate) || (sampleRate <= 0)
        return;
    end

    delaySamp = mod(round(sampleRate * delaySec), round(nLineSamples));
end

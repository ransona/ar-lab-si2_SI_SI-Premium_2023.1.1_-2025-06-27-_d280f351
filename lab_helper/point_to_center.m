function point_to_center(src,evt,varargin)
% point_to_center ScanImage user callback helper.
%
% Usage:
%   point_to_center(src,evt,varargin)

    disp(['Got Event: ' evt.EventName]);
    disp(src);
    disp(src.hSI);
    disp(src.hSI.hScan2D);

    hSI = src.hSI;

    try
        currentIsSlm = most.idioms.isValidObj(hSI.hSlmScan) ...
            && most.idioms.isValidObj(hSI.hScan2D) ...
            && isequal(hSI.hScan2D, hSI.hSlmScan);
    catch
        currentIsSlm = false;
    end

    if ~currentIsSlm
        return;
    end

    if isempty(hSI.hSlmScan.hLinScan) || ~most.idioms.isValidObj(hSI.hSlmScan.hLinScan)
        warning('point_to_center:MissingLinScan', ...
            'Current scanner is SLM, but no valid hLinScan is available for galvo centering.');
        return;
    end

    hSI.hSlmScan.hLinScan.xGalvo.pointPosition(0);
    hSI.hSlmScan.hLinScan.yGalvo.pointPosition(0);

    warning('point_to_center:SlmGalvosZeroed', ...
        'Current imaging system is SLM. Set hSI.hSlmScan.hLinScan x/y galvos to 0.');
end

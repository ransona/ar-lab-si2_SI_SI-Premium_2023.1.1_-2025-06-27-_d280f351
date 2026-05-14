function point_to_center(src,evt,varargin)
% point_to_center ScanImage user callback helper.
%
% Usage:
%   point_to_center(src,evt,varargin)

    % disp(['Got Event: ' evt.EventName]);
    % disp(src);
    % disp(src.hSI);
    % disp(src.hSI.hScan2D);

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
        return;
    end

    hSI.hSlmScan.hLinScan.xGalvo.pointPosition(0);
    hSI.hSlmScan.hLinScan.yGalvo.pointPosition(0);

    disp('SLM scanning: pointing galvos to 0');
end

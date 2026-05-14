function plotCurrentSlmPowerCorrection(hSI, xyRange_um, zPositions_um, numSamplesXY)
% plotCurrentSlmPowerCorrection Visualize current SLM power correction maps.
%
% Usage:
%   scanimage.util.plotCurrentSlmPowerCorrection()
%   scanimage.util.plotCurrentSlmPowerCorrection(hSI)
%   scanimage.util.plotCurrentSlmPowerCorrection(hSI, [-500 500], -150:50:150, 201)
%
% Samples the current diffraction-efficiency interpolant stored in
% hSI.hSlmScan.hSlm.hCSDiffractionEfficiency and plots the implied power
% correction (1 ./ efficiency) over XY for a set of Z planes.

    if nargin < 1 || isempty(hSI)
        hSI = evalin('base','hSI');
    end

    if nargin < 4 || isempty(numSamplesXY)
        numSamplesXY = 201;
    end

    validateattributes(hSI,{'scanimage.SI'},{'scalar'});
    validateattributes(numSamplesXY,{'numeric'},{'scalar','integer','positive','finite'});

    assert(most.idioms.isValidObj(hSI.hSlmScan),'No active SLM scanner is available.');
    interpolant = hSI.hSlmScan.hSlm.hCSDiffractionEfficiency.fromParentInterpolant{1};
    assert(~isempty(interpolant),'No diffraction-efficiency interpolant is currently loaded.');

    if nargin < 2 || isempty(xyRange_um) || nargin < 3 || isempty(zPositions_um)
        opts = struct;
        opts.WindowStyle = 'normal';
        queries = { ...
            'XY frame size in microns (symmetric, centered at 0)', ...
            'Z positions (MATLAB expression in um)'};
        defaults = {'1000','-150:50:150'};
        fieldWidth = [1 60];
        answer = most.gui.inputdlgCentered(queries,'Plot SLM Power Correction', ...
            repmat(fieldWidth,numel(queries),1),defaults,opts);
        if isempty(answer)
            return;
        end

        xyFrameSize_um = str2double(answer{1});
        zPositions_um = eval(answer{2}); %#ok<EVLDIR>
        validateattributes(xyFrameSize_um,{'numeric'},{'scalar','real','finite','positive'});
        validateattributes(zPositions_um,{'numeric'},{'vector','real','finite','nonempty'});
        xyRange_um = [-xyFrameSize_um/2, xyFrameSize_um/2];
    end

    validateattributes(xyRange_um,{'numeric'},{'vector','numel',2,'real','finite','increasing'});
    validateattributes(zPositions_um,{'numeric'},{'vector','real','finite','nonempty'});

    x = linspace(xyRange_um(1),xyRange_um(2),numSamplesXY);
    y = linspace(xyRange_um(1),xyRange_um(2),numSamplesXY);
    [X,Y] = ndgrid(x,y);

    numPlanes = numel(zPositions_um);
    nCols = ceil(sqrt(numPlanes));
    nRows = ceil(numPlanes / nCols);

    hFig = figure( ...
        'Name','Current SLM Power Correction', ...
        'NumberTitle','off', ...
        'Color','w');
    tiledlayout(hFig,nRows,nCols,'Padding','compact','TileSpacing','compact');

    for planeIdx = 1:numPlanes
        z = zPositions_um(planeIdx);
        Z = z .* ones(size(X));

        efficiency = interpolant(X(:),Y(:),Z(:));
        efficiency = reshape(efficiency,size(X));
        efficiency = max(efficiency, eps);
        powerCorrection = 1 ./ efficiency;

        nexttile;
        imagesc(x,y,powerCorrection');
        axis image;
        set(gca,'YDir','normal');
        colorbar;
        title(sprintf('z = %.0f um', z));
        xlabel('x (um)');
        ylabel('y (um)');
    end

    sgtitle(sprintf('Current SLM power correction over x/y = [%.0f, %.0f] um', ...
        xyRange_um(1),xyRange_um(2)));
end

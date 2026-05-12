classdef MroiTileAcquisition < most.Gui
    properties (SetObservable)
        finalZoom = 4;
        overlapPct = 10;
        framesPerTile = 3;
        pixelMultiplier = 1;
        cellposeBatchSize = 1;
        cellposeBsize = 256;
    end

    properties (Access = private)
        etStatus;
        etSummary;
        backup = struct('valid',false);
    end

    methods (Static)
        function h = launch()
            hSI = [];
            hSICtl = [];
            try
                if dabs.resources.ResourceStore.isInstantiated()
                    rs = dabs.resources.ResourceStore();
                    hSI = rs.filterByClass('scanimage.SI');
                    if iscell(hSI)
                        if ~isempty(hSI)
                            hSI = hSI{1};
                        else
                            hSI = [];
                        end
                    end
                end
            catch
                hSI = [];
            end

            if isempty(hSI)
                try
                    if evalin('base','exist(''hSI'',''var'')')
                        hSI = evalin('base','hSI');
                    end
                catch
                    hSI = [];
                end
            end

            if most.idioms.isValidObj(hSI) && ~isempty(hSI.hController)
                hSICtl = hSI.hController{1};
            else
                hSI = [];
            end

            cls = mfilename('class');
            h = feval(cls, hSI, hSICtl);
            h.raise();
        end
    end

    methods
        function obj = MroiTileAcquisition(hModel, hController)
            if nargin < 1
                hModel = [];
            end
            if nargin < 2
                hController = [];
            end
            obj@most.Gui(hModel, hController, [560 250], 'pixels');
        end

        function delete(obj)
            delete@most.Gui(obj);
        end
    end

    methods (Access = protected)
        function initGui(obj)
            set(obj.hFig,'Name','MROI Tile Acquisition','Resize','on');

            mainFlow = most.gui.uiflowcontainer('Parent',obj.hFig,'FlowDirection','TopDown');
            panel = uipanel('Parent',mainFlow,'Title','Tiling Settings');
            panelFlow = most.gui.uiflowcontainer('Parent',panel,'FlowDirection','TopDown');

            addRow(panelFlow, 'Final Zoom', obj, 'finalZoom');
            addRow(panelFlow, 'Overlap (%)', obj, 'overlapPct');
            addRow(panelFlow, 'Frames / Tile', obj, 'framesPerTile');
            addRow(panelFlow, 'Pixel Multiplier', obj, 'pixelMultiplier');
            addRow(panelFlow, 'Cellpose Batch', obj, 'cellposeBatchSize');
            addRow(panelFlow, 'Cellpose Bsize', obj, 'cellposeBsize');

            buttonFlow = most.gui.uiflowcontainer('Parent',mainFlow,'FlowDirection','LeftToRight','HeightLimits',[24 24]);
            obj.addUiControl('Parent',buttonFlow,'Style','pushbutton','String','Preview', ...
                'Callback',@obj.previewTiles);
            obj.addUiControl('Parent',buttonFlow,'Style','pushbutton','String','Apply Tiled MROI', ...
                'Callback',@obj.applyTiledMroi);
            obj.addUiControl('Parent',buttonFlow,'Style','pushbutton','String','Apply + Grab', ...
                'Callback',@obj.applyAndGrab);
            obj.addUiControl('Parent',buttonFlow,'Style','pushbutton','String','Grab + Save TIFF/ROI', ...
                'Callback',@obj.grabAndSavePerRoiTiffs);
            obj.addUiControl('Parent',buttonFlow,'Style','pushbutton','String','Run Cellpose', ...
                'Callback',@obj.runCellposeForRunDir);
            obj.addUiControl('Parent',buttonFlow,'Style','pushbutton','String','Import Cellpose Seg', ...
                'Callback',@obj.importCellposeSegmentation);
            obj.addUiControl('Parent',buttonFlow,'Style','pushbutton','String','Restore', ...
                'Callback',@obj.restoreOriginal);
            obj.addUiControl('Parent',buttonFlow,'Style','pushbutton','String','Close', ...
                'Callback',@(~,~)delete(obj));

            sumFlow = most.gui.uiflowcontainer('Parent',mainFlow,'FlowDirection','LeftToRight','HeightLimits',[20 20]);
            obj.etSummary = obj.addUiControl('Parent',sumFlow,'Style','text','String','', ...
                'HorizontalAlignment','left');

            statusFlow = most.gui.uiflowcontainer('Parent',mainFlow,'FlowDirection','LeftToRight','HeightLimits',[20 20]);
            obj.etStatus = obj.addUiControl('Parent',statusFlow,'Style','text','String','Ready', ...
                'HorizontalAlignment','left');

            function addRow(parent, label, model, prop, bindingType)
                if nargin < 5 || isempty(bindingType)
                    bindingType = 'value';
                end
                row = most.gui.uiflowcontainer('Parent',parent,'FlowDirection','LeftToRight','HeightLimits',[22 22]);
                most.gui.uicontrol('Parent',row,'Style','text','String',label,'WidthLimits',[120 120], ...
                    'HorizontalAlignment','right');
                most.gui.uicontrol('Parent',row,'Style','edit','Bindings',{model prop bindingType});
            end
        end
    end

    methods (Access = private)
        function previewTiles(obj, varargin)
            try
                hSI = obj.resolveSI();
                rgSource = obj.getSourceRoiGroupForTiling(hSI);
                [~, info] = obj.buildTiledRoiGroup(hSI, rgSource);
                obj.setSummary(sprintf('ROIs: %d | Tiles: %d | Zoom: %.3g | Overlap: %.1f%% | Pix x%.3g', ...
                    info.baseRois, info.totalTiles, obj.finalZoom, obj.overlapPct, obj.pixelMultiplier));
                obj.setStatus('Preview computed.');
            catch ME
                obj.setStatus(sprintf('Preview failed: %s', ME.message));
            end
        end

        function ok = applyTiledMroi(obj, varargin)
            ok = false;
            try
                hSI = obj.resolveSI();
                assert(~obj.isSiActiveSafe(hSI), 'Stop acquisition before applying tiled MROI.');

                if ~isstruct(obj.backup) || ~isfield(obj.backup,'valid') || ~obj.backup.valid
                    rgCur = hSI.hRoiManager.currentRoiGroup;
                    assert(~localRoiGroupAppearsTiled(rgCur), ...
                        ['Current ROI group appears already tiled. ' ...
                         'Load/restore the untiled ROI group, then retry.']);
                    obj.captureBackup(hSI);
                end
                rgSource = obj.getSourceRoiGroupForTiling(hSI);
                [rgTiled, info] = obj.buildTiledRoiGroup(hSI, rgSource);

                hSI.hRoiManager.scanZoomFactor = obj.finalZoom;
                hSI.hRoiManager.roiGroupMroi = rgTiled;
                hSI.hRoiManager.mroiEnable = true;
                obj.setFramesPerAcqSafe(hSI, max(1, round(obj.framesPerTile)));

                obj.setSummary(sprintf('ROIs: %d | Tiles: %d | Frames/tile: %d | Pix x%.3g', ...
                    info.baseRois, info.totalTiles, round(obj.framesPerTile), obj.pixelMultiplier));
                obj.setStatus('Applied tiled MROI.');
                ok = true;
            catch ME
                obj.setStatus(sprintf('Apply failed: %s', ME.message));
            end
        end

        function applyAndGrab(obj, varargin)
            try
                ok = obj.applyTiledMroi();
                if ~ok
                    return;
                end
                hSI = obj.resolveSI();
                assert(~obj.isSiActiveSafe(hSI), 'Acquisition already active.');
                hSI.startGrab();
                obj.setStatus('Applied tiled MROI and started GRAB.');
            catch ME
                obj.setStatus(sprintf('Apply+Grab failed: %s', ME.message));
            end
        end

        function grabAndSavePerRoiTiffs(obj, varargin)
            hSI = [];
            try
                hSI = obj.resolveSI();
                assert(~obj.isSiActiveSafe(hSI), 'Stop acquisition before running Grab + Save.');

                ok = obj.applyTiledMroi();
                if ~ok
                    return;
                end
                rgTiled = hSI.hRoiManager.roiGroupMroi;
                assert(~isempty(rgTiled) && most.idioms.isValidObj(rgTiled) && ~isempty(rgTiled.rois), ...
                    'Tiled ROI group is empty.');
                rgTiled = rgTiled.copy();

                rootDir = uigetdir(pwd, 'Select output folder for TIFF files');
                if isequal(rootDir,0)
                    obj.setStatus('Grab + Save cancelled.');
                    return;
                end
                runDir = obj.reserveOutputDir(rootDir);
                obj.saveRunMetadataSafe(runDir);
                exportDir = fullfile(runDir, 'per_roi');
                if ~exist(exportDir, 'dir')
                    mkdir(exportDir);
                end
                stitchedDir = fullfile(runDir, 'stitched_roi');
                if ~exist(stitchedDir, 'dir')
                    mkdir(stitchedDir);
                end

                logCfg = obj.captureLoggingConfig(hSI);
                cleaner = onCleanup(@()obj.restoreLoggingConfigSafe(hSI, logCfg)); %#ok<NASGU>

                if ~hSI.hChannels.loggingEnable
                    hSI.hChannels.loggingEnable = true;
                end
                logStem = sprintf('mroi_tiles_%s', datestr(now,'yyyymmdd_HHMMSS'));
                hSI.hScan2D.logFilePath = runDir;
                hSI.hScan2D.logFramesPerFile = inf;
                obj.setFramesPerAcqSafe(hSI, max(1, round(obj.framesPerTile)));

                timeout_s = max(15, max(1, round(obj.framesPerTile)) / obj.getFrameRateSafe(hSI) + 10);
                tifPaths = obj.runSequentialTileGrabs(hSI, rgTiled, runDir, logStem, timeout_s);
                assert(~isempty(tifPaths), 'No TIFF files found after GRAB.');
                preferredStitchCh = NaN;
                try
                    preferredStitchCh = localScalarNumeric(hSI.hChannels.channelSave, NaN);
                catch
                    preferredStitchCh = NaN;
                end
                tifPathsForStitch = localFilterTiffPathsByChannel(tifPaths, preferredStitchCh);
                if isempty(tifPathsForStitch)
                    tifPathsForStitch = tifPaths;
                end

                nOut = 0;
                nStitched = 0;
                nAvg8 = 0;
                avg8Dir = fullfile(runDir, 'stitched_avg8');
                if ~exist(avg8Dir, 'dir')
                    mkdir(avg8Dir);
                end

                for iT = 1:numel(tifPaths)
                    nOut = nOut + obj.exportPerRoiFromMroiTiff(tifPaths{iT}, exportDir);
                end
                nStitched = obj.exportStitchedFromMroiTiff(tifPathsForStitch, stitchedDir);
                if nStitched > 0
                    [nAvg8, ~] = obj.exportAverage8bitFromTiffs(stitchedDir, avg8Dir);
                end

                assert(nOut > 0, ...
                    'Per-ROI export produced 0 files. Check channel save settings and TIFF contents.');

                obj.setSummary(sprintf('Source TIFFs: %d | Per-ROI TIFFs: %d | Stitched TIFFs: %d | Avg8 TIFFs: %d', ...
                    numel(tifPaths), nOut, nStitched, nAvg8));
                obj.setStatus(sprintf('Saved per-ROI TIFFs to %s, stitched TIFFs to %s, avg8 TIFFs to %s', ...
                    exportDir, stitchedDir, avg8Dir));
            catch ME
                try
                    if obj.isSiActiveSafe(hSI)
                        hSI.abort();
                    end
                catch
                end
                obj.setStatus(sprintf('Grab + Save failed: %s', ME.message));
                try
                    most.ErrorHandler.logAndReportError(ME);
                catch
                end
            end
        end
        function runCellposeForRunDir(obj, varargin)
            try
                runDir = uigetdir(pwd, 'Select run folder containing stitched_roi or stitched_avg8');
                if isequal(runDir,0)
                    obj.setStatus('Run Cellpose cancelled.');
                    return;
                end

                stitchedDir = fullfile(runDir, 'stitched_roi');
                avg8Dir = fullfile(runDir, 'stitched_avg8');
                cellposeDir = fullfile(runDir, 'cellpose');
                if ~exist(avg8Dir, 'dir')
                    mkdir(avg8Dir);
                end

                avg8Files = [dir(fullfile(avg8Dir, '*_avg8.tif')); dir(fullfile(avg8Dir, '*_avg8.tiff'))];
                if isempty(avg8Files)
                    assert(exist(stitchedDir, 'dir') == 7, ...
                        'No *_avg8 TIFFs found and stitched_roi folder does not exist.');
                    [nAvg8, avg8Paths] = obj.exportAverage8bitFromTiffs(stitchedDir, avg8Dir);
                    assert(nAvg8 > 0 && ~isempty(avg8Paths), ...
                        'Failed to generate *_avg8 TIFFs from stitched TIFFs.');
                else
                    nAvg8 = numel(avg8Files);
                end

                [okCellpose, cmdOut, logPath] = obj.runCellposeBatch(avg8Dir, cellposeDir);
                assert(okCellpose, 'Cellpose failed: %s (log: %s)', strtrim(cmdOut), logPath);

                batchSize = max(1, round(localScalarNumeric(obj.cellposeBatchSize, 1)));
                bsize = max(16, round(localScalarNumeric(obj.cellposeBsize, 256)));

                obj.setSummary(sprintf(['Avg8 TIFFs: %d | Batch: %d | Bsize: %d ' ...
                    '| Cellpose output: %s | Log: %s'], ...
                    nAvg8, batchSize, bsize, cellposeDir, logPath));
                obj.setStatus(sprintf(['Cellpose completed on %d avg8 TIFF(s) ' ...
                    '(batch %d, bsize %d). Log: %s'], ...
                    nAvg8, batchSize, bsize, logPath));
            catch ME
                obj.setStatus(sprintf('Run Cellpose failed: %s', ME.message));
                try
                    most.ErrorHandler.logAndReportError(ME);
                catch
                end
            end
        end

        function importCellposeSegmentation(obj, varargin)
            try
                runDir = uigetdir(pwd, 'Select run folder containing cellpose output');
                if isequal(runDir,0)
                    obj.setStatus('Import Cellpose segmentation cancelled.');
                    return;
                end

                cellposeDir = fullfile(runDir, 'cellpose');
                assert(exist(cellposeDir, 'dir') == 7, ...
                    'Selected run folder does not contain a cellpose directory.');

                maskPaths = obj.findCellposeMaskPaths(cellposeDir);
                assert(~isempty(maskPaths), ...
                    'No Cellpose mask TIFFs found (*_cp_masks.tif or *_masks.tif).');

                meta = obj.loadRunMetadataSafe(runDir);
                pixMult = NaN;
                if isstruct(meta) && isfield(meta, 'pixelMultiplier')
                    pixMult = localScalarNumeric(meta.pixelMultiplier, NaN);
                end
                if ~(isfinite(pixMult) && pixMult > 0)
                    pixMult = localScalarNumeric(obj.pixelMultiplier, 1);
                end
                if ~(isfinite(pixMult) && pixMult > 0)
                    pixMult = 1;
                end
                lowResScale = 1 / pixMult;

                outDir = fullfile(runDir, 'cellpose_lowres');
                if ~exist(outDir, 'dir')
                    mkdir(outDir);
                end

                nMasks = 0;
                nCells = 0;
                for iMask = 1:numel(maskPaths)
                    [nCellsOne, outMaskPath] = obj.importSingleCellposeMaskToLowRes( ...
                        maskPaths{iMask}, outDir, lowResScale);
                    if ~isempty(outMaskPath)
                        nMasks = nMasks + 1;
                        nCells = nCells + nCellsOne;
                    end
                end
                assert(nMasks > 0, 'No Cellpose mask files were converted.');

                obj.setSummary(sprintf(['Imported masks: %d | Cells: %d | Scale: %.4g ' ...
                    '| Output: %s'], nMasks, nCells, lowResScale, outDir));
                obj.setStatus(sprintf(['Imported %d Cellpose mask(s) and mapped ' ...
                    'pixel coordinates to low-res.'], nMasks));
            catch ME
                obj.setStatus(sprintf('Import Cellpose failed: %s', ME.message));
                try
                    most.ErrorHandler.logAndReportError(ME);
                catch
                end
            end
        end

        function saveRunMetadataSafe(obj, runDir)
            try
                if nargin < 2 || isempty(runDir) || exist(runDir, 'dir') ~= 7
                    return;
                end
                meta = struct();
                meta.version = 1;
                meta.created = datestr(now, 31);
                meta.finalZoom = localScalarNumeric(obj.finalZoom, NaN);
                meta.overlapPct = localScalarNumeric(obj.overlapPct, NaN);
                meta.framesPerTile = localScalarNumeric(obj.framesPerTile, NaN);
                meta.pixelMultiplier = localScalarNumeric(obj.pixelMultiplier, NaN);
                save(fullfile(runDir, 'mroi_run_metadata.mat'), '-struct', 'meta');
            catch
            end
        end

        function meta = loadRunMetadataSafe(~, runDir)
            meta = struct();
            try
                if nargin < 2 || isempty(runDir) || exist(runDir, 'dir') ~= 7
                    return;
                end
                metaPath = fullfile(runDir, 'mroi_run_metadata.mat');
                if exist(metaPath, 'file') ~= 2
                    return;
                end
                meta = load(metaPath);
            catch
                meta = struct();
            end
        end

        function maskPaths = findCellposeMaskPaths(~, cellposeDir)
            maskPaths = {};
            if nargin < 2 || isempty(cellposeDir) || exist(cellposeDir, 'dir') ~= 7
                return;
            end

            patterns = {'*_cp_masks.tif', '*_cp_masks.tiff', '*_masks.tif', '*_masks.tiff'};
            f = [];
            for iP = 1:numel(patterns)
                f = [f; dir(fullfile(cellposeDir, patterns{iP}))]; %#ok<AGROW>
            end
            if isempty(f)
                return;
            end
            [~, order] = sort({f.name});
            f = f(order);

            maskPaths = arrayfun(@(x)fullfile(x.folder, x.name), f, 'UniformOutput', false);
            maskPaths = unique(maskPaths, 'stable');
        end

        function [nCells, outMaskPath] = importSingleCellposeMaskToLowRes(~, srcMaskPath, outDir, scaleFactor)
            nCells = 0;
            outMaskPath = '';

            assert(nargin >= 3 && ~isempty(srcMaskPath) && exist(srcMaskPath, 'file') == 2, ...
                'Cellpose mask file does not exist.');
            if nargin < 4 || isempty(scaleFactor)
                scaleFactor = 1;
            end
            scaleFactor = localScalarNumeric(scaleFactor, 1);
            if ~(isfinite(scaleFactor) && scaleFactor > 0)
                scaleFactor = 1;
            end

            info = imfinfo(srcMaskPath);
            assert(~isempty(info), 'Could not read TIFF metadata: %s', srcMaskPath);
            mask = imread(srcMaskPath, 1, 'Info', info);
            if ndims(mask) > 2
                mask = mask(:,:,1);
            end
            assert(isnumeric(mask) || islogical(mask), 'Cellpose mask is not numeric: %s', srcMaskPath);

            mask = double(mask);
            mask(~isfinite(mask)) = 0;
            mask(mask < 0) = 0;
            mask = round(mask);

            if abs(scaleFactor - 1) > 1e-12
                outSz = max([1 1], round(size(mask,1:2) .* scaleFactor));
                mask = imresize(mask, outSz, 'nearest');
                mask = round(mask);
            end

            maxLabel = max(mask(:));
            if ~isfinite(maxLabel) || maxLabel <= double(intmax('uint16'))
                maskOut = uint16(mask);
            else
                maskOut = uint32(mask);
            end

            [~, stem, ~] = fileparts(srcMaskPath);
            stem = regexprep(stem, '(?:_cp_masks|_masks)$', '');
            stem = localSanitizeFilename(stem);

            outMaskPath = fullfile(outDir, sprintf('%s_lowres_cp_masks.tif', stem));
            imwrite(maskOut, outMaskPath, 'Compression', 'none');

            labels = unique(maskOut(:));
            labels = double(labels(labels > 0));
            nCells = numel(labels);

            csvPath = fullfile(outDir, sprintf('%s_lowres_cells.csv', stem));
            matPath = fullfile(outDir, sprintf('%s_lowres_pixels.mat', stem));

            labelCol = zeros(nCells,1);
            centroidX = zeros(nCells,1);
            centroidY = zeros(nCells,1);
            areaPx = zeros(nCells,1);
            pixelCoords = cell(nCells,1);

            for iL = 1:nCells
                lbl = labels(iL);
                [r, c] = find(maskOut == lbl);
                if isempty(r)
                    continue;
                end
                labelCol(iL) = lbl;
                centroidX(iL) = mean(c);
                centroidY(iL) = mean(r);
                areaPx(iL) = numel(r);
                pixelCoords{iL} = [c r];
            end

            T = table(labelCol, centroidX, centroidY, areaPx, ...
                'VariableNames', {'label','centroid_x','centroid_y','area_px'});
            writetable(T, csvPath);

            save(matPath, 'srcMaskPath', 'outMaskPath', 'scaleFactor', 'labels', 'pixelCoords');
        end

        function restoreOriginal(obj, varargin)
            try
                hSI = obj.resolveSI();
                assert(~obj.isSiActiveSafe(hSI), 'Stop acquisition before restore.');
                if ~isstruct(obj.backup) || ~isfield(obj.backup,'valid') || ~obj.backup.valid
                    obj.setStatus('No backup to restore.');
                    return;
                end

                if isfield(obj.backup,'scanZoomFactor') && isfinite(obj.backup.scanZoomFactor)
                    hSI.hRoiManager.scanZoomFactor = obj.backup.scanZoomFactor;
                end
                if isfield(obj.backup,'roiGroup') && ~isempty(obj.backup.roiGroup) && most.idioms.isValidObj(obj.backup.roiGroup)
                    hSI.hRoiManager.roiGroupMroi = obj.backup.roiGroup;
                end
                if isfield(obj.backup,'mroiEnable')
                    hSI.hRoiManager.mroiEnable = logical(obj.backup.mroiEnable);
                end
                if isfield(obj.backup,'framesPerAcq') && isfinite(obj.backup.framesPerAcq)
                    obj.setFramesPerAcqSafe(hSI, obj.backup.framesPerAcq);
                end

                obj.backup = struct('valid',false);
                obj.setSummary('');
                obj.setStatus('Restored original ROI/scan settings.');
            catch ME
                obj.setStatus(sprintf('Restore failed: %s', ME.message));
            end
        end

        function captureBackup(obj, hSI)
            b = struct();
            b.valid = true;
            b.mroiEnable = hSI.hRoiManager.mroiEnable;
            b.scanZoomFactor = localScalarNumeric(hSI.hRoiManager.scanZoomFactor, NaN);
            b.roiGroup = [];
            try
                rg = hSI.hRoiManager.roiGroupMroi;
                if ~isempty(rg) && most.idioms.isValidObj(rg)
                    b.roiGroup = rg.copy();
                end
            catch
                b.roiGroup = [];
            end
            b.framesPerAcq = NaN;
            try
                b.framesPerAcq = localScalarNumeric(hSI.hScan2D.framesPerAcq, NaN);
            catch
            end
            obj.backup = b;
        end

        function rgIn = getSourceRoiGroupForTiling(obj, hSI)
            rgIn = [];
            try
                if isstruct(obj.backup) && isfield(obj.backup,'valid') && obj.backup.valid && ...
                        isfield(obj.backup,'roiGroup') && ~isempty(obj.backup.roiGroup) && ...
                        most.idioms.isValidObj(obj.backup.roiGroup)
                    rgIn = obj.backup.roiGroup;
                end
            catch
                rgIn = [];
            end
            if isempty(rgIn)
                rgIn = hSI.hRoiManager.currentRoiGroup;
            end
        end

        function [rgOut, info] = buildTiledRoiGroup(obj, hSI, rgIn)
            validateattributes(obj.finalZoom, {'numeric'}, {'scalar','finite','real','nonnan','>',0});
            validateattributes(obj.overlapPct, {'numeric'}, {'scalar','finite','real','nonnan','>=',0,'<',99});
            validateattributes(obj.framesPerTile, {'numeric'}, {'scalar','finite','real','nonnan','>=',1});
            validateattributes(obj.pixelMultiplier, {'numeric'}, {'scalar','finite','real','nonnan','>',0});

            if nargin < 3 || isempty(rgIn) || ~most.idioms.isValidObj(rgIn)
                rgIn = hSI.hRoiManager.currentRoiGroup;
            end
            assert(~isempty(rgIn) && most.idioms.isValidObj(rgIn), 'Current ROI group is not available.');
            assert(~isempty(rgIn.rois), 'Current ROI group has no ROIs.');

            currentZoom = localScalarNumeric(hSI.hRoiManager.scanZoomFactor, 1);
            sourceZoom = currentZoom;
            try
                if isstruct(obj.backup) && isfield(obj.backup,'valid') && obj.backup.valid && ...
                        isfield(obj.backup,'scanZoomFactor') && isfinite(obj.backup.scanZoomFactor)
                    sourceZoom = localScalarNumeric(obj.backup.scanZoomFactor, currentZoom);
                end
            catch
                sourceZoom = currentZoom;
            end
            overlapFrac = max(0, min(0.98, obj.overlapPct / 100));
            zoomScale = sourceZoom / obj.finalZoom;
            assert(zoomScale > 0, 'Invalid zoom scaling.');

            rgOut = scanimage.mroi.RoiGroup(sprintf('TiledMROI_Z%.3g_Ov%.1f', obj.finalZoom, obj.overlapPct));

            totalTiles = 0;
            for iRoi = 1:numel(rgIn.rois)
                roiIn = rgIn.rois(iRoi);
                if isempty(roiIn.scanfields)
                    continue;
                end

                sfRef = roiIn.scanfields(1);
                baseSize = double(sfRef.sizeXY);
                baseCenter = double(sfRef.centerXY);

                tileSize = baseSize .* zoomScale;
                tileSize = max(baseSize ./ 4096, min(baseSize, tileSize));
                step = tileSize .* (1 - overlapFrac);
                step = max(tileSize ./ 1e6, step);

                nXY = max([1 1], ceil((baseSize - tileSize) ./ step) + 1);
                spanXY = (nXY - 1) .* step + tileSize;
                originXY = baseCenter - spanXY/2 + tileSize/2;
                [ix, iy] = ndgrid(0:nXY(1)-1, 0:nXY(2)-1);
                centers = [originXY(1) + ix(:)*step(1), originXY(2) + iy(:)*step(2)];

                for iTile = 1:size(centers,1)
                    roiOut = scanimage.mroi.Roi();
                    roiOut.name = sprintf('%s_T%03d', localRoiName(roiIn, iRoi), iTile);

                    zList = [];
                    try
                        zList = roiIn.zs;
                    catch
                        zList = [];
                    end
                    if isempty(zList)
                        zList = 0;
                    end
                    zList = zList(:).';

                    for iZ = 1:numel(zList)
                        sfIn = [];
                        try
                            sfIn = roiIn.get(zList(iZ));
                        catch
                            sfIn = [];
                        end
                        if isempty(sfIn)
                            sfIn = sfRef;
                        end
                        if numel(sfIn) > 1
                            sfIn = sfIn(1);
                        end

                        sfOut = sfIn.copy();
                        sfOut.centerXY = centers(iTile,:);
                        sfOut.sizeXY = tileSize;
                        % Increase per-tile pixel grid to intentionally add
                        % spatial samples at higher zoom.
                        sfPix = double(sfIn.pixelResolutionXY);
                        if numel(sfPix) < 2 || any(~isfinite(sfPix(1:2))) || any(sfPix(1:2) <= 0)
                            sfPix = [512 512];
                        end
                        pixScale = localScalarNumeric(obj.pixelMultiplier, 1);
                        pixResOut = max([2 2], round(sfPix(1:2) .* pixScale));
                        pixResOut = max([2 2], 2*ceil(pixResOut/2));
                        sfOut.pixelResolutionXY = pixResOut;
                        roiOut.add(zList(iZ), sfOut);
                    end

                    rgOut.add(roiOut);
                end

                totalTiles = totalTiles + size(centers,1);
            end

            info = struct();
            info.baseRois = numel(rgIn.rois);
            info.totalTiles = totalTiles;
        end

        function setFramesPerAcqSafe(~, hSI, nFrames)
            nFrames = max(1, round(localScalarNumeric(nFrames, 1)));
            try
                hSI.hScan2D.framesPerAcq = nFrames;
            catch
                if ~isempty(hSI.hStackManager) && most.idioms.isValidObj(hSI.hStackManager)
                    hSI.hStackManager.enable = false;
                    hSI.hStackManager.framesPerSlice = nFrames;
                end
            end
        end

        function cfg = captureLoggingConfig(~, hSI)
            cfg = struct();
            cfg.valid = true;
            cfg.logFilePath = '';
            cfg.logFileStem = '';
            cfg.logFramesPerFile = [];
            cfg.loggingEnable = [];
            cfg.channelSave = [];
            try
                cfg.logFilePath = hSI.hScan2D.logFilePath;
            catch
            end
            try
                cfg.logFileStem = hSI.hScan2D.logFileStem;
            catch
            end
            try
                cfg.logFramesPerFile = hSI.hScan2D.logFramesPerFile;
            catch
            end
            try
                cfg.loggingEnable = hSI.hChannels.loggingEnable;
            catch
            end
            try
                cfg.channelSave = hSI.hChannels.channelSave;
            catch
            end
        end

        function restoreLoggingConfigSafe(~, hSI, cfg)
            try
                if ~most.idioms.isValidObj(hSI) || ~isstruct(cfg) || ~isfield(cfg,'valid') || ~cfg.valid
                    return;
                end
                if ~isempty(hSI.active) && hSI.active
                    hSI.abort();
                    pause(0.1);
                end
            catch
            end

            try
                if isfield(cfg,'logFilePath') && ischar(cfg.logFilePath)
                    hSI.hScan2D.logFilePath = cfg.logFilePath;
                end
            catch
            end
            try
                if isfield(cfg,'logFileStem') && ischar(cfg.logFileStem)
                    hSI.hScan2D.logFileStem = cfg.logFileStem;
                end
            catch
            end
            try
                if isfield(cfg,'logFramesPerFile') && ~isempty(cfg.logFramesPerFile)
                    hSI.hScan2D.logFramesPerFile = cfg.logFramesPerFile;
                end
            catch
            end
            try
                if isfield(cfg,'channelSave') && ~isempty(cfg.channelSave)
                    hSI.hChannels.channelSave = cfg.channelSave;
                end
            catch
            end
            try
                if isfield(cfg,'loggingEnable') && ~isempty(cfg.loggingEnable)
                    hSI.hChannels.loggingEnable = logical(cfg.loggingEnable);
                end
            catch
            end
        end

        function runDir = reserveOutputDir(~, rootDir)
            stamp = datestr(now,'yyyymmdd_HHMMSS');
            base = sprintf('mroi_tiles_%s', stamp);
            runDir = fullfile(rootDir, base);
            k = 1;
            while exist(runDir, 'dir')
                runDir = fullfile(rootDir, sprintf('%s_%02d', base, k));
                k = k + 1;
                if k > 99
                    error('Could not reserve unique output directory.');
                end
            end
            [ok, msg] = mkdir(runDir);
            if ~ok
                error('Could not create output directory: %s', msg);
            end
        end

        function rate = getFrameRateSafe(~, hSI)
            rate = NaN;
            try
                if most.idioms.isValidObj(hSI) && ~isempty(hSI.hRoiManager) && most.idioms.isValidObj(hSI.hRoiManager)
                    rate = localScalarNumeric(hSI.hRoiManager.scanFrameRate, NaN);
                end
            catch
                rate = NaN;
            end
            if ~isfinite(rate) || rate <= 0
                rate = 30;
            end
        end

        function tf = waitForAcqIdle(obj, hSI, timeout_s)
            tf = false;
            if nargin < 3 || isempty(timeout_s) || ~isfinite(timeout_s) || timeout_s <= 0
                timeout_s = 20;
            end
            tStart = tic;
            while toc(tStart) < timeout_s
                if ~obj.isSiActiveSafe(hSI)
                    tf = true;
                    return;
                end
                pause(0.05);
            end
        end

        function tifPaths = findLoggedTiffs(~, logDir, logStem, tStartDatenum, wait_s)
            tifPaths = {};
            if nargin < 5 || isempty(wait_s) || ~isfinite(wait_s) || wait_s <= 0
                wait_s = 5;
            end
            pattern = fullfile(logDir, sprintf('%s*.tif', logStem));
            t0 = tic;
            while toc(t0) < wait_s
                f = dir(pattern);
                if ~isempty(f)
                    if nargin >= 4 && isfinite(tStartDatenum)
                        f = f([f.datenum] >= (tStartDatenum - 2/86400));
                    end
                    if ~isempty(f)
                        tifPaths = arrayfun(@(x)fullfile(x.folder,x.name), f, 'UniformOutput', false);
                        return;
                    end
                end
                pause(0.1);
            end
        end

        function nOut = exportPerRoiFromMroiTiff(~, srcPath, outDir)
            nOut = 0;
            [roiData, ~] = scanimage.util.getMroiDataFromTiff(srcPath);
            if isempty(roiData)
                return;
            end

            [~, srcStem, ~] = fileparts(srcPath);
            srcStem = regexprep(srcStem, '\s+', '_');

            for iRoi = 1:numel(roiData)
                rd = roiData{iRoi};
                if ~isobject(rd) || ~isprop(rd, 'imageData') || isempty(rd.imageData)
                    continue;
                end
                nCh = numel(rd.imageData);
                for iCh = 1:nCh
                    imgCell = rd.imageData{iCh};
                    if isempty(imgCell)
                        continue;
                    end

                    chNum = iCh;
                    try
                        if isprop(rd,'channels') && numel(rd.channels) >= iCh && isfinite(rd.channels(iCh))
                            chNum = rd.channels(iCh);
                        end
                    catch
                    end

                    outPath = fullfile(outDir, sprintf('%s_roi%03d_ch%d.tif', srcStem, iRoi, chNum));
                    nFrames = localWriteRoiImageDataToTiff(imgCell, outPath);
                    if nFrames > 0
                        nOut = nOut + 1;
                    else
                        try
                            if exist(outPath,'file')
                                delete(outPath);
                            end
                        catch
                        end
                    end
                end
            end
        end

        function nOut = exportStitchedFromMroiTiff(obj, srcPath, outDir)
            nOut = 0;
            if iscell(srcPath)
                srcPaths = srcPath(:);
            else
                srcPaths = {srcPath};
            end
            srcPaths = srcPaths(~cellfun(@isempty, srcPaths));
            if isempty(srcPaths)
                return;
            end

            tileEntries = struct( ...
                'baseName','', ...
                'channel',NaN, ...
                'center',[NaN NaN], ...
                'pixelSize',[NaN NaN], ...
                'frames',{{}}, ...
                'frameClass','');
            nEntries = 0;

            for iSrc = 1:numel(srcPaths)
                [roiData, ~] = scanimage.util.getMroiDataFromTiff(srcPaths{iSrc});
                if isempty(roiData)
                    continue;
                end

                for iRoi = 1:numel(roiData)
                    rd = roiData{iRoi};
                    if ~isobject(rd) || ~isprop(rd, 'imageData') || isempty(rd.imageData)
                        continue;
                    end

                    roiName = localGetRoiName(rd, iRoi);
                    [baseName, isTile] = localParseTileName(roiName);
                    if ~isTile
                        continue;
                    end

                    [centerXY, pixelSize] = localGetRoiCenterAndPixelSize(rd);
                    if ~all(isfinite(centerXY))
                        continue;
                    end

                    nCh = numel(rd.imageData);
                    for iCh = 1:nCh
                        imgCell = rd.imageData{iCh};
                        frames = localFlattenImageCellFrames(imgCell);
                        if isempty(frames)
                            continue;
                        end

                        chNum = iCh;
                        try
                            if isprop(rd,'channels') && numel(rd.channels) >= iCh && isfinite(rd.channels(iCh))
                                chNum = rd.channels(iCh);
                            end
                        catch
                        end

                        nEntries = nEntries + 1;
                        tileEntries(nEntries).baseName = baseName;
                        tileEntries(nEntries).channel = chNum;
                        tileEntries(nEntries).center = centerXY;
                        tileEntries(nEntries).pixelSize = pixelSize;
                        tileEntries(nEntries).frames = frames;
                        tileEntries(nEntries).frameClass = class(frames{1});
                    end
                end
            end

            if nEntries <= 0
                return;
            end
            tileEntries = tileEntries(1:nEntries);

            [~, runStem, ~] = fileparts(srcPaths{1});
            runStem = regexprep(runStem, '\s+', '_');
            runStem = regexprep(runStem, '_t\d{4}.*$', '');
            if isempty(runStem)
                runStem = 'mroi_tiles';
            end
            overlapFrac = max(0, min(0.98, obj.overlapPct / 100));

            baseNames = unique({tileEntries.baseName}, 'stable');
            for iBase = 1:numel(baseNames)
                baseName = baseNames{iBase};
                baseMask = strcmp({tileEntries.baseName}, baseName);
                entriesBase = tileEntries(baseMask);
                if isempty(entriesBase)
                    continue;
                end

                chListAll = unique([entriesBase.channel], 'stable');
                if isempty(chListAll)
                    continue;
                end
                % Export one stitched mosaic per original ROI (not per channel):
                % pick the first available channel for that ROI.
                chList = chListAll(1);
                for iCh = 1:numel(chList)
                    chNum = chList(iCh);
                    chMask = [entriesBase.channel] == chNum;
                    entries = entriesBase(chMask);
                    if isempty(entries)
                        continue;
                    end

                    stitchedFrames = localBuildStitchedFrames(entries, overlapFrac);
                    if isempty(stitchedFrames)
                        continue;
                    end

                    outPath = fullfile(outDir, sprintf('%s_%s_stitched_ch%d.tif', ...
                        runStem, localSanitizeFilename(baseName), chNum));
                    nFrames = localWriteRoiImageDataToTiff({{stitchedFrames}}, outPath);
                    if nFrames > 0
                        nOut = nOut + 1;
                    else
                        try
                            if exist(outPath,'file')
                                delete(outPath);
                            end
                        catch
                        end
                    end
                end
            end
        end

        function tifPaths = runSequentialTileGrabs(obj, hSI, rgTiled, runDir, logStemBase, timeout_s)
            tifPaths = {};
            assert(most.idioms.isValidObj(hSI), 'ScanImage handle is invalid.');
            assert(~isempty(rgTiled) && most.idioms.isValidObj(rgTiled) && ~isempty(rgTiled.rois), ...
                'No tiled ROIs available for sequential acquisition.');

            nTiles = numel(rgTiled.rois);
            try
                for iTile = 1:nTiles
                    obj.setStatus(sprintf('Acquiring tile %d/%d...', iTile, nTiles));
                    drawnow();

                    if obj.isSiActiveSafe(hSI)
                        hSI.abort();
                        pause(0.1);
                    end

                    rgSingle = scanimage.mroi.RoiGroup(sprintf('%s_tile%04d', rgTiled.name, iTile));
                    rgSingle.add(rgTiled.rois(iTile).copy());
                    hSI.hRoiManager.roiGroupMroi = rgSingle;
                    hSI.hRoiManager.mroiEnable = true;

                    tileStem = sprintf('%s_t%04d', logStemBase, iTile);
                    hSI.hScan2D.logFileStem = tileStem;
                    tStart = now;
                    hSI.startGrab();

                    okIdle = obj.waitForAcqIdle(hSI, timeout_s);
                    assert(okIdle, 'Timed out waiting for GRAB completion on tile %d/%d.', iTile, nTiles);

                    tileTiffs = obj.findLoggedTiffs(runDir, tileStem, tStart, 8);
                    assert(~isempty(tileTiffs), 'No TIFF file found for tile %d/%d.', iTile, nTiles);
                    tifPaths = [tifPaths; tileTiffs(:)]; %#ok<AGROW>
                end
            catch ME
                try
                    if most.idioms.isValidObj(hSI)
                        hSI.hRoiManager.roiGroupMroi = rgTiled;
                        hSI.hRoiManager.mroiEnable = true;
                    end
                catch
                end
                rethrow(ME);
            end

            try
                hSI.hRoiManager.roiGroupMroi = rgTiled;
                hSI.hRoiManager.mroiEnable = true;
            catch
            end
        end


        function [nOut, outPaths] = exportAverage8bitFromTiffs(~, srcDir, outDir)
            nOut = 0;
            outPaths = {};
            if nargin < 2 || isempty(srcDir) || ~exist(srcDir, 'dir')
                return;
            end
            if nargin < 3 || isempty(outDir)
                outDir = srcDir;
            end
            if ~exist(outDir, 'dir')
                mkdir(outDir);
            end

            f = [dir(fullfile(srcDir, '*.tif')); dir(fullfile(srcDir, '*.tiff'))];
            if isempty(f)
                return;
            end
            [~, order] = sort({f.name});
            f = f(order);

            for iF = 1:numel(f)
                srcPath = fullfile(f(iF).folder, f(iF).name);
                info = [];
                try
                    info = imfinfo(srcPath);
                catch
                    info = [];
                end
                if isempty(info)
                    continue;
                end

                acc = [];
                nFramesValid = 0;
                for iFrame = 1:numel(info)
                    img = [];
                    try
                        img = imread(srcPath, iFrame, 'Info', info);
                    catch
                        img = [];
                    end
                    if isempty(img) || (~isnumeric(img) && ~islogical(img))
                        continue;
                    end
                    if ndims(img) > 2
                        img = img(:,:,1);
                    end

                    if isempty(acc)
                        acc = zeros(size(img,1), size(img,2), 'single');
                    end
                    if ~isequal(size(img,1), size(acc,1)) || ~isequal(size(img,2), size(acc,2))
                        continue;
                    end

                    acc = acc + single(img);
                    nFramesValid = nFramesValid + 1;
                end

                if isempty(acc) || nFramesValid < 1
                    continue;
                end

                avgImg = acc / nFramesValid;
                avg8 = localScaleToUint8(avgImg);

                [~, stem, ~] = fileparts(srcPath);
                outPath = fullfile(outDir, sprintf('%s_avg8.tif', stem));
                try
                    imwrite(avg8, outPath, 'Compression', 'none');
                    nOut = nOut + 1;
                    outPaths{end+1,1} = outPath; %#ok<AGROW>
                catch
                end
            end
        end
        function [ok, cmdOut, logPath] = runCellposeBatch(obj, inDir, outDir)
            ok = false;
            cmdOut = '';
            logPath = '';
            assert(nargin >= 2 && ~isempty(inDir) && exist(inDir, 'dir'), ...
                'Cellpose input directory does not exist.');

            if nargin < 3 || isempty(outDir)
                outDir = inDir;
            end
            if ~exist(outDir, 'dir')
                mkdir(outDir);
            end

            inFiles = [dir(fullfile(inDir, '*_avg8.tif')); dir(fullfile(inDir, '*_avg8.tiff'))];
            assert(~isempty(inFiles), ...
                'No *_avg8 TIFF files found in %s.', inDir);

            userHome = getenv('USERPROFILE');
            pyCandidates = { ...
                fullfile(userHome, 'miniconda3', 'envs', 'cellpose', 'python.exe'), ...
                fullfile(userHome, 'anaconda3', 'envs', 'cellpose', 'python.exe'), ...
                'python'};
            pyExe = '';
            for iC = 1:numel(pyCandidates)
                c = pyCandidates{iC};
                if strcmpi(c, 'python') || exist(c, 'file')
                    pyExe = c;
                    break;
                end
            end
            assert(~isempty(pyExe), 'Could not find Python executable for conda env "cellpose".');

            logPath = fullfile(outDir, sprintf('cellpose_log_%s.txt', datestr(now,'yyyymmdd_HHMMSS')));

            batchSize = max(1, round(localScalarNumeric(obj.cellposeBatchSize, 1)));
            bsize = max(16, round(localScalarNumeric(obj.cellposeBsize, 256)));

            cmd = sprintf(['"%s" -m cellpose ' ...
                '--dir "%s" --savedir "%s" --img_filter "_avg8" ' ...
                '--pretrained_model cpsam --batch_size %d --bsize %d ' ...
                '--save_tif --no_npy --verbose 2>&1'], ...
                pyExe, inDir, outDir, batchSize, bsize);

            [status, cmdOut] = system(cmd);

            try
                fid = fopen(logPath, 'wt');
                if fid > 0
                    fprintf(fid, 'Timestamp: %s\n', datestr(now, 31));
                    fprintf(fid, 'Command: %s\n', cmd);
                    fprintf(fid, 'ExitCode: %d\n\n', status);
                    fprintf(fid, '%s\n', cmdOut);
                    fclose(fid);
                end
            catch
            end

            ok = (status == 0);
            assert(ok, 'Cellpose batch failed (exit code %d). See log: %s', status, logPath);
        end

        function hSI = resolveSI(obj)
            hSI = obj.hModel;
            if ~most.idioms.isValidObj(hSI)
                hSI = [];
            end
            if isempty(hSI)
                try
                    if dabs.resources.ResourceStore.isInstantiated()
                        rs = dabs.resources.ResourceStore();
                        hSI = rs.filterByClass('scanimage.SI');
                        if iscell(hSI)
                            if ~isempty(hSI)
                                hSI = hSI{1};
                            else
                                hSI = [];
                            end
                        end
                    end
                catch
                    hSI = [];
                end
            end
            if isempty(hSI)
                try
                    if evalin('base','exist(''hSI'',''var'')')
                        hSI = evalin('base','hSI');
                    end
                catch
                    hSI = [];
                end
            end
            assert(most.idioms.isValidObj(hSI), 'ScanImage is not running.');
        end

        function tf = isSiActiveSafe(~, hSI)
            tf = false;
            try
                if ~most.idioms.isValidObj(hSI)
                    return;
                end
                if isprop(hSI, 'active')
                    tf = localToLogical(hSI.active);
                    if tf
                        return;
                    end
                end
                if isprop(hSI, 'acqState')
                    s = hSI.acqState;
                    if isstring(s)
                        s = char(s);
                    end
                    if ischar(s)
                        tf = any(strcmpi(s, {'focus','grab','loop','loop_wait'}));
                    end
                end
            catch
                tf = false;
            end
        end

        function setStatus(obj, msg)
            if isempty(obj.etStatus) || ~most.idioms.isValidObj(obj.etStatus)
                return;
            end
            obj.etStatus.String = msg;
        end

        function setSummary(obj, msg)
            if isempty(obj.etSummary) || ~most.idioms.isValidObj(obj.etSummary)
                return;
            end
            obj.etSummary.String = msg;
        end
    end
end

function name = localRoiName(roi, iFallback)
    name = '';
    try
        name = roi.name;
    catch
        name = '';
    end
    if isstring(name)
        name = char(name);
    end
    if ~ischar(name) || isempty(strtrim(name))
        name = sprintf('ROI%d', iFallback);
    else
        name = strtrim(name);
    end
    name = regexprep(name, '\s+', '_');
end

function tf = localToLogical(v)
    tf = false;
    if isempty(v)
        return;
    end
    if islogical(v)
        tf = any(v(:));
        return;
    end
    if isnumeric(v)
        tf = any(v(:) ~= 0);
        return;
    end
    if isstring(v)
        if isscalar(v)
            v = char(v);
        else
            tf = any(v ~= "");
            return;
        end
    end
    if ischar(v)
        s = strtrim(lower(v));
        if isempty(s) || strcmp(s,'idle') || strcmp(s,'false') || strcmp(s,'0') || strcmp(s,'off')
            tf = false;
        else
            tf = true;
        end
        return;
    end
    try
        tf = logical(v);
        if ~isscalar(tf)
            tf = any(tf(:));
        end
    catch
        tf = false;
    end
end

function v = localScalarNumeric(x, defaultValue)
    if nargin < 2
        defaultValue = NaN;
    end
    v = defaultValue;
    if isempty(x)
        return;
    end
    if islogical(x)
        x = double(x);
    end
    if ~isnumeric(x)
        try
            x = double(x);
        catch
            return;
        end
    end
    x = x(:);
    x = x(isfinite(x));
    if isempty(x)
        return;
    end
    v = x(end);
end

function name = localGetRoiName(rd, iFallback)
    name = '';
    try
        if isprop(rd, 'hRoi') && ~isempty(rd.hRoi) && isprop(rd.hRoi, 'name')
            name = rd.hRoi.name;
        end
    catch
        name = '';
    end
    if isstring(name)
        name = char(name);
    end
    if ~ischar(name) || isempty(strtrim(name))
        name = sprintf('ROI%d', iFallback);
    else
        name = strtrim(name);
    end
end

function [baseName, isTile] = localParseTileName(name)
    if isstring(name)
        name = char(name);
    end
    if ~ischar(name)
        name = '';
    end
    % Strip one or more trailing tile suffixes (_T###) to recover the
    % original untiled ROI name.
    tok = regexp(name, '^(.*?)(?:_T\d+)+$', 'tokens', 'once');
    if isempty(tok)
        baseName = name;
        isTile = false;
        return;
    end
    baseName = tok{1};
    if isempty(baseName)
        baseName = name;
    end
    isTile = true;
end

function [centerXY, pixelSize] = localGetRoiCenterAndPixelSize(rd)
    centerXY = [NaN NaN];
    pixelSize = [NaN NaN];
    try
        if ~isprop(rd, 'hRoi') || isempty(rd.hRoi)
            return;
        end

        z = 0;
        if isprop(rd, 'zs') && ~isempty(rd.zs) && isfinite(rd.zs(1))
            z = rd.zs(1);
        end

        sf = [];
        try
            sf = rd.hRoi.get(z);
        catch
            sf = [];
        end
        if isempty(sf)
            try
                if isprop(rd.hRoi, 'scanfields') && ~isempty(rd.hRoi.scanfields)
                    sf = rd.hRoi.scanfields(1);
                end
            catch
                sf = [];
            end
        end
        if isempty(sf)
            return;
        end
        if numel(sf) > 1
            sf = sf(1);
        end

        centerXY = double(sf.centerXY);
        sizeXY = double(sf.sizeXY);
        pixXY = double(sf.pixelResolutionXY);
        if numel(sizeXY) >= 2 && numel(pixXY) >= 2 && ...
                all(isfinite(pixXY(1:2))) && all(pixXY(1:2) > 0)
            pixelSize = sizeXY(1:2) ./ pixXY(1:2);
        end
    catch
        centerXY = [NaN NaN];
        pixelSize = [NaN NaN];
    end
end

function frames = localFlattenImageCellFrames(imgCell)
    frames = {};
    if isempty(imgCell)
        return;
    end
    if ~iscell(imgCell)
        imgCell = {imgCell};
    end

    for iVol = 1:numel(imgCell)
        volCell = imgCell{iVol};
        if isempty(volCell)
            continue;
        end
        if ~iscell(volCell)
            volCell = {volCell};
        end

        for iSlc = 1:numel(volCell)
            frameCell = volCell{iSlc};
            if isempty(frameCell)
                continue;
            end
            if ~iscell(frameCell)
                frameCell = {frameCell};
            end

            for iFrm = 1:numel(frameCell)
                img = frameCell{iFrm};
                if isempty(img) || (~isnumeric(img) && ~islogical(img))
                    continue;
                end
                if ndims(img) > 2
                    if size(img,3) == 1
                        img = img(:,:,1);
                    else
                        continue;
                    end
                end
                frames{end+1,1} = img; %#ok<AGROW>
            end
        end
    end
end

function stitchedFrames = localBuildStitchedFrames(entries, overlapFrac)
    stitchedFrames = {};
    if nargin < 2 || isempty(overlapFrac) || ~isfinite(overlapFrac)
        overlapFrac = 0;
    end
    overlapFrac = max(0, min(0.98, overlapFrac));

    if isempty(entries)
        return;
    end

    nTiles = numel(entries);
    nFrames = inf;
    for i = 1:nTiles
        nFrames = min(nFrames, numel(entries(i).frames));
    end
    if ~isfinite(nFrames) || nFrames < 1
        return;
    end
    nFrames = floor(nFrames);

    xVals = localUniqueTol(arrayfun(@(e)e.center(1), entries));
    yVals = localUniqueTol(arrayfun(@(e)e.center(2), entries));
    if isempty(xVals) || isempty(yVals)
        return;
    end

    firstFrame = entries(1).frames{1};
    tileH = size(firstFrame,1);
    tileW = size(firstFrame,2);
    if tileH < 1 || tileW < 1
        return;
    end

    pixXY = vertcat(entries.pixelSize);
    pixX = pixXY(:,1);
    pixY = pixXY(:,2);
    pixX = pixX(isfinite(pixX) & pixX > 0);
    pixY = pixY(isfinite(pixY) & pixY > 0);
    if isempty(pixX)
        pixX = NaN;
    else
        pixX = median(pixX);
    end
    if isempty(pixY)
        pixY = NaN;
    else
        pixY = median(pixY);
    end

    stepX = NaN;
    stepY = NaN;
    if numel(xVals) > 1 && isfinite(pixX) && pixX > 0
        dx = diff(xVals);
        dx = dx(isfinite(dx) & abs(dx) > 0);
        if ~isempty(dx)
            stepX = round(abs(median(dx)) / pixX);
        end
    end
    if numel(yVals) > 1 && isfinite(pixY) && pixY > 0
        dy = diff(yVals);
        dy = dy(isfinite(dy) & abs(dy) > 0);
        if ~isempty(dy)
            stepY = round(abs(median(dy)) / pixY);
        end
    end
    if ~(isfinite(stepX) && stepX > 0)
        stepX = max(1, round(tileW * (1 - overlapFrac)));
    end
    if ~(isfinite(stepY) && stepY > 0)
        stepY = max(1, round(tileH * (1 - overlapFrac)));
    end

    xStart = zeros(nTiles,1);
    yStart = zeros(nTiles,1);
    outW = 0;
    outH = 0;
    for i = 1:nTiles
        [~, ix] = min(abs(xVals - entries(i).center(1)));
        [~, iy] = min(abs(yVals - entries(i).center(2)));
        xStart(i) = 1 + (ix - 1) * stepX;
        yStart(i) = 1 + (iy - 1) * stepY;

        img0 = entries(i).frames{1};
        outW = max(outW, xStart(i) + size(img0,2) - 1);
        outH = max(outH, yStart(i) + size(img0,1) - 1);
    end
    if outW < 1 || outH < 1
        return;
    end

    frameClass = entries(1).frameClass;
    if isempty(frameClass)
        frameClass = class(firstFrame);
    end

    stitchedFrames = cell(nFrames,1);
    for iFrame = 1:nFrames
        acc = zeros(outH, outW, 'double');
        wgt = zeros(outH, outW, 'double');
        for i = 1:nTiles
            if numel(entries(i).frames) < iFrame
                continue;
            end
            img = entries(i).frames{iFrame};
            if isempty(img) || (~isnumeric(img) && ~islogical(img))
                continue;
            end
            h = size(img,1);
            w = size(img,2);
            yy = yStart(i):(yStart(i)+h-1);
            xx = xStart(i):(xStart(i)+w-1);
            acc(yy,xx) = acc(yy,xx) + double(img);
            wgt(yy,xx) = wgt(yy,xx) + 1;
        end

        out = zeros(outH, outW, 'double');
        valid = wgt > 0;
        out(valid) = acc(valid) ./ wgt(valid);
        stitchedFrames{iFrame} = localCastFrameToClass(out, frameClass);
    end
end

function vals = localUniqueTol(v)
    vals = [];
    if isempty(v)
        return;
    end
    v = double(v(:));
    v = v(isfinite(v));
    if isempty(v)
        return;
    end

    tol = max(1e-9, 1e-6 * max(1, max(abs(v))));
    v = sort(v);
    vals = v(1);
    for i = 2:numel(v)
        if abs(v(i) - vals(end)) > tol
            vals(end+1,1) = v(i); %#ok<AGROW>
        else
            vals(end,1) = (vals(end) + v(i)) / 2;
        end
    end
end

function out = localCastFrameToClass(img, className)
    switch className
        case 'logical'
            out = img > 0;
        case 'uint8'
            out = uint8(min(max(round(img), double(intmin('uint8'))), double(intmax('uint8'))));
        case 'int8'
            out = int8(min(max(round(img), double(intmin('int8'))), double(intmax('int8'))));
        case 'uint16'
            out = uint16(min(max(round(img), double(intmin('uint16'))), double(intmax('uint16'))));
        case 'int16'
            out = int16(min(max(round(img), double(intmin('int16'))), double(intmax('int16'))));
        case 'uint32'
            out = uint32(min(max(round(img), double(intmin('uint32'))), double(intmax('uint32'))));
        case 'int32'
            out = int32(min(max(round(img), double(intmin('int32'))), double(intmax('int32'))));
        case 'single'
            out = single(img);
        case 'double'
            out = double(img);
        otherwise
            out = single(img);
    end
end

function name = localSanitizeFilename(name)
    if isstring(name)
        name = char(name);
    end
    if ~ischar(name)
        name = '';
    end
    name = strtrim(name);
    if isempty(name)
        name = 'roi';
    end
    name = regexprep(name, '[<>:"/\\|?*]', '_');
    name = regexprep(name, '\s+', '_');
    name = regexprep(name, '\.+$', '');
    if isempty(name)
        name = 'roi';
    end
end


function img8 = localScaleToUint8(imgIn)
    img8 = uint8([]);
    if isempty(imgIn)
        return;
    end

    img = single(imgIn);
    img(~isfinite(img)) = 0;

    lo = min(img(:));
    hi = max(img(:));
    if ~isfinite(lo) || ~isfinite(hi) || hi <= lo
        img8 = zeros(size(img), 'uint8');
        return;
    end

    img = (img - lo) ./ (hi - lo);
    img = min(max(img, 0), 1);
    img8 = uint8(round(255 * img));
end

function outPaths = localFilterTiffPathsByChannel(tifPaths, channelNum)
    outPaths = {};
    if isempty(tifPaths) || ~isfinite(channelNum)
        outPaths = tifPaths;
        return;
    end

    hasTagged = false;
    for i = 1:numel(tifPaths)
        p = tifPaths{i};
        [~, nm, ~] = fileparts(p);
        tok = regexp(nm, '_chn(\d+)$', 'tokens', 'once');
        if isempty(tok)
            continue;
        end
        hasTagged = true;
        ch = str2double(tok{1});
        if isfinite(ch) && round(ch) == round(channelNum)
            outPaths{end+1,1} = p; %#ok<AGROW>
        end
    end

    if ~hasTagged
        outPaths = tifPaths;
    end
end

function nFrames = localWriteRoiImageDataToTiff(imgCell, outPath)
% imgCell format: {volume}{sliceIdx}{frameIdx} = 2D image

    nFrames = 0;
    wroteFirst = false;
    tObj = [];
    baseClass = '';
    baseSize = [0 0];
    bitsPerSample = [];
    sampleFormat = [];
    rowsPerStrip = [];
    cleanupObj = onCleanup(@()localCloseTiffSafe(tObj)); %#ok<NASGU>

    for iVol = 1:numel(imgCell)
        volCell = imgCell{iVol};
        if isempty(volCell)
            continue;
        end
        for iSlc = 1:numel(volCell)
            frameCell = volCell{iSlc};
            if isempty(frameCell)
                continue;
            end
            for iFrm = 1:numel(frameCell)
                img = frameCell{iFrm};
                if isempty(img) || (~isnumeric(img) && ~islogical(img))
                    continue;
                end

                [img, imgBits, imgSampleFmt] = localNormalizeFrameForTiff(img);
                if isempty(img)
                    continue;
                end

                if ~wroteFirst
                    baseClass = class(img);
                    baseSize = size(img);
                    bitsPerSample = imgBits;
                    sampleFormat = imgSampleFmt;

                    % Keep strips modest to avoid libtiff write failures on
                    % very large stitched frames.
                    rowsPerStrip = localRowsPerStrip(size(img,2), bitsPerSample, size(img,1));

                    % Prefer BigTIFF for large mosaics; fall back if not
                    % supported by this MATLAB build.
                    try
                        tObj = Tiff(outPath, 'w8');
                    catch
                        tObj = Tiff(outPath, 'w');
                    end
                else
                    assert(isequal(size(img), baseSize), ...
                        'All frames in one per-ROI TIFF must have identical dimensions.');
                    if ~strcmp(class(img), baseClass)
                        img = cast(img, baseClass);
                    end
                end

                if wroteFirst
                    tObj.writeDirectory();
                end

                tagStruct = struct( ...
                    'ImageLength', size(img,1), ...
                    'ImageWidth', size(img,2), ...
                    'Photometric', Tiff.Photometric.MinIsBlack, ...
                    'Compression', Tiff.Compression.None, ...
                    'BitsPerSample', bitsPerSample, ...
                    'SamplesPerPixel', 1, ...
                    'RowsPerStrip', rowsPerStrip, ...
                    'PlanarConfiguration', Tiff.PlanarConfiguration.Chunky, ...
                    'SampleFormat', sampleFormat);
                tObj.setTag(tagStruct);
                tObj.write(img);

                wroteFirst = true;
                nFrames = nFrames + 1;
            end
        end
    end

    localCloseTiffSafe(tObj);
end

function rowsPerStrip = localRowsPerStrip(imgWidth, bitsPerSample, imgHeight)
    rowsPerStrip = 1;
    if nargin < 3 || ~isfinite(imgHeight) || imgHeight < 1
        imgHeight = 1;
    end
    if nargin < 2 || ~isfinite(bitsPerSample) || bitsPerSample <= 0
        bitsPerSample = 16;
    end
    if nargin < 1 || ~isfinite(imgWidth) || imgWidth < 1
        imgWidth = 1;
    end

    bytesPerRow = double(imgWidth) * double(bitsPerSample) / 8;
    if ~isfinite(bytesPerRow) || bytesPerRow <= 0
        rowsPerStrip = 1;
        return;
    end

    targetStripBytes = 8 * 1024 * 1024;
    rowsPerStrip = max(1, floor(targetStripBytes / bytesPerRow));
    rowsPerStrip = min(max(1, round(rowsPerStrip)), max(1, round(double(imgHeight))));
end

function [imgOut, bitsPerSample, sampleFormat] = localNormalizeFrameForTiff(imgIn)
    bitsPerSample = [];
    sampleFormat = [];
    imgOut = [];

    if isempty(imgIn)
        return;
    end

    if ndims(imgIn) > 2
        if size(imgIn,3) == 1
            imgIn = imgIn(:,:,1);
        else
            % Per-ROI exports are single-channel grayscale frames.
            return;
        end
    end

    switch class(imgIn)
        case 'logical'
            imgOut = uint8(imgIn);
            bitsPerSample = 8;
            sampleFormat = Tiff.SampleFormat.UInt;
        case 'uint8'
            imgOut = imgIn;
            bitsPerSample = 8;
            sampleFormat = Tiff.SampleFormat.UInt;
        case 'int8'
            imgOut = int16(imgIn);
            bitsPerSample = 16;
            sampleFormat = Tiff.SampleFormat.Int;
        case 'uint16'
            imgOut = imgIn;
            bitsPerSample = 16;
            sampleFormat = Tiff.SampleFormat.UInt;
        case 'int16'
            imgOut = imgIn;
            bitsPerSample = 16;
            sampleFormat = Tiff.SampleFormat.Int;
        case 'uint32'
            imgOut = imgIn;
            bitsPerSample = 32;
            sampleFormat = Tiff.SampleFormat.UInt;
        case 'int32'
            imgOut = imgIn;
            bitsPerSample = 32;
            sampleFormat = Tiff.SampleFormat.Int;
        case {'single','double'}
            imgOut = single(imgIn);
            bitsPerSample = 32;
            sampleFormat = Tiff.SampleFormat.IEEEFP;
        otherwise
            if isnumeric(imgIn)
                imgOut = single(imgIn);
                bitsPerSample = 32;
                sampleFormat = Tiff.SampleFormat.IEEEFP;
            end
    end
end

function localCloseTiffSafe(tObj)
    try
        if ~isempty(tObj)
            close(tObj);
        end
    catch
    end
end

function tf = localRoiGroupAppearsTiled(rg)
    tf = false;
    try
        if isempty(rg) || ~isprop(rg,'rois') || isempty(rg.rois)
            return;
        end
        names = arrayfun(@(r)localRoiName(r,1), rg.rois, 'UniformOutput', false);
        tiledMask = ~cellfun(@isempty, regexp(names, '(?:_T\d+)+$', 'once'));
        % Consider it "already tiled" if the majority of ROI names carry
        % tile suffixes.
        tf = mean(double(tiledMask)) > 0.5;
    catch
        tf = false;
    end
end

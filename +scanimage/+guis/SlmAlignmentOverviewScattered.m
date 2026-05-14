classdef SlmAlignmentOverviewScattered < scanimage.guis.SlmAlignmentOverview
    methods
        function obj = SlmAlignmentOverviewScattered(hSlmScan)
            obj@scanimage.guis.SlmAlignmentOverview(hSlmScan);
        end

        function showDiffractionEfficiencyTool(obj,allowSavingZCalibration)
            msg = sprintf('Choose a diffraction efficiency calibration method.\n\n');
            most.gui.nonBlockingDialog('SLM Diffraction Efficiency', msg, ...
                {{'Sub-stage camera' @useSubStageCameraSlmCalibration} ...
                 {'Enter function' @set3DInterpolantByFunction} ...
                 {'Use SLM acquired Images of Uniform Sample (Scattered)' @add3DInterpolantBySlmAcquiredImagesScattered}}, ...
                'b','Position',[0 0 700 150],'Name','Diffraction Efficiency Calibration');

            function useSubStageCameraSlmCalibration
                hTool = obj.hSICtl.hGuiClasses.SubStageCameraSlmCalibration;
                hTool.allowSavingZCalibration = allowSavingZCalibration;
                hTool.raise();
            end

            function set3DInterpolantByFunction
                opts = struct;
                opts.WindowStyle = 'normal';

                queries = {'Function Handle returning efficiency as an equation of X,Y, and Z in microns relative to reference space'};
                queryDefaultValues = {'@(x_um, y_um, z_um) mean([(105-abs(x_um))/105, (105-abs(y_um))/105, (105-abs(z_um))/105],2)'};
                fieldWidth = [1 100];

                answer = most.gui.inputdlgCentered(queries,'SLM Diffraction Efficiency',repmat(fieldWidth,numel(queries),1),queryDefaultValues,opts);

                if ~isempty(answer)
                    try
                        try
                            fcn = str2func(answer{1});

                            testXYZ = rand(10,3) * 100;
                            for i = 1:10
                                val = fcn(testXYZ(i,1),testXYZ(i,2),testXYZ(i,3));
                                validateattributes(val,{'numeric'},{'scalar','nonempty','real','positive'});
                            end
                        catch ME
                            msg = sprintf('There was something wrong with the diffraction efficiency function supplied.\n%s',ME.message);
                            error(msg);
                        end
                    catch ME
                        most.ErrorHandler.logAndReportError(ME);
                    end

                    obj.hSlmScan.hSlm.hCSDiffractionEfficiency.reset();
                    obj.hSlmScan.hSlm.hCSDiffractionEfficiency.delete();
                    scanimage.util.setCustomSLMPowerFunction(fcn);
                    obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSlmScan.hSlm.hCSDiffractionEfficiency,'changed',@(varargin)obj.redraw);

                    try
                        obj.hSI.hCoordinateSystems.save();
                    catch ME
                        most.ErrorHandler.logAndReportError(ME);
                    end
                end
            end

            function add3DInterpolantBySlmAcquiredImagesScattered()
                folder = uigetdir('F:\SLM', ...
                    'Select folder containing SLM acquired TIFF files of a homogenously fluorescent sample.');

                if isequal(folder,0)
                    return;
                end

                tifs = dir(fullfile(folder,'*.tif'));
                tiffs = dir(fullfile(folder,'*.tiff'));
                fileStruct = [tifs; tiffs];
                assert(~isempty(fileStruct),'No TIFF files were found in the selected folder.');
                FILENAME = {fileStruct.name};
                PATHNAME = folder;

                opts = struct;
                opts.WindowStyle = 'normal';
                queries = { ...
                    'Median filter width in pixels (use 1 for no smoothing)', ...
                    'Median filter height in pixels (use 1 for no smoothing)'};
                queryDefaultValues = {'1','1'};
                fieldWidth = [1 50];
                answer = most.gui.inputdlgCentered(queries,'Scattered TIFF smoothing', ...
                    repmat(fieldWidth,numel(queries),1),queryDefaultValues,opts);
                if isempty(answer)
                    return;
                end
                medianFilterWindow = [str2double(answer{1}) str2double(answer{2})];
                validateattributes(medianFilterWindow,{'numeric'}, ...
                    {'vector','numel',2,'integer','positive','finite'});

                disp('Scattered TIFF correction: loading TIFF files...');
                ptsPerFile = cell(numel(FILENAME),1);
                imagePerFile = cell(numel(FILENAME),1);
                parkZs = nan(numel(FILENAME),1);
                hWait = waitbar(0,'Loading TIFF files...');
                waitbarCleanup = onCleanup(@()closeWaitbarSafely(hWait)); %#ok<NASGU>
                for tifIdx = 1:numel(FILENAME)
                    [roiData, roiGroup, header, imageData] = scanimage.util.getMroiDataFromTiff(fullfile(PATHNAME,FILENAME{tifIdx}));

                    assert(isfield(header.SI.hScan2D,'parkPosition_um'),'TIFFs must be acquired with the SLM scanner.');
                    assert(isscalar(roiGroup.rois) && isscalar(roiGroup.rois.scanfields),'Stack must be acquired without MROI');
                    assert(isscalar(roiData),'roiData must be scalar');

                    roiData = roiData{1};
                    scanfield = roiGroup.rois(1).scanfields;
                    assert(scanfield.rotationDegrees == 0,'There must be no rotation of the imaging field');
                    assert(scanfield.pixelResolutionXY(1) == scanfield.pixelResolutionXY(2),'Pixels per line must equal lines per frame.');
                    pixelResolution = scanfield.pixelResolutionXY(1);

                    assert(pixelResolution < 65,'Image resolution must be less than 65 pixels in either direction');
                    assert(numel(roiData.zs) < 65,'Stack must contain 64 or fewer slices.');
                    parkZs(tifIdx) = header.SI.hScan2D.parkPosition_um(1,3);

                    [xx_pix, yy_pix, zz_um] = ndgrid(1:pixelResolution,1:pixelResolution,header.SI.hScan2D.parkPosition_um(1,3));
                    pts_ref = scanimage.mroi.util.xformPoints([xx_pix(:) yy_pix(:)],scanfield.pixelToRefTransform);
                    pts_ref = scanimage.mroi.coordinates.Points(obj.hSI.hCoordinateSystems.hCSReference,[pts_ref zz_um(:)]);
                    pts_SLM = pts_ref.transform(obj.hSlmScan.hSlm.hCoordinateSystem);
                    ptsPerFile{tifIdx} = pts_SLM.points;

                    imageData = double(imageData);
                    imageData = pagetranspose(imageData);
                    if ndims(imageData) > 2
                        imageData = reshape(imageData,size(imageData,1),size(imageData,2),[]);
                        imageData = mean(imageData,3);
                    end
                    if any(medianFilterWindow > 1)
                        imageData = medfilt2(imageData,medianFilterWindow,'symmetric');
                    end
                    imagePerFile{tifIdx} = imageData;
                    updateWaitbarSafely(hWait, tifIdx / numel(FILENAME), ...
                        sprintf('Loading TIFF files... %d%%', round(100 * tifIdx / numel(FILENAME))));
                end

                disp('Scattered TIFF correction: grouping TIFFs by SLM Z...');
                [zKeys, sortOrder] = sort(round(parkZs(:),9));
                sortedParkZs = parkZs(sortOrder);
                sortedPts = ptsPerFile(sortOrder);
                sortedImages = imagePerFile(sortOrder);
                depthChange = [true; diff(zKeys) ~= 0];
                uniqueDepthKeys = zKeys(depthChange);
                uniqueZs = sortedParkZs(depthChange); %#ok<NASGU>
                numDepths = numel(uniqueDepthKeys);

                disp('Scattered TIFF correction: averaging frames within each depth...');
                totalPts_SLM = [];
                totalImageStack = zeros(pixelResolution,pixelResolution,numDepths);
                for depthIdx = 1:numDepths
                    if depthIdx < numDepths
                        mask = zKeys >= uniqueDepthKeys(depthIdx) & zKeys < uniqueDepthKeys(depthIdx + 1);
                    else
                        mask = zKeys >= uniqueDepthKeys(depthIdx);
                    end

                    depthImages = sortedImages(mask);
                    depthPts = sortedPts(mask);
                    totalImageStack(:,:,depthIdx) = mean(cat(3,depthImages{:}),3);
                    totalPts_SLM = cat(1,totalPts_SLM,depthPts{1});
                end

                disp('Scattered TIFF correction: applying floor normalization and 2P conversion...');
                floorPixelValue = prctile(totalImageStack(:),5);
                maxPixelValue = max(totalImageStack,[],'all');
                assert(maxPixelValue > floorPixelValue,'Image stack max must exceed the 5th percentile floor.');

                imageStack_emission_Norm = (totalImageStack - floorPixelValue) ./ (maxPixelValue - floorPixelValue);
                imageStack_emission_Norm = min(max(imageStack_emission_Norm,0),1);

                efficiency = sqrt(imageStack_emission_Norm);
                efficiency(efficiency < 0.02) = 0.02;

                disp('Scattered TIFF correction: building scattered interpolant...');
                interpolant = scatteredInterpolant(totalPts_SLM(:,1),totalPts_SLM(:,2),totalPts_SLM(:,3),efficiency(:), ...
                    'natural','nearest');

                disp('Scattered TIFF correction: updating ScanImage diffraction-efficiency LUT...');
                obj.hSlmScan.hSlm.hCSDiffractionEfficiency.fromParentInterpolant{1} = interpolant;
                obj.hSI.hCoordinateSystems.save();
                disp('Scattered TIFF correction: done.');

                debug = true;
                if debug
                    xyz = interpolant.Points;
                    x = linspace(min(xyz(:,1)),max(xyz(:,1)),100);
                    y = linspace(min(xyz(:,2)),max(xyz(:,2)),100);
                    z = linspace(min(xyz(:,3)),max(xyz(:,3)),20);
                    [a,b,c] = ndgrid(x,y,z);
                    eff = interpolant(a(:),b(:),c(:));
                    hFig = figure(105);
                    hold off;
                    scatter3(a(:),b(:),c(:),5,eff,'filled','MarkerFaceAlpha',0.05);
                    colorbar();
                    colormap(hFig,'turbo');
                    xlabel('x');
                    ylabel('y');
                    set(gca,'YDir','reverse');
                    set(gca,'ZDir','reverse');
                end
            end
        end
    end
end

function updateWaitbarSafely(hWait, frac, msg)
try
    if ~isempty(hWait) && isgraphics(hWait)
        waitbar(frac, hWait, msg);
    end
catch
end
end

function closeWaitbarSafely(hWait)
try
    if ~isempty(hWait) && isgraphics(hWait)
        close(hWait);
    end
catch
end
end

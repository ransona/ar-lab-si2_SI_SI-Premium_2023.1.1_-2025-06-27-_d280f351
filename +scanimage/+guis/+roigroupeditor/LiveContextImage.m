classdef LiveContextImage < scanimage.guis.roigroupeditor.ContextImageProvider
    
    properties (Hidden)
        hSI;
        hDisplay;
        
        hCamListener;
        
        scannerChans;
        numScannerChans;
        numScannerChansWithMerge;
        selectedChannelIsScanner;
        selectedChannelIsScannerMerge;
        hSelectedCam;
        
        scannerLiveNeedsReset = true;
        modelPresent = false;
        rollingAverageFactor = 1;
        
        scannerRoisActive = true;
        movementSinceAcqStart;
    end
    
    %% Lifecycle
    methods
        function obj = LiveContextImage(hEditorGui)
            obj = obj@scanimage.guis.roigroupeditor.ContextImageProvider(hEditorGui);
            obj.name = 'Live Image';
            obj.allowDelete = false;
            
            if most.idioms.isValidObj(hEditorGui.hModel)
                obj.modelPresent = true;
                obj.hSI = hEditorGui.hModel;
                obj.hDisplay = obj.hSI.hDisplay;
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI.hUserFunctions, 'frameAcquired', @obj.frameAcquired);
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI.hCameraManager, 'cameraLastFrameUpdated', @obj.cameraFrameAcquired);
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hDisplay, 'displayReset', @obj.siDisplayReset);
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hDisplay, 'displayRollingAverageFactor', 'PostSet', @obj.avgFactorChanged);
                
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hDisplay, 'chan1LUT', 'PostSet', @obj.updateImageData);
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hDisplay, 'chan2LUT', 'PostSet', @obj.updateImageData);
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hDisplay, 'chan3LUT', 'PostSet', @obj.updateImageData);
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hDisplay, 'chan4LUT', 'PostSet', @obj.updateImageData);
                
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI.hStackManager, 'zs', 'PostSet', @obj.updateZ);
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI.hMotors, 'samplePosition', 'PostSet', @obj.updateZ);

                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI.hChannels, 'channelDisplay', 'PostSet', @(varargin)obj.updateChannelOptions);            
            end
            
            obj.updateChannelOptions();
            obj.channelSelIdx = 1;

        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.hCamListener);
        end
    end
    
    %% Friend
    methods
        function decorateLegendItem(obj, itemHandles)
            obj.decorateLegendItem@scanimage.guis.roigroupeditor.ContextImageProvider(itemHandles);
            
            most.gui.uicontrol('parent',itemHandles.hContainer,'string','Snap Shot','callback',...
                @obj.takeSnapshot,'KeyPressFcn', @obj.hEditorGui.keyPressFcn, 'WidthLimits', [30 64]);
        end
        
        function updateChannelOptions(obj)
            oldChSel = [];
            if ~isempty(obj.channels)
                oldChSel = obj.channels{obj.channelSelIdx};
            end
            
            if obj.modelPresent
                if isa(obj.hSI.hScanner, 'scanimage.components.scan2d.LinScan')
                    obj.scannerChans = obj.hSI.hChannels.channelsActive;
                elseif isempty(obj.hDisplay.lastAcqStripeDataBuffer)
                    obj.scannerChans = obj.hSI.hChannels.channelDisplay;
                else
                    obj.scannerChans = obj.hDisplay.lastAcqStripeDataBuffer{1}.channelNumbers;
                end
                
                obj.numScannerChans = numel(obj.scannerChans);
                obj.numScannerChansWithMerge = obj.numScannerChans;
                chans = arrayfun(@(ch){sprintf('CH%d',ch)},obj.scannerChans);
                if (obj.numScannerChans > 1) && obj.hDisplay.channelsMergeEnable
                    obj.numScannerChansWithMerge = obj.numScannerChans + 1;
                    chans{end+1} = 'Merge';
                end
                
                if ~isempty(obj.hSI.hCameraManager.hCameraWrappers)
                    cameraNames = {obj.hSI.hCameraManager.hCameraWrappers.cameraName};
                    chans = [chans(:)', cameraNames(:)'];
                end
                
                if isempty(chans)
                    obj.channels = {''};
                else
                    obj.channels = chans;
                end
            else
                obj.numScannerChans = 4;
                obj.channels = {'CH1', 'CH2', 'CH3', 'CH4', 'Merge', 'Camera'};
            end
            
            if ~isempty(oldChSel)
                [tf,idx] = ismember(oldChSel,obj.channels);
                if tf
                    obj.channelSelIdx = idx;
                else
                    obj.channelSelIdx = 1;
                end
            else
                obj.channelSelIdx = 1;
            end
        end
        
        function avgFactorChanged(obj,varargin)
            if obj.hSI.active
                obj.rollingAverageFactor = obj.hDisplay.displayRollingAverageFactor;
            end
        end
        
        function v = show(obj)
            v = true;
            
            if ~obj.modelPresent
                return;
            end
            
            if obj.selectedChannelIsScanner || obj.selectedChannelIsScannerMerge
                if obj.hSI.active || obj.hSI.acqInitInProgress
                    if ~obj.scannerRoisActive
                        obj.zs = [];
                        obj.roiCPs = [];
                        obj.scannerLiveNeedsReset = true;
                        obj.scannerRoisActive = true;
                    end
                elseif ~isempty(obj.hDisplay.lastAcqStripeDataBuffer)
                    if isempty(obj.zs) || ~obj.scannerRoisActive
                        obj.resetLastAcqScannerRois();
                    end
                else
                    obj.zs = [];
                    obj.roiCPs = [];
                    obj.scannerRoisActive = true;
                    obj.z = obj.hEditorGui.editorZ;
                end
            else
                obj.resetCameraRois();
            end
        end
        
        function resetCameraRois(obj)
            obj.scannerRoisActive = false;
            
            [xx, yy] = obj.hSelectedCam.getRefCornerPoints();
            
            obj.zs = obj.hSI.hStackManager.zs(1);
            obj.roiCPs = {{[xx(:,1) yy(:,1); xx([2 1], 2) yy([2 1], 2)]}};
            obj.roiAffines = {{nan}};
            
            obj.z = obj.hEditorGui.editorZ;
        end
        
        function resetLastAcqScannerRois(obj)
            zs = [];
            rois = {};
            affs = {};
            
            % determine where all the image surfs need to be
            for i = 1:numel(obj.hDisplay.lastAcqStripeDataBuffer)
                stripeData = obj.hDisplay.lastAcqStripeDataBuffer{i};
                
                if isempty(stripeData.roiData) || isempty(stripeData.roiData{1}.zs)
                    continue
                end
                
                z = stripeData.roiData{1}.zs;
                zs = [zs z];
                zRois = {};
                zAffs = {};
                
                for j = 1:numel(stripeData.roiData)
                    rd = stripeData.roiData{j};
                    sf = rd.hRoi.get(z);
                    zRois{end+1} = sf.cornerpoints();
                    zAffs{end+1} = sf.affine;
                end
                
                rois{end+1} = zRois;
                affs{end+1} = zAffs;
            end
            
            obj.zs = zs;
            obj.roiCPs = rois;
            obj.roiAffines = affs;
            obj.z = obj.hEditorGui.editorZ;
            obj.scannerRoisActive = true;
        end

        function hPtAbsolute = convertSampleCoordinatestoAbsolute(obj,pts)
            if ~isa(pts,'scanimage.mroi.coordinates.Points')
                if isvector(pts) %assume pts are all zs
                    if ~isrow(pts)
                        pts = pts';
                    end
                    numPoints = numel(pts);

                    pts = [zeros(numPoints,2), pts];
                end


                hPtSampleRelative = scanimage.mroi.coordinates.Points(obj.hSI.hCoordinateSystems.hCSSampleRelative,pts);
            end
            hPtAbsolute = hPtSampleRelative.transform(obj.hSI.hCoordinateSystems.hCSSampleAbsolute);
        end
        
        function resetLiveScannerRois(obj)
            zs = unique(obj.hSI.hStackManager.hZs.transform(obj.hSI.hCoordinateSystems.hCSSampleRelative).points(:,3));
            rois = {};
            affs = {};
            
            % determine where all the image surfs need to be
            for slcIdx = 1:numel(zs)
                z = zs(slcIdx);
                zRois = {};
                zAffs = {};
                
                activeRois_ = obj.hSI.hRoiManager.currentRoiGroup.activeRois;
                mask = scanimage.mroi.util.fastRoiHitZ(activeRois_,z);
                scanRois = activeRois_(mask);
                sfs = arrayfun(@(r)r.get(z),scanRois,'UniformOutput',false);
                sfs = removeInvalidScanfields(sfs); % for sanity
                
                for j = 1:numel(sfs)
                    cps = sfs{j}.cornerpoints();
                    zRois{end+1} = cps;
                    zAffs{end+1} = sfs{j}.affine;
                end
                
                rois{end+1} = zRois;
                affs{end+1} = zAffs;
            end
            
            obj.zs = zs;
            obj.roiCPs = rois;
            obj.roiAffines = affs;
            obj.scannerLiveNeedsReset = false;
            obj.z = obj.hEditorGui.editorZ;
            obj.scannerRoisActive = true;
            
            function sfs = removeInvalidScanfields(sfs)
                validMask = cellfun(@(sf)most.idioms.isValidObj(sf),sfs);
                sfs(~validMask) = [];
            end
        end
        
        function v = setChannelIdx(obj,v)
            if 0 == obj.numScannerChans
                return;
            end
            
            obj.selectedChannelIsScanner = v <= obj.numScannerChans;
            obj.selectedChannelIsScannerMerge = ~obj.selectedChannelIsScanner && (v == obj.numScannerChansWithMerge);
            isCameraChannel = ~obj.selectedChannelIsScanner && ~obj.selectedChannelIsScannerMerge;
            
            if isCameraChannel
                i = obj.channelSelIdx - obj.numScannerChansWithMerge;
                obj.hSelectedCam = obj.hSI.hCameraManager.hCameraWrappers(i);
                
                most.idioms.safeDeleteObj(obj.hCamListener);
                obj.hCamListener = most.ErrorHandler.addCatchingListener(obj.hSelectedCam, 'lut', 'PostSet', @obj.updateImageData);
            end
            
            if obj.visible
                if (~isCameraChannel && ~obj.scannerRoisActive) || (isCameraChannel && obj.scannerRoisActive)
                    obj.show();
                end
                
                obj.updateImageData();
            end
        end
        
        function updateScannerImageFromVar(obj,srcVar,channelIdx)
            if isa(obj.hSI.hScanner, 'scanimage.components.scan2d.LinScan')
                channelIdx_ = obj.channels{channelIdx};
                channelIdx_ = str2double(channelIdx_(3));
                channelIdx = find(obj.scannerChans == channelIdx_);
            end
            
            if isempty(obj.hDisplay.(srcVar)) || obj.currZIdx > length(obj.hDisplay.(srcVar)) || isempty(obj.hDisplay.(srcVar){obj.currZIdx})
                return;
            end
            sd = obj.hDisplay.(srcVar){obj.currZIdx};
            if iscell(sd)
                sd = sd{1};
            end
            
            rois = obj.roiCPs{obj.currZIdx};
            nrois = numel(rois);
            
            if nrois == numel(sd.roiData)
                lut = [];
                for i = nrois:-1:1
                    imageData = sd.roiData{i}.imageData;
                    if channelIdx > length(imageData)
                       return; 
                    end
                    img = imageData{channelIdx}{1};
                    if size(img,3) > 1
                        obj.hSurfs(i).CData = img;
                        obj.hSurfs(i).AlphaData = double(sum(img, 3) > 0);
                    else
                        if isempty(lut)
                            lut = single(obj.hSI.hChannels.channelLUT{obj.scannerChans(obj.channelSelIdx)}) * obj.rollingAverageFactor;
                        end
                        [colorData, alphaData] = obj.scaleAndColorCData(img,'gray',lut);
                        obj.hSurfs(i).CData = colorData;
                        obj.hSurfs(i).AlphaData = alphaData;
                    end
                end
            elseif numel(sd.roiData)
                most.idioms.warn('Unexpected context image data');
            else
                for iSurface = 1:length(obj.hSurfs)
                    obj.hSurfs(iSurface).CData = [];
                    obj.hSurfs(iSurface).AlphaData = [];
                end
            end
        end
        
        function updateZ(obj,varargin)
            if strcmpi(obj.hSI.acqState,'idle') || (obj.hSI.hStackManager.enable && strcmpi(obj.hSI.hStackManager.stackMode,'slow'))
                obj.movementSinceAcqStart = 0;
            else
                hCS = obj.hSI.hCoordinateSystems;
                currentZ = hCS.focalPoint.transform(hCS.hCSSampleRelative).points(1,3);
                zAtStackStart = obj.hSI.hStackManager.zs(1);
                obj.movementSinceAcqStart = currentZ - zAtStackStart;
                obj.zs = obj.movementSinceAcqStart + obj.hSI.hStackManager.zs;
            end
            
            obj.hEditorGui.editorZ = obj.hEditorGui.editorZ;
        end
        
        function updateImageData(obj,varargin)
            if isempty(obj.zs) || isempty(obj.currZIdx) || isempty(obj.channelSelIdx) || isempty(obj.selectedChannelIsScanner) || isempty(obj.selectedChannelIsScannerMerge)
               return; 
            end
                
            if obj.selectedChannelIsScanner || obj.selectedChannelIsScannerMerge
                if ~isempty(obj.hDisplay.lastAcqStripeDataBuffer)
                    if obj.selectedChannelIsScanner
                        obj.updateScannerImageFromVar('lastAcqStripeDataBuffer',obj.channelSelIdx);
                    else
                        obj.updateScannerImageFromVar('lastAcqMergeStripeDataBuffer',1);
                    end
                else
                    if obj.selectedChannelIsScanner
                        obj.updateScannerImageFromVar('rollingStripeDataBuffer',obj.channelSelIdx);
                    else
                        obj.updateScannerImageFromVar('mergeStripeDataBuffer',1);
                    end
                end
            else
                dat = obj.hSelectedCam.lastFrame;
                if isempty(dat)
                    colorData = 0;
                    alphaData = 0;
                else
                    [colorData, alphaData] = obj.scaleAndColorCData(dat,'gray',obj.hSelectedCam.lut);
                end
                obj.hSurfs(1).CData = colorData;
                obj.hSurfs(1).AlphaData = alphaData;
            end
        end
        
        function frameAcquired(obj,varargin)
            % If the scanner is at a Z matching the RGE Z indicator, then show the image.
            import scanimage.mroi.coordinates.Points;
            persistent timeSinceLastRefresh;
            
            if isempty(timeSinceLastRefresh)
               timeSinceLastRefresh = tic(); 
            end

            if obj.scannerLiveNeedsReset
                obj.resetLiveScannerRois();
                obj.updateChannelOptions();
                obj.rollingAverageFactor = obj.hDisplay.displayRollingAverageFactor;
            end

            shouldRefresh = obj.visible ...
                && strcmp(obj.hSI.hRoiManager.scanType, 'frame') ... % as opposed to line scan
                && (obj.selectedChannelIsScanner || obj.selectedChannelIsScannerMerge) ...
                && ~isempty(obj.hSI.hDisplay.lastStripeData.roiData)...
                && toc(timeSinceLastRefresh) > 0.1;
            if ~shouldRefresh
                return;
            end

            stripeData = obj.hSI.hDisplay.lastStripeData;

            stackZs = unique(stripeData.zSeries);
            if ~iscolumn(stackZs)
                stackZs = stackZs .';
            end
            initialZPointValues = [zeros(length(stackZs), 2), stackZs];

            hFocalPt = stripeData.focalPoint;
            currentFocalDepth = hFocalPt.points(3); %In Sample Relative coordinates

            StackManager = obj.hSI.hStackManager;
            isLockedFastZ = StackManager.zSeriesLocked ...
                && StackManager.stackMode == scanimage.types.StackMode.fast;

            if ~StackManager.enable || isLockedFastZ
                changeInDepthSinceAcquisitionStart_um = currentFocalDepth - initialZPointValues(1,3);
            else
                % Can't change stage or fastZ position during SlowZ stack
                changeInDepthSinceAcquisitionStart_um = 0;
            end

            currentZPointValues = initialZPointValues + changeInDepthSinceAcquisitionStart_um;

            obj.zRange = [currentZPointValues(1,3), currentZPointValues(end,3)];
            obj.updateProjectionLines();
            timeSinceLastRefresh = tic();
            
            if isempty(obj.currZIdx)
                return;
            end
            
            if obj.selectedChannelIsScanner
                obj.updateScannerImageFromVar('rollingStripeDataBuffer',obj.channelSelIdx);
            else
                obj.updateScannerImageFromVar('mergeStripeDataBuffer',1);
            end
        end
        
        function cameraFrameAcquired(obj, ~, evt)
            if ~obj.visible || obj.selectedChannelIsScanner || obj.selectedChannelIsScannerMerge
                return
            end
            if evt.camSource == obj.hSelectedCam
                [colorData, alphaData] = obj.scaleAndColorCData(obj.hSelectedCam.lastFrame,'gray',obj.hSelectedCam.lut);
                obj.hSurfs(1).CData = colorData;
                obj.hSurfs(1).AlphaData = alphaData;
            end
        end
        
        function siDisplayReset(obj,varargin)
            obj.scannerLiveNeedsReset = obj.scannerLiveNeedsReset || strcmp(obj.hSI.hRoiManager.scanType, 'frame');
        end
        
        function takeSnapshot(obj,varargin)
            clk = clock;
            
            if obj.selectedChannelIsScanner || obj.selectedChannelIsScannerMerge
                ContextImageProperties = fillScannerContextImage();
            else
                ContextImageProperties = fillCameraContextImage();
            end
            
            if isempty(ContextImageProperties)
                return;
            end
            
            timeStr = sprintf('%d:%d:%.2d', clk(4), clk(5), floor(clk(6)));
            
            newColorIdx = obj.hEditorGui.pickMostUniqueCtxImColor();
            newColor = obj.hEditorGui.EDGE_COLOR_LIST{newColorIdx};
            
            hNewContextImg = scanimage.guis.roigroupeditor.ContextImageProvider(obj.hEditorGui);
            hNewContextImg.name = [ContextImageProperties.name timeStr];
            hNewContextImg.source = ContextImageProperties.sourceName;
            hNewContextImg.colorIdx = newColorIdx;
            hNewContextImg.color = newColor;
            hNewContextImg.channels = ContextImageProperties.channels;
            hNewContextImg.imgs = ContextImageProperties.images;
            hNewContextImg.channelSelIdx = ContextImageProperties.channelIndex;
            hNewContextImg.luts = ContextImageProperties.luts;
            hNewContextImg.roiCPs = ContextImageProperties.rois;
            hNewContextImg.roiAffines = ContextImageProperties.affines;
            hNewContextImg.channelMergeColors = ContextImageProperties.channelMergeColor;
            hNewContextImg.zs = ContextImageProperties.zs;
            
            obj.hEditorGui.hContextImages(end+1) = hNewContextImg;
            obj.hEditorGui.updateMaxViewFov();
            obj.hEditorGui.rebuildLegend();
            obj.hEditorGui.setZProjectionLimits();
            obj.hEditorGui.scrollLegendToBottom();
            roiNames = arrayfun(@(roi)roi.name,obj.hEditorGui.editingGroup.rois,'UniformOutput',false);
            contextImageOptions = arrayfun(@(ci)ci.name,obj.hEditorGui.hContextImages,'UniformOutput',false);
            obj.hEditorGui.pmPowerBoxContextImage.String = [{''} contextImageOptions{:}];
            obj.hEditorGui.pmPowerBoxLocation.String = [{''} roiNames{:} contextImageOptions{:}];
            
            obj.visible = false;
            hNewContextImg.visible = true;

            hNewContextImg.updateProjectionLines();
            
            function ContextImageProperties = fillScannerContextImage()
                srcVar = 'rollingStripeDataBuffer';

                channels = [];
                ContextImageProperties.rois = {};
                ContextImageProperties.affines = {};
                ContextImageProperties.images = {};
                ContextImageProperties.zs = [];
                for j = 1:numel(obj.hSI.hDisplay.(srcVar))
                    if iscell(obj.hSI.hDisplay.(srcVar){j})
                        stripeData = obj.hSI.hDisplay.(srcVar){j}{1};
                    else
                        stripeData = obj.hSI.hDisplay.(srcVar){j};
                    end
                    if isempty(stripeData.roiData)
                        continue;
                    end
                    if isempty(channels)
                        channels = stripeData.channelNumbers;
                        numChannels = numel(channels);
                    end
                    
                    roiZ = stripeData.roiData{1}.zs;
                    zRois = {};
                    zAffines = {};
                    zImages = {};
                    
                    for k=1:numel(stripeData.roiData)
                        sf = stripeData.roiData{k}.hRoi.get(roiZ);
                        zRois{end+1} = sf.cornerpoints();
                        zAffines{end+1} = sf.affine;
                        
                        channelImages = cell(numChannels, 1);
                        for iChannel=1:numChannels
                            
                            frames = stripeData.roiData{k}.imageData(iChannel);
                            frames = [frames{:}];
                            averageFrame = cellfun(@(im)average(im),frames,'UniformOutput',false);
                            channelImages{iChannel} = averageFrame{1};
                        end
                        zImages{end+1} = channelImages;
                    end
                    
                    ContextImageProperties.rois{end+1} = zRois;
                    ContextImageProperties.affines{end+1} = zAffines;
                    ContextImageProperties.images{end+1} = zImages;
                end

                ContextImageProperties.zs = obj.zs;

                if isempty(channels)
                    ContextImageProperties = [];
                    return;
                end
                
                ContextImageProperties.channels = arrayfun(@(ch){sprintf('CH%d',ch)},channels);
                if numel(ContextImageProperties.channels) > 1
                    ContextImageProperties.channels{end+1} = 'Merge';
                end
                ContextImageProperties.channelMergeColor = obj.hSI.hChannels.channelMergeColor(channels);
                ContextImageProperties.channelIndex = obj.channelSelIdx;
                
                channelLut = obj.hSI.hChannels.channelLUT(channels);

                ContextImageProperties.luts = channelLut;
                ContextImageProperties.name = 'SS: ';
                ContextImageProperties.sourceName = obj.hSI.hScan2D.name;
                
                function im = average(im)
                    im = (single(im)./obj.rollingAverageFactor);
                end
            end
            
            function ContextImageProperties = fillCameraContextImage()
                imageData = obj.hSelectedCam.lastFrame;
                [xx, yy] = obj.hSelectedCam.getRefCornerPoints();
                ContextImageProperties.name = ['SS: ' obj.hSelectedCam.cameraName];
                ContextImageProperties.sourceName = obj.hSelectedCam.cameraName;
                ContextImageProperties.channels = {obj.hSelectedCam.cameraName};
                ContextImageProperties.channelIndex = 1;
                ContextImageProperties.luts = {obj.hSelectedCam.lut};
                ContextImageProperties.rois = {{[xx(:,1) yy(:,1); xx([2 1], 2) yy([2 1], 2)]}};
                ContextImageProperties.images = {{{imageData}}};
            	ContextImageProperties.zs = obj.zs(1); % should be current z in sample coords
                ContextImageProperties.affines = {{nan}}; % this data is needed for cell picker feature; need to fix
                ContextImageProperties.channelMergeColor = []; % not needed because this ss will not have a merge function
            end
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

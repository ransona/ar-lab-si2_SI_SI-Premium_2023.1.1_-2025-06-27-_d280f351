classdef RoiGroupEditor < most.Gui & most.HasClassDataFile
    properties (Constant)
        EDGE_COLOR_LIST = {[0 1 1] [0.6392 0.2863 0.6431] [.5 .5 1] [0 .5 .5] [.5 .25 0] [.25 0 .25]};
    end

    properties (SetObservable)
        editorZ = 0;
        
        showEditorZ(1,1) logical = true;
        showImagingZs(1,1) logical = true;
        showScannerFov(1,1) logical = true;
        showSelectedRoi(1,1) logical = true;
        showOtherRois(1,1) logical = true;
        showTileView(1,1) logical = false;
        showPowerBoxes(1,1) logical = false;
    end
    
    properties (SetObservable)
        viewMode = '2D';
        
        projectionMode = 'XZ';
        mainViewFov = 30;
        mainViewPosition = [0 0];
        zProjectionRange = [-inf inf];
        units;
        
        editingGroup;
        editorMode = 'imaging';
        
        newRoiDrawMode;
        newRoiDrawModeCache;
        scanfieldResizeMaintainPixelProp;
        newRoiDefaultResolutionMode;
        lockScanfieldWidth = false;
        lockScanfieldHeight = false;
        drawMultipleRois = false;
        drawArray = false;
        
        drawMultipleRoisCache = false;
        
        defaultRoiPositionX = 0;
        defaultRoiPositionY = 0;
        defaultRoiWidth = 5;
        defaultRoiHeight = 5;
        defaultRoiRotation = 0;
        defaultRoiPixelCountX = 512;
        defaultRoiPixelCountY = 512;
        defaultRoiPixelRatioX = 51.2;
        defaultRoiPixelRatioY = 51.2;
        defaultStimFunction = 'logspiral';
        defaultStimFunctionArgs = {'revolutions',5};
        defaultStimDuration = 10;
        defaultStimRepetitions = 1;
        defaultStimPower = 50;
        defaultStimPowerLastAct = 50;
        defaultAnalysisRoiChannel = 1;
        defaultAnalysisRoiThreshold = 100;
        defaultAnalysisRoiProcessor = 'CPU';
        
        defaultWpStimDuration = .1;
        defaultScnStimDuration = 10;
        
        stimQuickAddDuration = 1;
        
        cellPickMode = 'Manual';
        cellPickRoiMargin = 0;
        cellPickCreateAsDiscrete = true;
        cellPickCreateWithMask = true;
        cellPickPauseDuration = 1;
        diskCellPickParams = struct('radiusRange',[3 10],'edgeSign',-1,'postDilateBy',0,'dPosMax',2,'postFracRemove',0,'jitter',[]);
        annularCellPickParams = struct('radiusRange',[2 5],'edgeSign',1,'postDilateBy',2,'dPosMax',2,'postFracRemove',0.35,'jitter',[-2 -2; 0 -2 ; 2 -2; -2 0; 2 0; -2 2; 0 2; 2 2]);
        
        xyMaxVel = 40000;           %deg/sec
        xyMaxAccel = 80000000;         %deg/sec
        zMaxVel = 5000;            %um/sec^s
        zMaxAccel = 5000000;          %um/sec^s
        optimizeTransitions = true;
        optimizeStimuli = false;
        
        stagePos = '[ 0.0   0.0   0.0 ]';
        
        slmPatternType = 'point';
        slmBitmapDisplayTransparency = 0.5;
        
        slmBitmapBrushEnable = false;
        slmBitmapBrushValue = 1;
        slmBitmapBrushSize = 20;
        slmBitmapBrushSoftEdgePct = .5;
        slmPixelMeshBuffer = [];
        
        pbBitmapBrushEnable = false;
        pbBitmapBrushValue = 1;
        pbBitmapBrushSize = 20;
        pbBitmapBrushSoftEdgePct = .5;
        pbCIThreshold = [0 100];
        pbCIValue = [0 1];

        stimpathRenderMaxPoints = 500;
    end
    
    properties (SetAccess = private)
        scannerSet;
        scannersetIsSlm;
        zProjectionDefaultRange;
        zProjectionLimits = [-1 1] * 1e6;
        interestingZs;
        maxInterestingZ;
        minInterestingZ;
    end
    
    properties (Hidden)
        roiTable;
        tblData;
        tblMapping;
        
        canDrawArray = false;
        
        drawData = {{}};
        drawDataProj = {{}};
        pbDat = {{}};
        pbSampleDat = {{}};
        hSelObjHandles = {};
        scanPathCache = [];
        scanPathCacheIds = [];
        
        selectedObj;
        selectedObjParent;
        selectedObjRoiIdx = 0;
        
        selectedPowerBox;
        selectedPowerBoxDisplay;
        hBlankPanel;
        hNewPanel;
        hGlobalImagingSfPropsPanel;
        hImagingRoiPropsPanel;
        hImagingSfPropsPanel;
        hStimRoiPropsPanel;
        hAnalysisRoiPropsPanel;
        hAnalysisSfPropsPanel;
        hNewImagingRoiPanel;
        hNewStimRoiPanel;
        hNewAnalysisRoiPanel;
        hStimOptimizationPanel;
        hStimQuickAddPanel;
        hSlmPropsPanel;
        hSlmPropsPanelCtls;
        hPowerBoxPropsPanel;
        
        hGlobalImagingSfPropsPanelCtls;
        hImagingRoiPropsPanelCtls;
        hImagingSfPropsPanelCtls;
        hStimRoiPropsPanelCtls;
        hAnalysisRoiPropsPanelCtls;
        hAnalysisSfPropsPanelCtls;
        hNewImagingRoiPanelCtls;
        hNewStimRoiPanelCtls;
        hNewAnalysisRoiPanelCtls;
        hStimOptimizationPanelCtls;
        hPowerBoxPropsPanelCtls;
        
        activePanelUpdateFcn;
        
        h2DViewPanel;
        h2DMainViewAxes;
        h2DMainViewOutlineAxes;
        h2DMainViewTickAxes;
        h2DZScrollAxes;
        h2DProjectionViewAxes;
        h2DProjectionViewTickAxes;
        h2DScannerFovSurf;
        h2DScannerFovLines;
        h2DScannerFovHandles;
        h2DScannerFovZeroOrder;
        
        hZPlaneCtl;
        
        h2DScrollPatch;
        h2DScrollKnob;
        h2DScrollLine1;
        h2DScrollLine2;
        hZCursorText;
        hZCursorTextRect;
        
        h3DViewPanel;
        h3DViewAxes;
        h3DViewMouseFindAxes;
        
        hSnapLineX;
        hSnapLineY;
        hSnapLineR;
        
        makeToolBoxColor = most.constants.Colors.green;
        
        h2DImagingPlaneLines;
        h2DFocusPlaneLine;
        h3DImagingPlaneSurfs = matlab.graphics.primitive.Surface.empty;
        n3dip = 0;
        
        
        hRGListeners;
        hRGNameListeners;
        hSIListeners;
        hSSListeners;
        hImageGroupListeners;
        hSlmListeners;
        hSelectedObjectListeners;
        
        xyUnitFactor = 1;
        xyUnitOffset = [0 0];
        fovGridxx = [-.5 .5; -.5 .5];
        fovGridyy = [-.5 -.5; .5 .5];
        
        pbUnitsUM;
        pbUnitsSA;
        tbViewMode2D;
        tbViewMode3D;
        tbProjectionModeXZ;
        tbProjectionModeYZ;
        slLegendScroll;
        pbMoveTop;
        pbMoveUp;
        pbMoveDown;
        pbMoveBottom;
        pbNew;
        pbDel;
        hButtonFlow;
        hCopyButtonFlow;
        hNameFlow;
        etName;
        
        hSlmPatternTypeFlow;
        hSlmBitmapFlow;
        
        hSamplePowerBoxFlow;

        procMap = containers.Map({'cpu' 'fpga'}, {1 2});
        rProcMap = containers.Map({1 2}, {'cpu' 'fpga'});
        stimFcnOptions;
        slmScanOptions;
        stimFcnParamOptions;
        
        nLegendItems = 0;
        legendCols = 0;
        legendTotRows = 0;
        legendMaxTopRow = 1;
        hLegendScrollingPanel;
        hLegendGrid;
        createMode = false;
        editorModeIsStim = false;
        editorModeIsSlm = false;
        editorModeIsImaging = true;
        
        siZs;
        siImRg;
        mainViewFovLim = 30;
        siObjectiveResolution;
        
        
        hContextImages = scanimage.guis.roigroupeditor.ContextImageProvider.empty();
        
        initDone = false;
        
        locks;
        defaultRoiSize;
        projectionDim = 1;
        
        cellPickOn = false;
        cellPickModes = {'Disk cell','Annular cell','Manual'};
        cellPickSurfs = [];
        cellPickSurfsIdMap = {};
        cellPickZs = [];
        cellPickCellsAtZ = {};
        cellPickFunc = [];
        cellPickSelectedCellIdx = [];
        
        showHandles = true;
        enableListeners = true;
        slmPatternTypeIsBitmap = false;

        TileController = scanimage.guis.roigroupeditor.TileController.empty();

        pmPowerBoxMaskEnable;
        etPowerBoxName;
        pmPowerBoxType;
        etPowerBoxPower;
        pmPowerBoxMaskBackground;
        pmPowerBoxLocation;
        pmPowerBoxLocked;
        etPowerBoxMaskResX;
        etPowerBoxMaskResY;
        hPowerBoxMaskImage;
        pmPowerBoxContextImage;
        etPbCIFgThreshold 
        etPbCIFgValue
        etPbCIBgThreshold;
        etPbCIBgValue;
        slPowerBoxContextImageValue;
        slPowerBoxContextImageThreshold;
        cbPowerBoxBrushEnable;
        etPowerBoxBrushValue;
        slPowerBoxBrushValue;        
        etPowerBoxBrushSize;
        slPowerBoxBrushSize;
        pmSelectedPowerBox;
        powerBoxMaskSettingsPanel;
    end
    
    properties (SetObservable)
        slmPatternSfParent;
        slmPatternRoiParent;
        slmPatternRoiGroupParent;
    end
    
    properties
       hPowerBoxDisplayManager;
    end

    %% Lifecycle
    methods
        function obj = RoiGroupEditor(hModel, hController)
            %% main figure
            if nargin < 1
                hModel = [];
            end
            
            if nargin < 2
                hController = [];
            end
            
            obj = obj@most.Gui(hModel, hController, [280 64], 'characters');
            obj.showWaitbarDuringInitalization = true;
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.hContextImages);
            most.idioms.safeDeleteObj(obj.hRGListeners);
            most.idioms.safeDeleteObj(obj.hRGNameListeners);
            most.idioms.safeDeleteObj(obj.hSSListeners);
            most.idioms.safeDeleteObj(obj.hSIListeners);
            most.idioms.safeDeleteObj(obj.hImageGroupListeners);
            most.idioms.safeDeleteObj(obj.hSelectedObjectListeners);
            most.idioms.safeDeleteObj(obj.hPowerBoxDisplayManager);
        end
    end
    
    %% most.GUI
    methods (Access = protected)
        initGui(obj)
    end
    
    %% Prop access
    methods
        function set.editorZ(obj, v)
            v = max(min(obj.zProjectionLimits(2),v),obj.zProjectionLimits(1));
            
            obj.h2DScrollKnob.YData = v;
            obj.h2DScrollLine1.YData = [v v];
            obj.h2DScrollLine2.YData = [v v];
            obj.editorZ = v;
            
            obj.updateScrollPatch();
            
            if isa(obj.selectedObj, 'scanimage.mroi.scanfield.ScanField')
                z = obj.selectedObjParent.zs(obj.selectedObjParent.scanfields == obj.selectedObj);
                if z ~= v
                    if obj.editorModeIsSlm
                        % No-op
                    elseif obj.editorModeIsStim
                        if ~obj.selectedObj.isPause
                            obj.changeSelection([], []);
                        end
                    else
                        obj.changeSelection(obj.selectedObjParent, []);
                    end
                    obj.fixTableCheck();
                end
            end
            
            if isa(obj.selectedObj, 'scanimage.mroi.Roi')
                if ismember(v, obj.selectedObj.zs)
                    str = 'Edit ScanField at Current Z';
                else
                    str = 'Add ScanField at Current Z';
                end
                obj.hAnalysisRoiPropsPanelCtls.pbCreateSf.hCtl.String = str;
                obj.hImagingRoiPropsPanelCtls.pbCreateSf.hCtl.String = str;
            end
            
            obj.updateDisplay();
            obj.cellPickSelectedCellIdx = [];
            set(obj.hZPlaneCtl, 'String', num2str(obj.editorZ));
        end
        
        function set.editingGroup(obj,v)
            if isempty(v)
                v = scanimage.mroi.RoiGroup;
            end
            
            assert(isa(v,'scanimage.mroi.RoiGroup') && most.idioms.isValidObj(v),'Object must be a valid ROI group.');
            obj.editingGroup = v;
            obj.updateScanPathCache();
            
            most.idioms.safeDeleteObj(obj.hRGListeners);
            most.idioms.safeDeleteObj(obj.hImageGroupListeners);
            obj.hRGListeners = most.util.DelayedEventListener(0.5,obj.editingGroup,'changed',@obj.rgChanged);
            
            most.idioms.safeDeleteObj(obj.hRGNameListeners);
            obj.hRGNameListeners = most.ErrorHandler.addCatchingListener(obj.editingGroup, 'name','PostSet',@obj.nameChanged);
            obj.nameChanged();
            
            if obj.siImRg == v
                obj.hImageGroupListeners = most.ErrorHandler.addCatchingListener(obj.hModel.hRoiManager, 'roiGroupMroi','PostSet',@setToNewRg);
            end
            
            obj.setZProjectionLimits();
            
            function setToNewRg(varargin)
                obj.editingGroup = obj.hModel.hRoiManager.roiGroupMroi;
                obj.updateTable();
                obj.updateDisplay();
            end
        end
        
        function set.editorMode(obj,v)
            most.idioms.safeDeleteObj(obj.hSSListeners);
            
            if ~obj.isGuiLoaded
                return;
            end
            switch v
                case 'imaging'
                    set(obj.roiTable, 'ColumnName', {''; 'ID'; 'ROI Name/SF Type'; 'Time (ms)'; 'Enable'; 'Display'; 'Z [um]'});
                    set(obj.roiTable, 'ColumnWidth', { 20 28 120 59 43 45 58 });
                    obj.hNewPanel = obj.hNewImagingRoiPanel;
                    obj.makeToolBoxColor = most.constants.Colors.green;
                    if most.idioms.isValidObj(obj.hModel)
                        obj.hSSListeners = most.ErrorHandler.addCatchingListener(obj.hModel.hScan2D, 'scannerset','PostSet',@obj.ssChange);
                    end
                    obj.showHandles = true;
                    
                    obj.canDrawArray = isa(obj.scannerSet,'scanimage.mroi.scannerset.ResonantGalvoGalvo');
                    obj.hNewImagingRoiPanelCtls.cbDrawArray.Visible = most.gui.OnOff(obj.canDrawArray);
                    
                case 'stimulation'
                    columnNames = {''; 'ID'; 'Stimulus Function'; 'Time (ms)'; 'Reps'; 'Power%'; 'Z [um]'};
                    set(obj.roiTable, 'ColumnName', columnNames);
                    set(obj.roiTable, 'ColumnWidth', { 20 28 120 64 36 60 45 });
                    obj.hNewPanel = obj.hNewStimRoiPanel;
                    obj.makeToolBoxColor = most.constants.Colors.darkGreen;
                    obj.showHandles = isa(obj.scannerSet,'scanimage.mroi.scannerset.GalvoGalvo');
                    obj.canDrawArray = false;
                    
                case 'analysis'
                    set(obj.roiTable, 'ColumnName',{''; 'ID'; 'Analysis Type'; 'Channel'; 'Thresh.'; 'Proc.'; 'Z [um]'});
                    set(obj.roiTable, 'ColumnWidth', { 20 28 120 59 56 45 45 });
                    obj.hNewPanel = obj.hNewAnalysisRoiPanel;
                    obj.makeToolBoxColor = most.constants.Colors.green;
                    if most.idioms.isValidObj(obj.hModel)
                        obj.hSSListeners = most.ErrorHandler.addCatchingListener(obj.hModel.hScan2D, 'scannerset','PostSet',@obj.ssChange);
                    end
                    obj.showHandles = true;
                    obj.canDrawArray = false;
                    
                case 'slm'
                    set(obj.roiTable, 'ColumnName',{''; 'ID'; 'X'; 'Y'; 'Z'; 'Weight Factor'});
                    set(obj.roiTable, 'ColumnWidth', { 20 30 60 60 60 100});
                    if isa(obj.scannerSet,'scanimage.mroi.scannerset.GalvoGalvo')
                        obj.hSlmPropsPanelCtls.pmFunction.String = obj.slmScanOptions;
                        obj.hSlmPropsPanelCtls.pmFunction.Enable = 'on';
                        obj.showHandles = true;
                    else
                        obj.hSlmPropsPanelCtls.pmFunction.String = {'point'};
                        obj.hSlmPropsPanelCtls.pmFunction.Value = 1;
                        obj.hSlmPropsPanelCtls.pmFunction.Enable = 'off';
                        obj.showHandles = false;
                    end
                    obj.canDrawArray = false;
                    
                    %                     obj.hNewPanel = obj.hNewAnalysisRoiPanel;
                    %                     obj.makeToolBoxColor = [0 1 0];
                    %                     if most.idioms.isValidObj(obj.hModel)
                    %                         obj.hSSListener = most.ErrorHandler.addCatchingListener(obj.hModel.hScan2D, 'scannerset','PostSet',@obj.ssChange);
                    %                     end
                    
                otherwise
                    error('Invalid editor mode.');
            end
            obj.hSelObjHandles{1}.MarkerEdgeColor = obj.makeToolBoxColor;
            obj.hSelObjHandles{1}.MarkerFaceColor = obj.makeToolBoxColor * .5;
            obj.hSelObjHandles{2}.Color = obj.makeToolBoxColor;
            obj.hSelObjHandles{3}.MarkerEdgeColor = obj.makeToolBoxColor;
            
            obj.editorMode = v;
            
            obj.hCopyButtonFlow.Visible = most.gui.OnOff(strcmp(obj.editorMode, 'analysis'));
            
            obj.editorModeIsImaging = strcmp(obj.editorMode, 'imaging');
            obj.editorModeIsStim = strcmp(obj.editorMode, 'stimulation');
            obj.editorModeIsSlm = strcmp(obj.editorMode, 'slm');
        end
        
        function set.editorModeIsStim(obj,v)
            hasOptimizationPanel = v && isa(obj.scannerSet,'scanimage.mroi.scannerset.GalvoGalvo');
            obj.hStimOptimizationPanel.Visible = most.gui.OnOff(hasOptimizationPanel);
            obj.hStimQuickAddPanel.Visible = most.gui.OnOff(v);
            
            obj.editorModeIsStim = v;
        end
        
        function set.editorModeIsSlm(obj,v)
            nonSlmControlFlag = most.gui.OnOff(~v);
            obj.hButtonFlow.Visible = nonSlmControlFlag;
            obj.hNameFlow.Visible = nonSlmControlFlag;
            obj.pbMoveBottom.Visible = nonSlmControlFlag;
            obj.pbMoveDown.Visible = nonSlmControlFlag;
            obj.pbMoveUp.Visible = nonSlmControlFlag;
            obj.pbMoveTop.Visible = nonSlmControlFlag;
            
            slmControlFlag = most.gui.OnOff(v);
            obj.hSlmPatternTypeFlow.Visible = slmControlFlag;
            obj.hSlmPropsPanel.Visible = slmControlFlag;
            
            if v
                obj.pbNew.String = 'Add Points...';
            else
                obj.pbNew.String = 'Add ROI...';
                obj.pbNew.Visible = 'on';
                obj.pbDel.Visible = 'on';
                obj.roiTable.Visible = 'on';
                obj.hSlmBitmapFlow.Visible = 'off';
                obj.slmBitmapBrushEnable = false;
            end
            
            obj.editorModeIsSlm = v;
        end
        
        function set.units(obj,v)
            switch lower(v)
                case 'degrees'
                    unitShorthand = 'deg';
                    obj.xyUnitFactor = 1;
                case 'microns'
                    unitShorthand = 'um';
                    obj.xyUnitFactor = obj.siObjectiveResolution;
                otherwise
                    error('Unsupported unit.');
            end

            xLabel = sprintf('X [%s]', unitShorthand);
            yLabel = sprintf('Y [%s]', unitShorthand);
            xlabel(obj.h2DMainViewTickAxes, xLabel);
            ylabel(obj.h2DMainViewTickAxes, yLabel);
            xlabel(obj.h3DViewAxes, xLabel);
            ylabel(obj.h3DViewAxes, yLabel);

            switch obj.projectionMode
                case 'XZ'
                    xTickAxes = 'X';
                case 'YZ'
                    xTickAxes = 'Y';
                otherwise
                    xTickAxes = '?';
            end
            xlabel(obj.h2DProjectionViewTickAxes, sprintf('%s [%s]', xTickAxes, unitShorthand));

            pixelRatioLabelFormat = sprintf('Pixel Ratio [Pix/%s] %%s:', unitShorthand);
            set([obj.hImagingSfPropsPanelCtls.stPixRatioX.hTxt, ...
                obj.hNewImagingRoiPanelCtls.stPixRatioX.hTxt], ...
                'String', sprintf(pixelRatioLabelFormat, 'X'));
            set([obj.hImagingSfPropsPanelCtls.stPixRatioY.hTxt, ...
                obj.hNewImagingRoiPanelCtls.stPixRatioY.hTxt], ...
                'String', sprintf(pixelRatioLabelFormat, 'Y'));
            set([obj.hNewImagingRoiPanelCtls.stMargin.hTxt, ...
                obj.hNewAnalysisRoiPanelCtls.stMargin.hTxt], ...
                'String', sprintf('ROI Margin [%s]', unitShorthand));
            
            obj.units = lower(v);
            obj.updateXYAxes();
            obj.updateDisplay();
            obj.selectedObjChanged();
            obj.updateGlobalPanel();
            
            if obj.editorModeIsSlm
                obj.updateTable();
            end
        end
        
        function set.zProjectionRange(obj, v)
            v(1) = min(max(v(1),obj.zProjectionLimits(1)),obj.zProjectionLimits(2));
            v(2) = min(max(v(2),obj.zProjectionLimits(1)),obj.zProjectionLimits(2));
            
            if diff(v) < 1
                v = [-.5 .5] + sum(v)/2;
            end
            
            obj.zProjectionRange = v;
            
            obj.h2DZScrollAxes.YLim = v;
            obj.h2DProjectionViewAxes.YLim = v;
            
            [~,prefix,exponent] = most.idioms.engineersStyle(max(abs(v))*1e-6,'m');
            obj.h2DProjectionViewTickAxes.YLim = v.*1e-6 ./ 10^exponent;
            ylabel(obj.h2DProjectionViewTickAxes,['Sample Z [' prefix 'm]']);
            
            obj.updateScrollPatch();
        end
        
        function set.mainViewFov(obj,v)
            obj.mainViewFov = max(min(obj.mainViewFovLim,v),2^-8);
            obj.mainViewPosition = obj.mainViewPosition;
        end
        
        function set.mainViewPosition(obj,v)
            mxPos = (obj.mainViewFovLim-obj.mainViewFov)/2;
            obj.mainViewPosition = max(min(v,mxPos),-mxPos);
            obj.updateXYAxes();
        end
        
        function set.viewMode(obj, v)
            obj.deleteDrawData();
            
            switch v
                case '2D'
                    obj.h3DViewPanel.Visible = 'off';
                    obj.h2DViewPanel.Visible = 'on';
                    obj.viewMode = v;
                    set(obj.tbViewMode2D, 'Value', true);
                    set(obj.tbViewMode3D, 'Value', false);
                    obj.updateDisplay();
                    
                case '3D'
                    obj.h2DViewPanel.Visible = 'off';
                    obj.h3DViewPanel.Visible = 'on';
                    obj.viewMode = v;
                    set(obj.tbViewMode3D, 'Value', true);
                    set(obj.tbViewMode2D, 'Value', false);
                    obj.updateDisplay();
                    camtarget(obj.h3DViewAxes,[.5 .5 mean(obj.h3DViewAxes.ZLim)]);
                    view(obj.h3DViewAxes,45,45);
                    
                otherwise
                    error('Unsupported view mode.');
            end
            
            obj.updateXYAxes();
        end
        
        function set.projectionMode(obj, v)
            switch lower(obj.units)
                case 'microns'
                    units_ = ' [um]';
                case 'degrees'
                    units_ = ' [deg]';
                otherwise
                    units_ = '';
            end
            
            switch v
                case 'XZ'
                    obj.projectionMode = v;
                    obj.projectionDim = 1;
                    set(obj.tbProjectionModeXZ, 'Value', true);
                    set(obj.tbProjectionModeYZ, 'Value', false);
                    
                    obj.h2DScannerFovLines(1).XData = min(obj.fovGridxx(:))*ones(1,2);
                    obj.h2DScannerFovLines(2).XData = max(obj.fovGridxx(:))*ones(1,2);
                    
                    xlabel(obj.h2DProjectionViewTickAxes,sprintf('X%s',units_));
                case 'YZ'
                    obj.projectionMode = v;
                    obj.projectionDim = 2;
                    set(obj.tbProjectionModeYZ, 'Value', true);
                    set(obj.tbProjectionModeXZ, 'Value', false);
                    
                    obj.h2DScannerFovLines(1).XData = min(obj.fovGridyy(:))*ones(1,2);
                    obj.h2DScannerFovLines(2).XData = max(obj.fovGridyy(:))*ones(1,2);
                    
                    xlabel(obj.h2DProjectionViewTickAxes,sprintf('Y%s',units_));
                otherwise
                    error('Unsupported projection mode.');
            end
            obj.updateDisplay();
            obj.updateXYAxes();
        end
        
        function set.showEditorZ(obj, v)
            obj.h2DScrollLine2.Visible = most.gui.OnOff(v);
            obj.showEditorZ = v;
        end
        
        function set.showImagingZs(obj, v)
            visibilityFlag = most.gui.OnOff(v);
            set(obj.h2DImagingPlaneLines, 'visible', visibilityFlag);
            set(obj.h2DFocusPlaneLine, 'visible', visibilityFlag);
            set(obj.h3DImagingPlaneSurfs(1:obj.n3dip), 'visible', visibilityFlag);
            
            obj.showImagingZs = v;
        end
        
        function set.showScannerFov(obj, v)
            obj.showScannerFov = v;
            obj.h2DScannerFovSurf.Visible = most.gui.OnOff(v);
            set(obj.h2DScannerFovLines,'Visible', most.gui.OnOff(v));
        end
        
        function set.showSelectedRoi(obj, v)
            obj.showSelectedRoi = v;
            if obj.selectedObjRoiIdx > 0
                cellfun(@(x)set(x,'Visible', most.gui.OnOff(v)), obj.drawData{obj.selectedObjRoiIdx});
                if isa(obj.selectedObj, 'scanimage.mroi.Roi')
                    v = ~isempty(obj.selectedObj.get(obj.editorZ)) && v;
                end
                cellfun(@(x)set(x,'Visible', most.gui.OnOff(v && obj.showHandles)),obj.hSelObjHandles);
                
                if ~isempty(obj.drawDataProj{1})
                    cellfun(@(x)set(x,'Visible', most.gui.OnOff(v)), obj.drawDataProj{obj.selectedObjRoiIdx});
                end
            end
        end
        
        function set.showOtherRois(obj, v)
            obj.showOtherRois = v;
            ids = setdiff(1:numel(obj.drawData),obj.selectedObjRoiIdx);
            if ~isempty(ids)
                cellfun(@(x)set(x,'Visible', most.gui.OnOff(v)), horzcat(obj.drawData{ids}));
                
                if ~isempty(obj.drawDataProj{1})
                    cellfun(@(x)set(x,'Visible', most.gui.OnOff(v)), horzcat(obj.drawDataProj{ids}));
                end
            end
        end

        function set.showTileView(obj, v)
            obj.showTileView = v;
            if v
                obj.TileController.show();
            else
                obj.TileController.hide();
            end
        end

        function set.showPowerBoxes(obj,v)
            obj.showPowerBoxes = v;
            obj.hPowerBoxDisplayManager.setAllVisibility(v);
            obj.updateMaxViewFov();
        end
        
        function set.newRoiDrawMode(obj, v)
            switch v
                case 'top left rectangle'
                    set(obj.hNewImagingRoiPanelCtls.rbTopLeftRect, 'Value', true);
                    set(obj.hNewImagingRoiPanelCtls.rbCenterPtRect, 'Value', false);
                    set(obj.hNewImagingRoiPanelCtls.rbCellPick, 'Value', false);
                    set(obj.hNewImagingRoiPanelCtls.stDraw, 'String', '   Draw new ROI...');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'String', 'Create Using Defaults');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'Enable', 'on');
                    
                    set(obj.hNewStimRoiPanelCtls.rbTopLeftRect, 'Value', true);
                    set(obj.hNewStimRoiPanelCtls.rbCenterPtRect, 'Value', false);
                    set(obj.hNewStimRoiPanelCtls.rbCellPick, 'Value', false);
                    set(obj.hNewStimRoiPanelCtls.stDraw, 'String', '   Draw new ROI...');
                    set(obj.hNewStimRoiPanelCtls.pbCreate, 'String', 'Create Using Defaults');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'Enable', 'on');
                    
                    set(obj.hNewAnalysisRoiPanelCtls.rbTopLeftRect, 'Value', true);
                    set(obj.hNewAnalysisRoiPanelCtls.rbCenterPtRect, 'Value', false);
                    set(obj.hNewAnalysisRoiPanelCtls.rbCellPick, 'Value', false);
                    set(obj.hNewAnalysisRoiPanelCtls.stDraw, 'String', '   Draw new ROI...');
                    set(obj.hNewAnalysisRoiPanelCtls.pbCreate, 'String', 'Create Using Defaults');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'Enable', 'on');
                    
                    
                    set(obj.hNewImagingRoiPanelCtls.cellCtls, 'Visible', 'off');
                    set(obj.hNewImagingRoiPanelCtls.rectCtls, 'Visible', 'on');
                    set(obj.hNewImagingRoiPanelCtls.cbDrawMultiple, 'Visible', 'on');
                    
                    set(obj.hNewStimRoiPanelCtls.cellCtls, 'Visible', 'off');
                    set(obj.hNewStimRoiPanelCtls.rectCtls, 'Visible', 'on');
                    set(obj.hNewStimRoiPanelCtls.cbDrawMultiple, 'Visible', 'on');
                    
                    set(obj.hNewAnalysisRoiPanelCtls.cellCtls, 'Visible', 'off');
                    set(obj.hNewAnalysisRoiPanelCtls.rectCtls, 'Visible', 'on');
                    set(obj.hNewAnalysisRoiPanelCtls.cbDrawMultiple, 'Visible', 'on');
                    
                    obj.cellPickOn = false;
                    obj.endCellPick(false);
                    
                case 'center point rectangle'
                    set(obj.hNewImagingRoiPanelCtls.rbTopLeftRect, 'Value', false);
                    set(obj.hNewImagingRoiPanelCtls.rbCenterPtRect, 'Value', true);
                    set(obj.hNewImagingRoiPanelCtls.rbCellPick, 'Value', false);
                    set(obj.hNewImagingRoiPanelCtls.stDraw, 'String', '   Draw new ROI...');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'String', 'Create Using Defaults');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'Enable', 'on');
                    
                    set(obj.hNewStimRoiPanelCtls.rbTopLeftRect, 'Value', false);
                    set(obj.hNewStimRoiPanelCtls.rbCenterPtRect, 'Value', true);
                    set(obj.hNewStimRoiPanelCtls.rbCellPick, 'Value', false);
                    set(obj.hNewStimRoiPanelCtls.stDraw, 'String', '   Draw new ROI...');
                    set(obj.hNewStimRoiPanelCtls.pbCreate, 'String', 'Create Using Defaults');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'Enable', 'on');
                    
                    set(obj.hNewAnalysisRoiPanelCtls.rbTopLeftRect, 'Value', false);
                    set(obj.hNewAnalysisRoiPanelCtls.rbCenterPtRect, 'Value', true);
                    set(obj.hNewAnalysisRoiPanelCtls.rbCellPick, 'Value', false);
                    set(obj.hNewAnalysisRoiPanelCtls.stDraw, 'String', '   Draw new ROI...');
                    set(obj.hNewAnalysisRoiPanelCtls.pbCreate, 'String', 'Create Using Defaults');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'Enable', 'on');
                    
                    
                    set(obj.hNewImagingRoiPanelCtls.cellCtls, 'Visible', 'off');
                    set(obj.hNewImagingRoiPanelCtls.rectCtls, 'Visible', 'on');
                    set(obj.hNewImagingRoiPanelCtls.cbDrawMultiple, 'Visible', 'on');
                    
                    set(obj.hNewStimRoiPanelCtls.cellCtls, 'Visible', 'off');
                    set(obj.hNewStimRoiPanelCtls.rectCtls, 'Visible', 'on');
                    set(obj.hNewStimRoiPanelCtls.cbDrawMultiple, 'Visible', 'on');
                    
                    set(obj.hNewAnalysisRoiPanelCtls.cellCtls, 'Visible', 'off');
                    set(obj.hNewAnalysisRoiPanelCtls.rectCtls, 'Visible', 'on');
                    set(obj.hNewAnalysisRoiPanelCtls.cbDrawMultiple, 'Visible', 'on');
                    
                    obj.cellPickOn = false;
                    obj.endCellPick(false);
                    
                case 'cell picker'
                    set(obj.hNewImagingRoiPanelCtls.rbTopLeftRect, 'Value', false);
                    set(obj.hNewImagingRoiPanelCtls.rbCenterPtRect, 'Value', false);
                    set(obj.hNewImagingRoiPanelCtls.rbCellPick, 'Value', true);
                    set(obj.hNewImagingRoiPanelCtls.stDraw, 'String', '   Select Cells...');
                    set(obj.hNewImagingRoiPanelCtls.pbCreate, 'String', 'Add Selected Cells');
                    
                    set(obj.hNewStimRoiPanelCtls.rbTopLeftRect, 'Value', false);
                    set(obj.hNewStimRoiPanelCtls.rbCenterPtRect, 'Value', false);
                    set(obj.hNewStimRoiPanelCtls.rbCellPick, 'Value', true);
                    set(obj.hNewStimRoiPanelCtls.stDraw, 'String', '   Select Cells...');
                    set(obj.hNewStimRoiPanelCtls.pbCreate, 'String', 'Add Selected Cells');
                    
                    set(obj.hNewAnalysisRoiPanelCtls.rbTopLeftRect, 'Value', false);
                    set(obj.hNewAnalysisRoiPanelCtls.rbCenterPtRect, 'Value', false);
                    set(obj.hNewAnalysisRoiPanelCtls.rbCellPick, 'Value', true);
                    set(obj.hNewAnalysisRoiPanelCtls.stDraw, 'String', '   Select Cells...');
                    set(obj.hNewAnalysisRoiPanelCtls.pbCreate, 'String', 'Add Selected Cells');
                    
                    
                    set(obj.hNewImagingRoiPanelCtls.rectCtls, 'Visible', 'off');
                    set(obj.hNewImagingRoiPanelCtls.cbDrawMultiple, 'Visible', 'off');
                    set(obj.hNewImagingRoiPanelCtls.cellCtls, 'Visible', 'on');
                    
                    set(obj.hNewStimRoiPanelCtls.rectCtls, 'Visible', 'off');
                    set(obj.hNewStimRoiPanelCtls.cbDrawMultiple, 'Visible', 'off');
                    set(obj.hNewStimRoiPanelCtls.cellCtls, 'Visible', 'on');
                    
                    set(obj.hNewAnalysisRoiPanelCtls.rectCtls, 'Visible', 'off');
                    set(obj.hNewAnalysisRoiPanelCtls.cbDrawMultiple, 'Visible', 'off');
                    set(obj.hNewAnalysisRoiPanelCtls.cellCtls, 'Visible', 'on');
                    
                    obj.cellPickOn = true;
                    
                    if obj.createMode && ~strcmp(obj.newRoiDrawMode, v)
                        obj.startCellPick();
                    end
                    
                otherwise
                    error('Invalid choice.');
            end
            
            if obj.createMode && ~obj.cellPickOn
                obj.h2DMainViewAxes.ButtonDownFcn = @obj.mainCreate;
            else
                obj.h2DMainViewAxes.ButtonDownFcn = @obj.mainPan;
            end
            
            obj.newRoiDrawMode = v;
            
            if (~obj.editorModeIsStim && ~obj.editorModeIsSlm) || (~strcmp(obj.defaultStimFunction,'point') && ~strcmp(obj.defaultStimFunction,'waypoint'))
                obj.newRoiDrawModeCache = v;
            end
        end
        
        function set.scanfieldResizeMaintainPixelProp(obj, v)
            switch v
                case 'count'
                    set(obj.hImagingSfPropsPanelCtls.rbMaintainPixCount, 'Value', true);
                    set(obj.hImagingSfPropsPanelCtls.rbMaintainPixRatio, 'Value', false);
                    
                case 'ratio'
                    set(obj.hImagingSfPropsPanelCtls.rbMaintainPixRatio, 'Value', true);
                    set(obj.hImagingSfPropsPanelCtls.rbMaintainPixCount, 'Value', false);
                    
                otherwise
                    error('Invalid choice.');
            end
            obj.scanfieldResizeMaintainPixelProp = v;
        end
        
        function set.newRoiDefaultResolutionMode(obj, v)
            switch v
                case 'pixel count'
                    set(obj.hNewImagingRoiPanelCtls.rbPixCount, 'Value', true);
                    set(obj.hNewImagingRoiPanelCtls.rbPixRatio, 'Value', false);
                    
                    obj.hNewImagingRoiPanelCtls.pixRatCtls.Visible = 'off';
                    obj.hNewImagingRoiPanelCtls.pixCntCtls.Visible = 'on';
                    
                case 'pixel ratio'
                    set(obj.hNewImagingRoiPanelCtls.rbPixRatio, 'Value', true);
                    set(obj.hNewImagingRoiPanelCtls.rbPixCount, 'Value', false);
                    
                    obj.hNewImagingRoiPanelCtls.pixCntCtls.Visible = 'off';
                    obj.hNewImagingRoiPanelCtls.pixRatCtls.Visible = 'on';
                    
                otherwise
                    error('Invalid choice.');
            end
            obj.newRoiDefaultResolutionMode = v;
        end
        
        function set.defaultRoiPixelCountX(obj,v)
            obj.defaultRoiPixelCountX = v;
            obj.hNewImagingRoiPanelCtls.etPixCountX.hCtl.String = v;
        end
        
        function set.defaultRoiPixelCountY(obj,v)
            obj.defaultRoiPixelCountY = v;
            obj.hNewImagingRoiPanelCtls.etPixCountY.hCtl.String = v;
        end
        
        function set.defaultRoiPixelRatioX(obj,v)
            obj.defaultRoiPixelRatioX = v;
            obj.hNewImagingRoiPanelCtls.etPixRatioX.hCtl.String = v/obj.xyUnitFactor;
        end
        
        function set.defaultRoiPixelRatioY(obj,v)
            obj.defaultRoiPixelRatioY = v;
            obj.hNewImagingRoiPanelCtls.etPixRatioY.hCtl.String = v/obj.xyUnitFactor;
        end
        
        function set.defaultRoiPositionX(obj,v)
            obj.defaultRoiPositionX = v;
            obj.hNewImagingRoiPanelCtls.etCenterX.hCtl.String = v*obj.xyUnitFactor + obj.xyUnitOffset(1);
            obj.hNewStimRoiPanelCtls.etCenterX.hCtl.String = v*obj.xyUnitFactor + obj.xyUnitOffset(1);
            obj.hNewAnalysisRoiPanelCtls.etCenterX.hCtl.String = v*obj.xyUnitFactor + obj.xyUnitOffset(1);
        end
        
        function set.defaultRoiPositionY(obj,v)
            obj.defaultRoiPositionY = v;
            obj.hNewImagingRoiPanelCtls.etCenterY.hCtl.String = v*obj.xyUnitFactor + obj.xyUnitOffset(2);
            obj.hNewStimRoiPanelCtls.etCenterY.hCtl.String = v*obj.xyUnitFactor + obj.xyUnitOffset(2);
            obj.hNewAnalysisRoiPanelCtls.etCenterY.hCtl.String = v*obj.xyUnitFactor + obj.xyUnitOffset(2);
        end
        
        function set.defaultRoiWidth(obj,v)
            obj.defaultRoiWidth = v;
            obj.hNewImagingRoiPanelCtls.etWidth.hCtl.String = v*obj.xyUnitFactor;
            obj.hNewStimRoiPanelCtls.etWidth.hCtl.String = v*obj.xyUnitFactor;
            obj.hNewAnalysisRoiPanelCtls.etWidth.hCtl.String = v*obj.xyUnitFactor;
        end
        
        function set.defaultRoiHeight(obj,v)
            obj.defaultRoiHeight = v;
            obj.hNewImagingRoiPanelCtls.etHeight.hCtl.String = v*obj.xyUnitFactor;
            obj.hNewStimRoiPanelCtls.etHeight.hCtl.String = v*obj.xyUnitFactor;
            obj.hNewAnalysisRoiPanelCtls.etHeight.hCtl.String = v*obj.xyUnitFactor;
        end
        
        function set.cellPickRoiMargin(obj,v)
            obj.cellPickRoiMargin = v;
            obj.hNewImagingRoiPanelCtls.etMargin.hCtl.String = v*obj.xyUnitFactor;
            obj.hNewStimRoiPanelCtls.etMargin.hCtl.String = v*obj.xyUnitFactor;
            obj.hNewAnalysisRoiPanelCtls.etMargin.hCtl.String = v*obj.xyUnitFactor;
        end
        
        function set.defaultRoiRotation(obj,v)
            obj.defaultRoiRotation = v;
            obj.hNewImagingRoiPanelCtls.etRotation.hCtl.String = v;
            obj.hNewStimRoiPanelCtls.etRotation.hCtl.String = v;
            obj.hNewAnalysisRoiPanelCtls.etRotation.hCtl.String = v;
        end
        
        function set.createMode(obj,v)
            if v
                obj.hFig.Pointer = 'crosshair';
                if ~obj.cellPickOn
                    obj.h2DMainViewAxes.ButtonDownFcn = @obj.mainCreate;
                end
            else
                if ~obj.slmBitmapBrushEnable
                    obj.hFig.Pointer = 'arrow';
                end
                obj.h2DMainViewAxes.ButtonDownFcn = @obj.mainPan;
                obj.endCellPick(false);
                
                if strcmp(obj.editorMode,'slm')
                    obj.pbNew.String = 'Add Points...';
                else
                    obj.pbNew.String = 'Add ROI...';
                end
            end
            
            obj.createMode = v;
        end
        
        function v = get.siZs(obj)
            if most.idioms.isValidObj(obj.hModel)
                v = obj.hModel.hStackManager.zs;
            else
                v = 0;
            end
        end
        
        function v = get.siImRg(obj)
            if most.idioms.isValidObj(obj.hModel)
                v = obj.hModel.hRoiManager.roiGroupMroi;
            else
                v = [];
            end
        end
        
        function v = get.siObjectiveResolution(obj)
            if most.idioms.isValidObj(obj.hModel)
                v = obj.hModel.objectiveResolution;
            else
                v = 15;
            end
        end
        
        function set.scannerSet(obj,ss)
            obj.scannerSet = ss;
            
            isgg = isa(ss,'scanimage.mroi.scannerset.GalvoGalvo');
            if isgg
                obj.hNewStimRoiPanelCtls.pmFunction.String = obj.stimFcnOptions;
                obj.hStimRoiPropsPanelCtls.pmFunction.String = obj.hNewStimRoiPanelCtls.pmFunction.String;
                
                if ~ismember(obj.defaultStimFunction, obj.hNewStimRoiPanelCtls.pmFunction.String)
                    obj.defaultStimFunction = 'logspiral';
                end
            elseif obj.editorModeIsStim
                slmOnlyOptions = {'point', 'pause', 'park'};
                obj.hNewStimRoiPanelCtls.pmFunction.String = slmOnlyOptions;
                obj.hStimRoiPropsPanelCtls.pmFunction.String = slmOnlyOptions;
                obj.defaultStimFunction = 'point';
            end
            
            if obj.editorModeIsStim || obj.editorModeIsSlm
                obj.showHandles = isgg;
            end
            
            if ~obj.isGuiLoaded
                return;
            end
            
            obj.updateFovLines();
            obj.updateMaxViewFov();
        end
        
        function v = get.scannersetIsSlm(obj)
            v = ~isempty(obj.scannerSet) && isa(obj.scannerSet,'scanimage.mroi.scannerset.SLM');
        end
        
        function set.cellPickMode(obj, v)
            switch v
                case 'Disk cell'
                    obj.cellPickFunc = @obj.diskCellPickFunc;
                    
                case 'Annular cell'
                    obj.cellPickFunc = @obj.annularCellPickFunc;
                    
                case 'Manual'
                    obj.cellPickFunc = @obj.manualCellPickFunc;
                    
                case 'Custom...'
                    resp = inputdlg('Enter the name of a function on the matlab search path that contains custom cell segmentation ...','Select Custom',1,{'customCellPickFunc'});
                    if isempty(resp)
                        return;
                    end
                    v = resp{1};
                    if isvarname(v)
                        obj.cellPickFunc = str2func(v);
                        obj.cellPickModes{end+1} = v;
                        set([obj.hNewImagingRoiPanelCtls.pmSelMode.hCtl obj.hNewStimRoiPanelCtls.pmSelMode.hCtl obj.hNewAnalysisRoiPanelCtls.pmSelMode.hCtl],'string',{obj.cellPickModes{:},'Custom...'});
                    else
                        fprintf(2,'Invalid function name.\n');
                        return;
                    end
                    
                otherwise
                    assert(isvarname(v),'Invalid function name.');
                    if ~ismember(v,obj.cellPickModes)
                        obj.cellPickModes{end+1} = v;
                        set([obj.hNewImagingRoiPanelCtls.pmSelMode.hCtl obj.hNewStimRoiPanelCtls.pmSelMode.hCtl obj.hNewAnalysisRoiPanelCtls.pmSelMode.hCtl],'string',{obj.cellPickModes{:},'Custom...'});
                    end
                    obj.cellPickFunc = str2func(v);
            end
            obj.cellPickMode = v;
        end
        
        function set.defaultStimDuration(obj, val)
            assert(~isempty(val) && ~isnan(val) && ~isinf(val) && (val > 0), 'Duration must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
            obj.defaultStimDuration = val;
            if strcmp('waypoint', obj.defaultStimFunction)
                obj.defaultWpStimDuration = val;
            else
                obj.defaultScnStimDuration = val;
            end
        end
        
        function set.defaultStimRepetitions(obj, val)
            if ~isempty(val) && ~isnan(val) && ~isinf(val) && (val > 0)
                obj.defaultStimRepetitions = ceil(val);
            else
                most.idioms.warn('Repetitions must be a valid positive integer. NaN and Inf are not allowed. Resetting to previous value.');
            end
        end
        
        function set.defaultStimPower(obj, val)
            if isempty(val) || isnan(val)
                % store the last actual value
                if ~isempty(obj.defaultStimPower)
                    obj.defaultStimPowerLastAct = obj.defaultStimPower;
                end
                obj.defaultStimPower = [];
            elseif isinf(val)
                % restore last actual value
                obj.defaultStimPower = obj.defaultStimPowerLastAct;
            elseif val >= 0 && val <= 100
                obj.defaultStimPower = val;
            else
                most.idioms.warn('Beam Power must be a valid number between 0 and 100. Resetting to previous value.');
            end
        end
        
        function set.stagePos(obj,~)
            if most.idioms.isValidObj(obj.hModel)
                p = obj.hModel.hMotors.samplePosition;
                fmt = ['[ ' strtrim(repmat('%.2f   ',1,numel(p))) ' ]'];
                obj.stagePos = num2str(p,fmt);
            end
        end
        
        function v = get.locks(obj)
            v = logical([obj.lockScanfieldWidth obj.lockScanfieldHeight]);
        end
        
        function v = get.defaultRoiSize(obj)
            v = [obj.defaultRoiWidth obj.defaultRoiHeight];
        end
        
        function set.lockScanfieldWidth(obj, v)
            obj.lockScanfieldWidth = v;
            
            if isa(obj.selectedObj, 'scanimage.mroi.scanfield.ScanField')
                obj.defaultRoiWidth = obj.selectedObj.sizeXY(1);
            end
        end
        
        function set.lockScanfieldHeight(obj, v)
            obj.lockScanfieldHeight = v;
            
            if isa(obj.selectedObj, 'scanimage.mroi.scanfield.ScanField')
                obj.defaultRoiHeight = obj.selectedObj.sizeXY(2);
            end
        end
        
        function set.drawMultipleRois(obj,v)
            obj.drawMultipleRois = v;
            if obj.createMode
                if strcmp(obj.editorMode,'slm') || v
                    obj.pbNew.String = 'Done';
                else
                    obj.pbNew.String = 'Cancel';
                end
            end
            
            if ~obj.editorModeIsStim || ~strcmp('waypoint', obj.defaultStimFunction)
                obj.drawMultipleRoisCache = v;
            end
        end
        
        function set.enableListeners(obj,v)
            if most.idioms.isValidObj(obj.hRGListeners)
                obj.hRGListeners.enabled = v;
            end
            if most.idioms.isValidObj(obj.hSlmListeners)
                obj.hSlmListeners.enabled = v;
            end
            for i = 1:numel(obj.hSelectedObjectListeners)
                if most.idioms.isValidObj(obj.hSelectedObjectListeners(i))
                    obj.hSelectedObjectListeners(i).enabled = v;
                end
            end
        end
        
        function set.stimQuickAddDuration(obj,v)
            if ~isempty(v) && ~isnan(v)
                obj.stimQuickAddDuration = v;
            end
        end
        
        function set.defaultStimFunction(obj,v)
            obj.defaultStimFunction = v;
            obj.hNewStimRoiPanelCtls.etArgs.ParameterOptions = obj.getStimParamOptions(v);
            
            isp = strcmp('point', obj.defaultStimFunction);
            iswp = strcmp('waypoint', obj.defaultStimFunction);
            
            if obj.editorModeIsStim
                if iswp
                    obj.defaultStimDuration = obj.defaultWpStimDuration;
                    obj.drawMultipleRois = true;
                else
                    obj.defaultStimDuration = obj.defaultScnStimDuration;
                    obj.drawMultipleRois = obj.drawMultipleRoisCache;
                end
            else
                obj.drawMultipleRois = obj.drawMultipleRoisCache;
            end
            
            if obj.editorModeIsSlm || (obj.editorModeIsStim && (isp || iswp))
                obj.newRoiDrawMode = 'center point rectangle';
            else
                obj.newRoiDrawMode = obj.newRoiDrawModeCache;
            end
        end
        
        function set.slmPatternType(obj,v)
            if obj.editorModeIsSlm
                
                sf = obj.slmPatternSfParent;
                curpat = sf.slmPattern;
                
                if isempty(v)
                    if isempty(curpat) || size(curpat,2) < 5
                        v = 'point';
                    else
                        v = 'bitmap';
                    end
                end
                
                switch(v)
                    case 'point'
                        if ~isempty(curpat) && (size(curpat,2) > 4) && (sum(curpat(:)) > 0)
                            answ = questdlg('The current bitmap will be cleared. Continue?', 'SLM Pattern Editor', 'Continue', 'Cancel', 'Cancel');
                            if strcmp(answ, 'Continue')
                                curpat = [];
                            else
                                return;
                            end
                        elseif size(curpat,2) == 3
                            curpat(:,4) = 1;
                        elseif size(curpat,2) ~= 4
                            curpat = [];
                        end
                        obj.slmPatternSfParent.slmPattern = curpat;
                        
                        obj.editingGroup = [];
                        sz = sf.sizeXY;
                        for i = 1:size(curpat,1)
                            obj.createRoi(curpat(i,1:2) + sf.centerXY,sz,curpat(i,3),curpat(i,4));
                        end
                        
                        obj.updateTable();
                        bmtf = 'off';
                        nbmtf = 'on';
                        bm = false;
                        
                    case 'bitmap'
                        if ~isempty(curpat) && (size(curpat,2) < 5)
                            answ = questdlg('The current point array will be cleared. Continue?', 'SLM Pattern Editor', 'Continue', 'Cancel', 'Cancel');
                            if strcmp(answ, 'Continue')
                                ss = obj.scannerSet;
                                if isa(ss,'scanimage.mroi.scannerset.GalvoGalvo')
                                    ss = ss.slm;
                                end
                                obj.slmPatternSfParent.slmPattern = zeros(fliplr(ss.scanners{1}.hDevice.pixelResolutionXY));
                            else
                                return;
                            end
                        elseif isempty(obj.slmPatternSfParent.slmPattern)
                            ss = obj.scannerSet;
                            if isa(ss,'scanimage.mroi.scannerset.GalvoGalvo')
                                ss = ss.slm;
                            end
                            obj.slmPatternSfParent.slmPattern = zeros(fliplr(ss.scanners{1}.hDevice.pixelResolutionXY));
                        end
                        
                        obj.editingGroup = [];
                        obj.createRoi(sf.centerXY, sf.sizeXY, 0, 0);
                        
                        bmtf = 'on';
                        nbmtf = 'off';
                        bm = true;
                        
                    otherwise
                        error('Invalid SLM pattern type.');
                end
                
                obj.hSlmBitmapFlow.Visible = bmtf;
                obj.pbNew.Visible = nbmtf;
                obj.pbDel.Visible = nbmtf;
                obj.roiTable.Visible = nbmtf;
                
                obj.slmPatternType = v;
                obj.slmPatternTypeIsBitmap = bm;
                obj.slmBitmapBrushEnable = false;
                
                obj.changeSelection();
            end
        end
        
        function set.slmBitmapDisplayTransparency(obj,v)
            obj.h2DScannerFovSurf.FaceAlpha = v;
            obj.slmBitmapDisplayTransparency = v;
        end
        
        function set.slmBitmapBrushEnable(obj,v)
            if v
                obj.bufferSlmPixelMesh();
                obj.hFig.Pointer = 'crosshair';
                obj.hFig.WindowButtonMotionFcn = @obj.brushHover;
            else
                obj.hFig.Pointer = 'arrow';
                obj.hFig.WindowButtonMotionFcn = [];
            end
            obj.slmBitmapBrushEnable = v;
        end
        
        function set.scanPathCache(obj,v)
            obj.scanPathCache = v;
        end
    end % methods - property access
    
    %% User methods
    methods
        function selectZDialog(obj)
            zStr = num2str(obj.editorZ);
            answer = inputdlg({'Jump to Z position (microns)','OR move ROIs to new Z position'},'Select Z',1,{zStr zStr});
            if ~isempty(answer)
                answer1 = str2double(answer{1});
                answer2 = str2double(answer{2});

                validateattributes(answer1,{'numeric'},{'scalar','nonnan','finite','real'});
                validateattributes(answer2,{'numeric'},{'scalar','nonnan','finite','real'});

                bothChanged = ~isequal(answer1,obj.editorZ) && ~isequal(answer2,obj.editorZ);
                assert(~bothChanged,'Only one of the options can be changed');

                if answer1 ~= obj.editorZ
                    obj.editorZ = answer1;
                elseif answer2 ~= obj.editorZ
                    deltaZ = answer2 - obj.editorZ;
                    obj.editingGroup.addZOffset(deltaZ);
                    obj.editorZ = answer2;
                end
            end
        end

        setEditorGroupAndMode(obj,group,scannerset,mode);
        
        function saveGroup(obj,varargin)
            [filename,pathname] = uiputfile('.roi','Choose filename to save ROI group to',obj.getClassDataVar('lastFile'));
            if 0 == filename
                return;
            end
            filename = fullfile(pathname,filename);
            obj.setClassDataVar('lastFile',filename);
            
            try
                obj.hFig.Pointer = 'watch';
                drawnow();
                obj.editingGroup.saveToFile(filename);
                obj.hFig.Pointer = 'arrow';
            catch ME
                obj.hFig.Pointer = 'arrow';
                ME.rethrow;
            end
        end
        
        loadGroup(obj,varargin);

        function clearGroup(obj,varargin)
            obj.enableListeners = false;
            obj.editingGroup.clear();
            obj.enableListeners = true;
            obj.rgChangedPar();
        end
        
        function copyImagingRois(obj,varargin)
            try
                roigroup = obj.hModel.hRoiManager.currentRoiGroup;
                assert(~isempty(roigroup.rois) && ~isempty(roigroup.rois(1).scanfields), 'Imaging ROI group is empty');
                assert(isa(roigroup.rois(1).scanfields(1), 'scanimage.mroi.scanfield.fields.RotatedRectangle'),...
                    'Only imaging ROIs can be imported for analysis.');
                
                roigroup = obj.convertImagingToIntegrationRois(roigroup);
                
                obj.enableListeners = false;
                obj.editingGroup.copyobj(roigroup);
                obj.enableListeners = true;
                delete(roigroup);
                
                obj.rgChangedPar();
                obj.setZProjectionLimits();
            catch ME
                warndlg(sprintf('Failed to import ROIs. %s', ME.message),'ROI Group Import');
                ME.rethrow;
            end
        end
        
        function newRg = convertImagingToIntegrationRois(obj,imRg)
            newRg = scanimage.mroi.RoiGroup;
            for i = 1:numel(imRg.rois)
                roi = imRg.rois(i);
                N = numel(roi.scanfields);
                if N
                    newRoi = scanimage.mroi.Roi;
                    
                    for j = 1:N
                        newSf = scanimage.mroi.scanfield.fields.IntegrationField();
                        
                        newSf.centerXY = roi.scanfields(j).centerXY;
                        newSf.sizeXY = roi.scanfields(j).sizeXY;
                        newSf.rotationDegrees = roi.scanfields(j).rotationDegrees;
                        newSf.threshold = obj.defaultAnalysisRoiThreshold;
                        newSf.channel = obj.defaultAnalysisRoiChannel;
                        newSf.processor = obj.defaultAnalysisRoiProcessor;
                        
                        newRoi.add(roi.zs(j), newSf);
                    end
                    
                    newRg.add(newRoi);
                end
            end
        end
        
        function resetContextImages(obj)
            delete(obj.hContextImages);
            obj.hContextImages = scanimage.guis.roigroupeditor.LiveContextImage(obj);
            obj.rebuildLegend();
            obj.scrollLegendToBottom();
        end
        
        optimizePath(obj);
    end
    
    %% Internal methods
    methods (Hidden)
        roiTableCB(obj,~,evt);
        
        updateTable(obj);
        
        function fixTableCheck(obj)
            if numel(obj.tblData)
                tf = false;
                
                if most.idioms.isValidObj(obj.selectedObj)
                    [tf, idx] = ismember(obj.selectedObj.uuiduint64, [obj.tblMapping{:,3}]);
                end
                
                if ~tf && most.idioms.isValidObj(obj.selectedObjParent)
                    [tf, idx] = ismember(obj.selectedObjParent.uuiduint64, [obj.tblMapping{:,3}]);
                end
                
                obj.tblData(:,1) = {false};
                if tf
                    obj.tblData{idx,1} = true;
                    
                    %make sure it is in sight
                    tlIdx = obj.tblMapping{idx,2};
                    if tlIdx < obj.roiTable.firstRowIdx
                        obj.roiTable.firstRowIdx = max(1,tlIdx-1);
                    elseif tlIdx >= obj.roiTable.firstRowIdx + obj.roiTable.numVisibleRows
                        obj.roiTable.firstRowIdx = min(obj.roiTable.maxTopRow, tlIdx+numel(obj.tblMapping{tlIdx,1}.zs)+1-obj.roiTable.numVisibleRows);
                    end
                end
                obj.roiTable.Data = obj.tblData;
            end
        end
        
        function remTableRoi(obj, id)
            [tf, tlIdx] = ismember(id, [obj.tblMapping{:,3}]);
            
            if tf
                obj.tblMapping(tlIdx,:) = [];
                obj.tblData(tlIdx,:) = [];
                
                if ~(obj.editorModeIsStim || obj.editorModeIsSlm)
                    linesRemoved = 1;
                    i = tlIdx;
                    while i <= size(obj.tblMapping,1)
                        if obj.tblMapping{i,2} == tlIdx
                            obj.tblMapping(i,:) = [];
                            obj.tblData(i,:) = [];
                            linesRemoved = linesRemoved + 1;
                        else
                            obj.tblMapping{i,2} = obj.tblMapping{i,2} - linesRemoved;
                            i = i+1;
                        end
                    end
                end
                
                obj.roiTable.Data = obj.tblData;
            end
        end
        
        function remTableSf(obj, id)
            [tf, sfIdx] = ismember(id, [obj.tblMapping{:,3}]);
            
            if tf
                obj.tblMapping(sfIdx,:) = [];
                obj.tblData(sfIdx,:) = [];
                
                for i = sfIdx:size(obj.tblMapping,1)
                    if obj.tblMapping{i,2} > sfIdx
                        obj.tblMapping{i,2} = obj.tblMapping{i,2} - 1;
                    end
                end
                
                obj.roiTable.Data = obj.tblData;
            end
        end
        
        function updateDisplay(obj,rois)
            persistent inProg
            persistent req
            
            if ~obj.isGuiLoaded
                return;
            end
            
            if nargin < 2
                rois = inf;
            end

            if isempty(inProg) || ~inProg
                req = rois;

                while ~isempty(req)
                    inProg = true;
                    arg = req;
                    req = [];

                    try
                        if isempty(obj.scanPathCache)
                            obj.refreshScanPath();
                        end

                        if strcmp(obj.viewMode, '3D')
                            obj.draw3D(arg);
                        else
                            obj.draw2D(arg);
                        end
                        inProg = false;
                    catch ME
                        inProg = false;
                        rethrow(ME);
                    end
                end
            else
                req = [req rois];
            end
            
            obj.hPowerBoxDisplayManager.update();
        end
        
        updateScanPathCache(obj,roiIdx);
        
        refreshScanPath(obj);
        
        function [path, waypath] = getStimPts(obj,i,sf)
            if sf.isPoint
                idx = floor(mean(obj.scanPathCacheIds(i,:)));
                path.G = obj.scanPathCache.G(idx,:);
                path.Z = obj.scanPathCache.Z(idx,:);
            else
                path.G = obj.scanPathCache.G(obj.scanPathCacheIds(i,1):obj.scanPathCacheIds(i,2),:);
                path.Z = obj.scanPathCache.Z(obj.scanPathCacheIds(i,1):obj.scanPathCacheIds(i,2),:);
            end
            
            if sf.isWayPoint
                waypath.G = obj.scanPathCache.G(obj.scanPathCacheIds(i,1):obj.scanPathCacheIds(i,2),:);
                waypath.Z = obj.scanPathCache.Z(obj.scanPathCacheIds(i,1):obj.scanPathCacheIds(i,2),:);
            else
                waypath = [];
            end
        end
        
        function remDrawnRoi(obj, id)
            objs = obj.drawData{id};
            obj.drawData(id) = [];
            cellfun(@delete,objs);
            if isempty(obj.drawData)
                obj.drawData = {{}};
            end
            
            if ~isempty(obj.drawDataProj{1})
                objs = obj.drawDataProj{id};
                obj.drawDataProj(id) = [];
                cellfun(@delete,objs);
                if isempty(obj.drawDataProj)
                    obj.drawDataProj = {{}};
                end
            end
        end
        
        changeSelection(obj, selObj, selObjParent);
        
        function updateMoveButtons(obj)
            if obj.editorModeIsStim
                selObj = obj.selectedObjParent;
            else
                selObj = obj.selectedObj;
            end
            
            if isa(selObj,'scanimage.mroi.Roi')
                obj.selectedObjRoiIdx = obj.editingGroup.idToIndex(selObj.uuiduint64);
                
                canMoveUp = 1 < obj.selectedObjRoiIdx;
                set([obj.pbMoveUp, obj.pbMoveTop], 'Enable', most.gui.OnOff(canMoveUp));

                canMoveDown = numel(obj.editingGroup.rois) > obj.selectedObjRoiIdx;
                set([obj.pbMoveDown, obj.pbMoveBottom], 'Enable', most.gui.OnOff(canMoveDown));
            else
                obj.pbMoveBottom.Enable = 'off';
                obj.pbMoveDown.Enable = 'off';
                obj.pbMoveUp.Enable = 'off';
                obj.pbMoveTop.Enable = 'off';
            end
        end
        
        scrollWheelFcn(obj, ~, eventData);
        
        function imagingPlaneLineBDF(obj,varargin)
            if strcmpi(obj.hFig.SelectionType,'extend') && obj.hModel.hStackManager.stackDefinition == scanimage.types.StackDefinition.arbitrary
                pt = get(obj.h2DZScrollAxes,'CurrentPoint');
                ZsMinusPt = abs(pt(1,2) - obj.hModel.hStackManager.arbitraryZs);
                closestZ = min(ZsMinusPt);
                zMask = ZsMinusPt == closestZ;
                obj.hModel.hStackManager.arbitraryZs(zMask) = [];
            else
                obj.zScroll('more','than','2','arguments')
            end
        end

        function zScroll(obj,stop,varargin)
            if nargin > 2
                pt = get(obj.h2DZScrollAxes,'CurrentPoint');
                setZ(pt(1,2));
                set(obj.hFig,...
                    'WindowButtonMotionFcn', @(varargin)obj.zScroll(false),...
                    'WindowButtonUpFcn',@(varargin)obj.zScroll(true));
                waitfor(obj.hFig,'WindowButtonMotionFcn',[]);
                if obj.slmBitmapBrushEnable
                    obj.hFig.WindowButtonMotionFcn = @obj.brushHover;
                end
            elseif stop
                set(obj.hFig, 'WindowButtonMotionFcn', [], 'WindowButtonUpFcn', []);
            else
                pt = get(obj.h2DZScrollAxes,'CurrentPoint');
                setZ(pt(1,2));
            end
            
            function setZ(z)
                % snap to interesting zs
                [dist,i] = min(abs(z-obj.interestingZs));
                if dist < diff(obj.zProjectionRange)/100
                    z = obj.interestingZs(i);
                else
                    z = floor(z*100)/100;
                end
                
                obj.editorZ = z;
            end
        end
        
        function mainPan(obj,stop,varargin)
            persistent ppt;
            persistent pptr;
            persistent mvd;
            
            if nargin > 2
                ppt = most.gui.getPointerLocation(obj.h2DMainViewAxes);
                
                pptr = obj.hFig.Pointer;
                obj.hFig.Pointer = 'fleur';
                mvd = false;
                
                set(obj.hFig,'WindowButtonMotionFcn',@(varargin)obj.mainPan(false),'WindowButtonUpFcn',@(varargin)obj.mainPan(true));
                waitfor(obj.hFig,'WindowButtonMotionFcn',[]);
                if obj.slmBitmapBrushEnable
                    obj.hFig.WindowButtonMotionFcn = @obj.brushHover;
                end
            elseif stop
                set(obj.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
                obj.hFig.Pointer = pptr;
                if ~mvd && ~isempty(obj.selectedObj)
                    % click and release with no drag. deselect
                    obj.changeSelection();
                    obj.fixTableCheck();
                end
            else
                nwpt = most.gui.getPointerLocation(obj.h2DMainViewAxes);
                obj.mainViewPosition = obj.mainViewPosition - nwpt + ppt;
                mvd = true;
                ppt = most.gui.getPointerLocation(obj.h2DMainViewAxes);
            end
        end
        
        mainCreate(obj,stop,varargin);
        
        function zPan(obj, isPanningStopped, varargin)
            persistent PreviousMouseLocation;
            
            CurrentMouseLocation = getCurrentPoint();
            if nargin > 2
                PreviousMouseLocation = CurrentMouseLocation;
                obj.hFig.Pointer = 'fleur';
                set(obj.hFig,...
                    'WindowButtonMotionFcn', @(varargin)obj.zPan(false),...
                    'WindowButtonUpFcn', @(varargin)obj.zPan(true));
                waitfor(obj.hFig,'WindowButtonMotionFcn',[]);
            elseif isPanningStopped
                set(obj.hFig,...
                    'WindowButtonMotionFcn', [],...
                    'WindowButtonUpFcn', []);
                obj.hFig.Pointer = 'arrow';
            else
                obj.zProjectionRange = obj.zProjectionRange...
                    - CurrentMouseLocation.y + PreviousMouseLocation.y;
                obj.mainViewPosition(obj.projectionDim) = obj.mainViewPosition(obj.projectionDim)...
                    - CurrentMouseLocation.x + PreviousMouseLocation.x;
                
                PreviousMouseLocation = getCurrentPoint();
            end
            
            function cp = getCurrentPoint()
                cp = most.gui.getPointerLocation(obj.h2DProjectionViewAxes);
                cp = struct('x', cp(1),'y', cp(2));
            end
        end
        
        function pan3DView(obj,stop,varargin)
            persistent ppt;
            
            if nargin > 2
                ppt = getPt;
                set(obj.hFig,'WindowButtonMotionFcn',@(varargin)obj.pan3DView(false),'WindowButtonUpFcn',@(varargin)obj.pan3DView(true));
                waitfor(obj.hFig,'WindowButtonMotionFcn',[]);
            elseif stop
                set(obj.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
            else
                nwpt = getPt();
                deltaPix = nwpt-ppt;
                
                mod = get(obj.hFig, 'currentModifier');
                if ismember('shift', mod) || strcmp(obj.hFig.SelectionType, 'extend')
                    camorbit(obj.h3DViewAxes,deltaPix(1),-deltaPix(2),'data',[0 0 1]);
                else
                    camdolly(obj.h3DViewAxes,-deltaPix(1),-deltaPix(2),0,'movetarget','pixels');
                end
                ppt = nwpt;
            end
            
            function p = getPt
                pt = hgconvertunits(obj.hFig,[0 0 obj.hFig.CurrentPoint],obj.hFig.Units,'pixels',0);
                p = pt([3,4]);
            end
        end
        
        keyPressFcn(obj,~,evt);
        
        function rgChanged(obj,varargin)
            obj.setZProjectionLimits();
            obj.rgChangedPar();
            obj.hPowerBoxDisplayManager.update();
        end
        
        function rgChangedPar(obj,~)
            % Dev Note: Originally updateScanPathCache was called after
            % updateTable but this resulted in indexing errors when loading
            % a group that had more patterns than the previously loaded
            % group. The reason is because updateTable calls
            % changedSelection which calls updateDisplay which tries to
            % pull path data from the cache for each scan pattern. Since
            % the cache has not yet been updated you will have an indexing
            % error where we try to pull cache data for a pattern that
            % isn't in the cache. For example start a group with 2 patterns
            % and then try to load a group with 4 patterns, since the 2
            % pattern group is what is currently cached you will get an
            % index error when trying to update from the cache for patterns
            % 3 and 4. - JLF
            obj.updateScanPathCache();
            obj.updateTable();
            obj.updateDisplay();
            obj.updateGlobalPanel();
        end
        
        function selectedObjChanged(obj)
            if isa(obj.activePanelUpdateFcn,'function_handle')
                obj.activePanelUpdateFcn();
            end
        end
        
        function newRoi(obj,varargin)
            obj.showPowerBoxes = false;
            if obj.createMode
                obj.changeSelection();
                return;
            end
            
            obj.defaultStimFunction = obj.defaultStimFunction;
            
            if numel(obj.tblData)
                obj.tblData(:,1) = {false};
            end
            
            obj.roiTable.Data = obj.tblData;
            obj.changeSelection();
            obj.hBlankPanel.Visible = 'off';
            obj.hStimOptimizationPanel.Visible = 'off';
            obj.hGlobalImagingSfPropsPanel.Visible = 'off';
            
            if ~obj.editorModeIsSlm
                obj.hNewPanel.Visible = 'on';
                obj.activePanelUpdateFcn = @obj.newRoiPropsPanelUpdate;
                obj.newRoiPropsPanelUpdate();
            end
            
            obj.createMode = true;
            
            if obj.cellPickOn
                obj.startCellPick();
            end
            
            if strcmp(obj.editorMode,'slm') || obj.drawMultipleRois
                obj.pbNew.String = 'Done';
            else
                obj.pbNew.String = 'Cancel';
            end
        end
        
        delSelection(obj,varargin);
        
        p2DViewSize(obj,varargin);
        
        function resizeLegend(obj,varargin)
            if ~obj.initDone
                return;
            end

            obj.hLegendScrollingPanel.Units = 'pixels';
            w = obj.hLegendScrollingPanel.Position(3);
            if w > 448
                obj.legendCols = max(floor(w/224),1);
            else
                obj.legendCols = max(floor(w/180),1);
            end
            nRow = max(1,ceil(obj.nLegendItems/obj.legendCols));

            if nRow ~= obj.legendTotRows
                obj.legendTotRows = nRow;
                if obj.legendTotRows > 3
                    nVisibleRows = 3;
                    obj.legendMaxTopRow = obj.legendTotRows - nVisibleRows + 1;

                    obj.slLegendScroll.hCtl.Min = 1;
                    obj.slLegendScroll.hCtl.Max = obj.legendMaxTopRow;
                    a = nVisibleRows / (obj.legendTotRows - nVisibleRows);
                    obj.slLegendScroll.hCtl.SliderStep = [1/(obj.legendMaxTopRow-1) a];
                    obj.slLegendScroll.hCtl.Value = obj.legendMaxTopRow;
                    obj.slLegendScroll.hCtl.Enable = 'on';
                else
                    obj.slLegendScroll.hCtl.Min = 1;
                    obj.slLegendScroll.hCtl.Value = 1;
                    obj.slLegendScroll.hCtl.Enable = 'off';
                    obj.legendScrl();
                end
            end

            obj.hLegendGrid.Units = 'pixels';
            obj.hLegendGrid.Position([3 4]) = [w 33*obj.legendTotRows];
            set(obj.hLegendGrid,'GridSize',[obj.legendTotRows obj.legendCols]);
        end
        
        function legendScrl(obj,varargin)
            if obj.initDone
                %                 obj.hLegendScrollingPanel.Units = 'pixels';
                %                 H = obj.hLegendScrollingPanel.Position;
                H = 99; % this should not change
                
                v = (obj.slLegendScroll.hCtl.Value-1) * 33;
                obj.hLegendGrid.Units = 'pixels';
                obj.hLegendGrid.Position(2) = H - min(3,obj.legendTotRows)*33 - v;
            end
        end
        
        function scrollLegendToBottom(obj)
            obj.slLegendScroll.hCtl.Value = obj.slLegendScroll.hCtl.Min;
        end
        
        rebuildLegend(obj);

        updateFovLines(obj);
        
        function updateMaxViewFov(obj)
            m = max([max(abs(obj.fovGridxx(:))); max(abs(obj.fovGridyy(:)));]);
            if obj.editorModeIsSlm && isa(obj.scannerSet,'scanimage.mroi.scannerset.GalvoGalvo')
                cornerPoints = obj.scannerSet.fovCornerPoints();
                m = max([m; cornerPoints(:)]);
            end

            m = max(m, maxCellData([obj.hContextImages(:).roiCPs]));

            if obj.showTileView
                tileCornerPoints = obj.TileController.getCornerPoints();
                m = max([m; abs(tileCornerPoints(:))]);
            end
            
            if obj.showPowerBoxes
                powerBoxDisplays = obj.hPowerBoxDisplayManager.powerBoxDisplays;
                powerBoxCornerPoints = arrayfun(@(pbd)abs(pbd.cornerPts),powerBoxDisplays,'UniformOutput',false);
                m = max(m,maxCellData(powerBoxCornerPoints));
            end

            obj.mainViewFovLim = 2.2*m;
            obj.mainViewFov = obj.mainViewFov;

            function md = maxCellData(c)
                if isempty(c)
                    md = 0;
                elseif iscell(c)
                    md = max(cellfun(@maxCellData,c));
                else
                    md = max(c(:));
                end
            end
        end
        
        function updateXYAxes(obj)
            axesAspectRatio = obj.h2DMainViewAxes.PlotBoxAspectRatio(1:2);
            normalAspectRatio = axesAspectRatio / min(axesAspectRatio);
            fov = normalAspectRatio * obj.mainViewFov;
            limits = obj.mainViewPosition + (fov .* [-1; 1]) / 2;
            limits = limits .';
            % limits now is a square matrix where:
            %    [xmin, xmax;
            %     ymin, ymax;]
            tickLimits = limits * obj.xyUnitFactor + obj.xyUnitOffset;
            set(obj.h2DMainViewAxes, 'XLim', limits(1,:), 'YLim', limits(2,:));
            set(obj.h2DMainViewTickAxes, 'XLim', tickLimits(1,:), 'YLim', tickLimits(2,:));
            set([obj.h2DProjectionViewAxes, obj.h2DProjectionViewTickAxes], 'XLim', limits(obj.projectionDim,:));
        end
        
        function deleteDrawData(obj)
            cellfun(@delete, horzcat(obj.drawData{:}));
            obj.drawData = repmat({{}},1,numel(obj.editingGroup.rois)+1);
            
            cellfun(@delete, horzcat(obj.drawDataProj{:}));
            obj.drawDataProj = repmat({{}},1,numel(obj.editingGroup.rois)+1);
        end
        
        draw2D(obj, rois);
        
        function roiHit(obj,src,~)
            if obj.createMode && obj.cellPickOn
                return;
            end

            if strcmpi(obj.hSamplePowerBoxFlow.Visible, 'on')
                obj.finishPowerBoxEdit();
            end
            
            idx = obj.editingGroup.idToIndex(src.UserData);
            if idx > 0
                roi = obj.editingGroup.rois(idx);
                
                if idx ~= obj.selectedObjRoiIdx
                    if numel(roi.scanfields) > 0
                        if ismember(obj.editorZ, roi.zs)
                            obj.changeSelection(roi.get(obj.editorZ),roi);
                        else
                            obj.changeSelection(roi,[]);
                        end
                    else
                        obj.changeSelection(roi,[]);
                    end
                    obj.fixTableCheck();
                end
                
                % was already selected. this is a drag
                if strcmp(obj.viewMode, '2D')
                    obj.roiManip(struct('UserData','move'),nan);
                end
            end
        end

        roiManip(obj,stop,varargin);
        
        function roiProjPatchHit(obj,src,~)
            idx = obj.editingGroup.idToIndex(src.UserData);
            if idx > 0
                roi = obj.editingGroup.rois(idx);
                
                if idx ~= obj.selectedObjRoiIdx
                    if numel(roi.scanfields) > 0
                        if (obj.editorModeIsStim || obj.editorModeIsSlm)
                            sf = roi.scanfields(1);
                            obj.changeSelection(roi,sf);
                        else
                            if ismember(obj.editorZ, roi.zs)
                                obj.changeSelection(roi.get(obj.editorZ),roi);
                            else
                                obj.changeSelection(roi,[]);
                            end
                        end
                    else
                        obj.changeSelection(roi,[]);
                    end
                    obj.fixTableCheck();
                end
            end
        end
        
        function roiProjLineHit(obj,src,evt)
            idx = obj.editingGroup.idToIndex(src.UserData);
            if idx > 0
                roi = obj.editingGroup.rois(idx);
                z = evt.IntersectionPoint(2);
                diff = abs(z - roi.zs);
                [~,i] = min(diff);
                sf = roi.scanfields(i);
                
                if isempty(obj.selectedObj) || (sf ~= obj.selectedObj)
                    obj.changeSelection(sf,roi);
                    obj.fixTableCheck();
                else
                    % already selected. this is a drag
                    obj.sfDrag();
                end
            end
        end

        function slmPointProjHit(obj,src,evt)
            idx = obj.editingGroup.idToIndex(src.UserData);
            if idx > 0
                roi = obj.editingGroup.rois(idx);
                pt = evt.IntersectionPoint;
                z = pt(2);
                diff = abs(z - roi.zs);
                [~,i] = min(diff);
                sf = roi.scanfields(i);

                if isempty(obj.selectedObj) || (sf ~= obj.selectedObj)
                    obj.changeSelection(sf,roi);
                    obj.fixTableCheck();
                else
                    % already selected. this is a drag
                    obj.slmPointDrag(pt);
                end
            end
        end
        
        sfDrag(obj,stop);

        slmPointDrag(obj,z,stop);
        
        fovSurfHit(obj,src,evt);
        
        function bufferSlmPixelMesh(obj)
            ss = obj.scannerSet;
            if isa(ss,'scanimage.mroi.scannerset.GalvoGalvo')
                ss = ss.slm;
            end
            
            z_ref = scanimage.mroi.coordinates.Points(ss.hCSReference,[0,0,0]);
            z_ref = z_ref.transform(ss.scanners{1}.hCoordinateSystem);
            z_slm = z_ref.points(3);
            
            res = ss.scanners{1}.hDevice.pixelResolutionXY;
            [xx_mesh,yy_mesh,zz_mesh] = meshgrid(1:res(1),1:res(2),z_slm);
            mesh = [xx_mesh(:),yy_mesh(:),zz_mesh(:)];
            mesh = scanimage.mroi.coordinates.Points(ss.scanners{1}.hCSPixel,mesh);
            mesh = mesh.transform(obj.scannerSet.hCSReference);
            mesh = mesh.points(:,1:2);
            
            obj.slmPixelMeshBuffer.mesh = mesh;
            obj.slmPixelMeshBuffer.boundsx = [min(mesh(:,1)) max(mesh(:,1))];
            obj.slmPixelMeshBuffer.boundsy = [min(mesh(:,2)) max(mesh(:,2))];
            obj.slmPixelMeshBuffer.needsBsxfun = verLessThan('matlab','9.1.0'); %implicit expansion is supported starting Matlab 2016b
        end
        
        function [inds, rs] = findBrushAffectedInds(obj,pt)
            ss = obj.scannerSet;
            if isa(ss,'scanimage.mroi.scannerset.GalvoGalvo')
                ss = ss.slm;
            end
            
            % determine brush size in reference space
            pts = [0                      0 0
                obj.slmBitmapBrushSize 0 0];
            pts = scanimage.mroi.coordinates.Points(ss.scanners{1}.hCSPixel,pts);
            pts = pts.transform(obj.scannerSet.hCSReference);
            pts = pts.points;
            brushSize = norm(pts(1,:)-pts(2,:));
            
            outOfBounds = (pt(1)+brushSize/2)<obj.slmPixelMeshBuffer.boundsx(1) || (pt(1)-brushSize/2)>obj.slmPixelMeshBuffer.boundsx(2) || ...
                (pt(2)+brushSize/2)<obj.slmPixelMeshBuffer.boundsy(1) || (pt(2)-brushSize/2)>obj.slmPixelMeshBuffer.boundsy(2);
            
            if outOfBounds
                inds = [];
                rs = [];
                return
            end
            
            if obj.slmPixelMeshBuffer.needsBsxfun
                mesh_pt = bsxfun(@minus,obj.slmPixelMeshBuffer.mesh,pt);
            else
                mesh_pt = obj.slmPixelMeshBuffer.mesh - pt;
            end
            
            mesh_pt = mesh_pt.^2;
            rs_squared = sum(mesh_pt,2);
            
            inds = find(rs_squared<brushSize^2);
            rs = sqrt(rs_squared(inds))/brushSize;
        end
        
        function brushHover(obj,varargin)
            ocdat = obj.h2DScannerFovSurf.CData;
            
            % reset and cache the green mask
            gm = ocdat(:,:,3);
            rm = zeros(size(gm),'uint8');
            
            % find the hover point
            cp = obj.h2DMainViewAxes.CurrentPoint(1,1:2) - obj.slmPatternSfParent.centerXY;
            
            % find affected points
            [ptinds, rs] = findBrushAffectedInds(obj,cp);
            
            % determine value with soft edge
            sep = obj.slmBitmapBrushSoftEdgePct;
            ovws = min(1,max(0,(sep - (1-rs)) / sep)); % old val weights
            gvs = (1-ovws) + ovws.*double(gm(ptinds))/255;
            rvs = (1-ovws) + ovws.*double(rm(ptinds))/255;
            
            % update maps
            rm(ptinds) = uint8(255*rvs);
            rm = min(rm,gm); % this makes brush tool green to white instead of yellow to white
            gm(ptinds) = uint8(255*gvs);
            
            ocdat(:,:,1) = rm;
            ocdat(:,:,2) = gm;
            obj.h2DScannerFovSurf.CData = ocdat;
        end
        
        draw3D(obj,rois);
        
        function updateZs(obj, varargin)
            zs = obj.siZs;
            
            obj.n3dip = min(numel(zs),500);
            Ns = numel(obj.h3DImagingPlaneSurfs);
            for i = 1:obj.n3dip
                if i > Ns
                    obj.h3DImagingPlaneSurfs(end+1) = surface(obj.h3DViewAxes.XLim,obj.h3DViewAxes.YLim,ones(2),'FaceColor','w','facealpha',.1,'edgecolor','w','linewidth',1,'parent',obj.h3DViewAxes,'hittest','off','PickableParts','none');
                end
                obj.h3DImagingPlaneSurfs(i).ZData = zs(i)*ones(2);
            end
            set(obj.h3DImagingPlaneSurfs(1:obj.n3dip),'Visible', most.gui.OnOff(obj.showImagingZs));
            set(obj.h3DImagingPlaneSurfs(obj.n3dip+1:end),'Visible','off');
            
            yd = [zs;zs;nan(1,numel(zs))];
            obj.h2DImagingPlaneLines.XData = repmat([-999999 999999 nan],1,numel(zs));
            obj.h2DImagingPlaneLines.YData = yd(:)';
            
            obj.setZProjectionLimits();
        end
        
        function updateFocalPointZ(obj, varargin)
            hPtFocus = scanimage.mroi.coordinates.Points(obj.hModel.hCoordinateSystems.hCSFocus,[0,0,0]);
            hPtFocusRef = hPtFocus.transform(obj.hModel.hCoordinateSystems.hCSSampleRelative);
            
            focusRefZ = hPtFocusRef.points(1,3);
                
            obj.h2DFocusPlaneLine.XData = [-999999 999999 nan];
            obj.h2DFocusPlaneLine.YData = [focusRefZ focusRefZ nan];
        end
        
        function setZProjectionLimits(obj)
            obj.interestingZs = unique([...
                obj.siZs, ...
                obj.editingGroup.zs, ...
                obj.hContextImages.zs, ...
                obj.TileController.getZs()]);
            obj.maxInterestingZ = max(obj.interestingZs);
            obj.minInterestingZ = min(obj.interestingZs);
            
            mddl = (obj.maxInterestingZ + obj.minInterestingZ) / 2;
            rg = max(obj.maxInterestingZ - obj.minInterestingZ, 20);
            
            obj.zProjectionDefaultRange = mddl + [-1 1] * rg * 0.6;
            
            defaultMaxLimit = 1e6; % 1 meter
            maxLimit = max([ abs(obj.interestingZs(:)') defaultMaxLimit ]);
            obj.zProjectionLimits = maxLimit * [-1 1];
            
            obj.zProjectionRange = obj.zProjectionRange;
            
            if obj.editorZ < obj.zProjectionLimits(1) || obj.editorZ > obj.zProjectionLimits(2)
                obj.editorZ = obj.editorZ;
            end
        end
        
        function chgName(obj,varargin)
            if most.idioms.isValidObj(obj.editingGroup)
                obj.editingGroup.name = obj.etName.String;
            else
                obj.etName.String = '';
            end
        end
        
        function op = getStimParamOptions(obj,n)
            if isfield(obj.stimFcnParamOptions,n)
                op = obj.stimFcnParamOptions.(n);
            else
                op = {};
            end
        end
        
        function nameChanged(obj,varargin)
            obj.etName.String = obj.editingGroup.name_;
        end
        
        function moveButton(obj,ammt)
            if obj.editorModeIsStim
                selObj = obj.selectedObjParent;
            else
                selObj = obj.selectedObj;
            end
            
            obj.enableListeners = false;
            obj.editingGroup.moveById(selObj.uuiduint64,ammt);
            obj.enableListeners = true;
            obj.updateScanPathCache();
            obj.updateTable();
            obj.updateMoveButtons();
            obj.updateDisplay();
        end
        
        function roiPropsPanelUpdate(obj)
            obj.hImagingRoiPropsPanelCtls.etName.hCtl.String = obj.selectedObj.name_;
            obj.hImagingRoiPropsPanelCtls.etUUID.hCtl.String = obj.selectedObj.uuid;
            obj.hImagingRoiPropsPanelCtls.cbEnable.hCtl.Value = obj.selectedObj.enable;
            obj.hImagingRoiPropsPanelCtls.cbDisplay.hCtl.Value = obj.selectedObj.display;
            obj.hImagingRoiPropsPanelCtls.cbDiscrete.hCtl.Value = obj.selectedObj.discretePlaneMode;
            obj.hImagingRoiPropsPanelCtls.etCPs.hCtl.String = numel(obj.selectedObj.zs);
            
            if obj.selectedObj.discretePlaneMode || (numel(obj.selectedObj.zs) > 1)
                obj.hImagingRoiPropsPanelCtls.etZmin.hCtl.String = min(obj.selectedObj.zs);
                obj.hImagingRoiPropsPanelCtls.etZmax.hCtl.String = max(obj.selectedObj.zs);
            else
                obj.hImagingRoiPropsPanelCtls.etZmin.hCtl.String = '-inf';
                obj.hImagingRoiPropsPanelCtls.etZmax.hCtl.String = 'inf';
            end
            
            if isempty(obj.selectedObj.powers)
                obj.hImagingRoiPropsPanelCtls.etPowers.hCtl.String = '[default]';
            else
                obj.hImagingRoiPropsPanelCtls.etPowers.hCtl.String = num2str(obj.selectedObj.powers);
            end
            
            if isempty(obj.selectedObj.pzAdjust)
                obj.hImagingRoiPropsPanelCtls.etPZ.hCtl.String = '[default]';
            else
                obj.hImagingRoiPropsPanelCtls.etPZ.hCtl.String = num2str(obj.selectedObj.pzAdjust);
            end
            
            if isempty(obj.selectedObj.Lzs)
                obj.hImagingRoiPropsPanelCtls.etLzs.hCtl.String = '[default]';
            else
                obj.hImagingRoiPropsPanelCtls.etLzs.hCtl.String = num2str(obj.selectedObj.Lzs);
            end
        end
        
        roiPropsPanelCtlCb(obj,src,~);

        stimRoiPropsPanelUpdate(obj);
        
        stimRoiPropsPanelCtlCb(obj,src,~);
        
        function editSlmPattern(obj,varargin)
            obj.slmPatternRoiGroupParent = obj.editingGroup;
            obj.setEditorGroupAndMode(obj.selectedObjParent,obj.scannerSet,'slm');
        end
        
        function editOrClearSlmPattern(obj,varargin)
            if isempty(obj.selectedObj.slmPattern)
                if isempty(obj.selectedObj.slmPattern)
                    % converting to an SLM pattern. Figure out best
                    % place to point galvos taking zero order beam
                    % block and slm fov into account
                    r = obj.scannerSet.slm.zeroOrderBlockRadius;
                    if r
                        % deflect y just outside zero order beam block
                        y  = - r * obj.scannerSet.slm.scannerToRefTransform(5) * 2;
                    else
                        % no zero order beam block. point galvos
                        % directly at spot and make slm pattern zero
                        y = 0;
                    end
                    obj.selectedObj.slmPattern = [0 y obj.selectedObjParent.zs(1) 1];
                    obj.selectedObj.centerXY = obj.selectedObj.centerXY - [0 y];
                end
                obj.editSlmPattern;
            else
                obj.selectedObj.slmPattern = [];
            end
        end
        
        function updateSlmPattern(obj)
            if ~obj.slmPatternTypeIsBitmap
                pat = zeros(numel(obj.editingGroup.rois),4);
                sfCenterXY = obj.slmPatternSfParent.centerXY;
                for i = 1:numel(obj.editingGroup.rois)
                    pat(i,:) = [obj.editingGroup.rois(i).scanfields(1).centerXY - sfCenterXY obj.editingGroup.rois(i).zs(1) obj.editingGroup.rois(i).scanfields(1).powers];
                end
                obj.slmPatternSfParent.slmPattern = pat;
            end
        end
        
        function finishSlmEdit(obj,varargin)
            obj.updateSlmPattern();
            
            obj.setEditorGroupAndMode(obj.slmPatternRoiGroupParent,obj.scannerSet,'stimulation');
            obj.changeSelection(obj.slmPatternSfParent,obj.slmPatternRoiParent);
            obj.fixTableCheck();
        end

        openPowerBoxSettingsPane(obj, hPowerBox, hPowerBoxDisplay);

        redrawPowerBoxPane(obj);

        finishPowerBoxEdit(obj, varargin);
        
        function analysisRoiPropsPanelUpdate(obj)
            obj.hAnalysisRoiPropsPanelCtls.etName.hCtl.String = obj.selectedObj.name_;
            obj.hAnalysisRoiPropsPanelCtls.etUUID.hCtl.String = obj.selectedObj.uuid;
            obj.hAnalysisRoiPropsPanelCtls.cbEnable.hCtl.Value = obj.selectedObj.enable;
            obj.hAnalysisRoiPropsPanelCtls.cbDisplay.hCtl.Value = obj.selectedObj.display;
            obj.hAnalysisRoiPropsPanelCtls.cbDiscrete.hCtl.Value = obj.selectedObj.discretePlaneMode;
            obj.hAnalysisRoiPropsPanelCtls.etCPs.hCtl.String = numel(obj.selectedObj.zs);
            
            obj.hAnalysisRoiPropsPanelCtls.etZmin.hCtl.String = min(obj.selectedObj.zs);
            obj.hAnalysisRoiPropsPanelCtls.etZmax.hCtl.String = max(obj.selectedObj.zs);
            
            if numel(obj.selectedObj.scanfields)
                obj.hAnalysisRoiPropsPanelCtls.pmChannel.hCtl.Value = obj.selectedObj.scanfields(1).channel;
                obj.hAnalysisRoiPropsPanelCtls.etThreshold.hCtl.String = obj.selectedObj.scanfields(1).threshold;
                obj.hAnalysisRoiPropsPanelCtls.pmProcessor.hCtl.Value = obj.procMap(lower(obj.selectedObj.scanfields(1).processor));
            end
        end
        
        analysisRoiPropsPanelCtlCb(obj,src,~);
        
        function analysisSfPropsPanelUpdate(obj)
            obj.hAnalysisSfPropsPanelCtls.etZ.hCtl.String = obj.selectedObjParent.zs(obj.selectedObjParent.scanfields == obj.selectedObj);
            obj.hAnalysisSfPropsPanelCtls.etCenterX.hCtl.String = obj.selectedObj.centerXY(1) * obj.xyUnitFactor + obj.xyUnitOffset(1);
            obj.hAnalysisSfPropsPanelCtls.etCenterY.hCtl.String = obj.selectedObj.centerXY(2) * obj.xyUnitFactor + obj.xyUnitOffset(2);
            obj.hAnalysisSfPropsPanelCtls.etWidth.hCtl.String = obj.selectedObj.sizeXY(1) * obj.xyUnitFactor;
            obj.hAnalysisSfPropsPanelCtls.etHeight.hCtl.String = obj.selectedObj.sizeXY(2) * obj.xyUnitFactor;
            obj.hAnalysisSfPropsPanelCtls.etRotation.hCtl.String = obj.selectedObj.rotationDegrees; % obj.selectedObj.rotation;
            
            if numel(obj.selectedObj.mask) <= 100
                str = mat2str(obj.selectedObj.mask,5);
            else
                str = '<Matrix too large for display>';
            end
            
            obj.hAnalysisSfPropsPanelCtls.etMask.hCtl.String = str;
        end
        
        analysisSfPropsPanelCtlCb(obj,src,~);
        
        function imagingSfPropsPanelUpdate(obj)
            obj.hImagingSfPropsPanelCtls.etZ.hCtl.String = obj.selectedObjParent.zs(obj.selectedObjParent.scanfields == obj.selectedObj);
            obj.hImagingSfPropsPanelCtls.etCenterX.hCtl.String = obj.selectedObj.centerXY(1) * obj.xyUnitFactor + obj.xyUnitOffset(1);
            obj.hImagingSfPropsPanelCtls.etCenterY.hCtl.String = obj.selectedObj.centerXY(2) * obj.xyUnitFactor + obj.xyUnitOffset(2);
            obj.hImagingSfPropsPanelCtls.etWidth.hCtl.String = obj.selectedObj.sizeXY(1) * obj.xyUnitFactor;
            obj.hImagingSfPropsPanelCtls.etHeight.hCtl.String = obj.selectedObj.sizeXY(2) * obj.xyUnitFactor;
            obj.hImagingSfPropsPanelCtls.etRotation.hCtl.String = obj.selectedObj.degrees;
            obj.hImagingSfPropsPanelCtls.etPixCountX.hCtl.String = obj.selectedObj.pixelResolution(1);
            obj.hImagingSfPropsPanelCtls.etPixCountY.hCtl.String = obj.selectedObj.pixelResolution(2);
            obj.hImagingSfPropsPanelCtls.etPixRatioX.hCtl.String = obj.selectedObj.pixelRatio(1) / obj.xyUnitFactor;
            obj.hImagingSfPropsPanelCtls.etPixRatioY.hCtl.String = obj.selectedObj.pixelRatio(2) / obj.xyUnitFactor;
        end
        
        imSfPropsPanelCtlCb(obj,src,~);
        
        function newRoiPropsPanelUpdate(obj)
            obj.defaultRoiPositionX = obj.defaultRoiPositionX;
            obj.defaultRoiPositionY = obj.defaultRoiPositionY;
            
            obj.defaultRoiWidth = obj.defaultRoiWidth;
            obj.defaultRoiHeight = obj.defaultRoiHeight;
            
            obj.defaultRoiPixelRatioX = obj.defaultRoiPixelRatioX;
            obj.defaultRoiPixelRatioY = obj.defaultRoiPixelRatioY;
            
            obj.cellPickRoiMargin = obj.cellPickRoiMargin;
            
            obj.defaultRoiRotation = obj.defaultRoiRotation;
            
            obj.defaultRoiPixelCountX = obj.defaultRoiPixelCountX;
            obj.defaultRoiPixelCountY = obj.defaultRoiPixelCountY;
        end
        
        newRoiPropsPanelCtlCb(obj,src,~);

        function slmPropsPanelUpdate(obj)
            sf = obj.slmPatternSfParent;
            
            if isa(obj.scannerSet,'scanimage.mroi.scannerset.GalvoGalvo')
                slmScanFunction = regexpi(func2str(sf.stimfcnhdl),'[^\.]*$','match');
                [~,obj.hSlmPropsPanelCtls.pmFunction.hCtl.Value] = ismember(slmScanFunction,obj.slmScanOptions);
                obj.showHandles = ~strcmp(slmScanFunction,'point');
                
                obj.hSlmPropsPanelCtls.etArgs.ParameterOptions = obj.getStimParamOptions(slmScanFunction{1});
            end
            
            obj.hSlmPropsPanelCtls.etArgs.Value = sf.stimparams;
            
            obj.hSlmPropsPanelCtls.etDuration.hCtl.String = sf.duration*1000;
            obj.hSlmPropsPanelCtls.etReps.hCtl.String = sf.repetitions;
            obj.hSlmPropsPanelCtls.etWidth.hCtl.String = sf.sizeXY(1) * obj.xyUnitFactor;
            obj.hSlmPropsPanelCtls.etHeight.hCtl.String = sf.sizeXY(2) * obj.xyUnitFactor;
            obj.hSlmPropsPanelCtls.etRotation.hCtl.String = sf.rotation;
            obj.hSlmPropsPanelCtls.etPower.hCtl.String = sf.powers;
            
            if obj.slmPatternTypeIsBitmap
                mn = min(sf.slmPattern(:));
                mx = max(sf.slmPattern(:));
                cdat = repmat(uint8(255 * (sf.slmPattern - mn) / (mx - mn)),1,1,3);
                cdat(:,:,1) = 0;
                obj.h2DScannerFovSurf.CData = cdat;
            else
                obj.enableListeners = false;
                for roi = obj.editingGroup.rois
                    if ~isempty(roi.scanfields)
                        roi.scanfields(1).sizeXY = sf.sizeXY;
                        roi.scanfields(1).rotation = sf.rotation;
                        roi.scanfields(1).stimfcnhdl = sf.stimfcnhdl;
                    end
                end
                obj.enableListeners = true;
                obj.h2DScannerFovSurf.CData = [];
            end
        end
        
        slmPropsPanelCtlCb(obj,src,~);
        
        updateGlobalPanel(obj);
        
        function globalPnlCallback(obj,src,prop,idx,fac,off)
            v = str2double(src.String);
            
            if fac
                v = v / (obj.xyUnitFactor^fac);
            end
            
            if off
                v = v - obj.xyUnitOffset(idx);
            end
            
            if ~isempty(v) && ~isnan(v)
                obj.enableListeners = false;
                for sf = [obj.editingGroup.rois.scanfields]
                    sf.(prop)(idx) = v;
                end
                obj.enableListeners = true;
                obj.rgChangedPar();
            end
            
            obj.updateGlobalPanel();
        end
        
        function zPlaneCtlCb(obj,src,~)
            etzplane = str2num(src.String);
            
            if ~isempty(etzplane) && ~isnan(etzplane) && ~isinf(etzplane)
                obj.editorZ = etzplane;
            else
                most.idioms.warn('Z plane must be a valid number. NaN and Inf are not allowed. Resetting to previous value.');
                obj.editorZ = obj.editorZ;
            end
        end
        
        function [roi, sf] = createRoi(obj,varargin)
            if nargin > 3
                z = varargin{3};
                varargin(3) = [];
            else
                z = obj.editorZ;
            end
            
            sf = obj.createSf(varargin{:});
            
            roi = scanimage.mroi.Roi;
            roi.add(z,sf);
            
            obj.enableListeners = false;
            obj.editingGroup.add(roi);
            obj.satisfyConstraints(sf);
            obj.enableListeners = true;
            
            if obj.editorModeIsSlm
                obj.updateScanPathCache();
                obj.selectedObj = sf;
                obj.selectedObjParent = roi;
                obj.selectedObjRoiIdx = numel(obj.editingGroup.rois);
            elseif ~obj.drawMultipleRois
                obj.createMode = false;
                obj.updateScanPathCache();
                obj.changeSelection(sf,roi);
            else
                obj.updateScanPathCache();
                obj.updateDisplay();
            end
            
            obj.setZProjectionLimits();
            obj.updateTable();
        end
        
        sf = createSf(obj,centerXY,sizeXY,power);
        
        function satisfyConstraints(obj,sf)
            if obj.editorModeIsSlm
                if sf == obj.slmPatternSfParent
                    % satisfy constaints of galvo position for GG+SLM set
                    obj.scannerSet.satisfyConstraintsRoiGroup(obj.slmPatternRoiGroupParent,sf);
                else
                    % satisfy constraints of focal points?
                end
            else
                obj.scannerSet.satisfyConstraintsRoiGroup(obj.editingGroup,sf);
            end
        end
        
        function editOrCreateScanfieldAtZ(obj,varargin)
            if ismember(obj.editorZ, obj.selectedObj.zs)
                sf = obj.selectedObj.get(obj.editorZ);
                obj.changeSelection(sf,obj.selectedObj);
                obj.fixTableCheck();
            else
                sf = obj.selectedObj.get(obj.editorZ,true);
                if isempty(sf)
                    sf = obj.createSf();
                else
                    sf = sf.copy();
                end
                obj.enableListeners = false;
                obj.selectedObj.add(obj.editorZ,sf);
                obj.enableListeners = true;
                obj.changeSelection(sf,obj.selectedObj);
                obj.updateTable();
                obj.setZProjectionLimits();
            end
        end
        
        function imagingSystemChange(obj,varargin)
            switch obj.editorMode
                case {'imaging' 'analysis'}
                    obj.scannerSet = obj.hModel.hScan2D.scannerset;
                    obj.canDrawArray = isa(obj.scannerSet,'scanimage.mroi.scannerset.ResonantGalvoGalvo');
                    obj.hNewImagingRoiPanelCtls.cbDrawArray.Visible = most.gui.OnOff(obj.canDrawArray);
                    most.idioms.safeDeleteObj(obj.hSSListeners);
                    obj.hSSListeners = most.ErrorHandler.addCatchingListener(obj.hModel.hScan2D, 'scannerset','PostSet',@obj.ssChange);
            end
            obj.frameRateUpdate();
        end
        
        function frameRateUpdate(obj,varargin)
            s = '';
            if obj.hModel.hRoiManager.mroiEnable
                r = obj.hModel.hRoiManager.scanFrameRate;
                if ~isinf(r) && ~isnan(r)
                    s = most.idioms.engineersStyle(1/r,'s','%.2f',' ');
                    s = sprintf('%.2f Hz (%s)',r,s);
                end
            end
            obj.hGlobalImagingSfPropsPanelCtls.etFrameRate.String = s;
        end
        
        function ssChange(obj,varargin)
            obj.scannerSet = obj.hModel.hScan2D.scannerset;
        end
        
        function c = pickMostUniqueCtxImColor(obj)
            usedColors = [obj.hContextImages.colorIdx];
            for i = numel(obj.EDGE_COLOR_LIST):-1:1
                usedColorCnt(i) = sum(usedColors == i);
            end
            [~, c] = min(usedColorCnt);
        end
        
        function startCellPick(obj)
            obj.cellPickZs = [];
            obj.cellPickCellsAtZ = {};
            obj.cellPickSelectedCellIdx = [];
            
            obj.updateCellPickToZ();
            obj.updateCellPickButtons();
        end
        
        function updateCellPickToZ(obj)
            most.idioms.safeDeleteObj(obj.cellPickSurfs);
            obj.cellPickSurfs = [];
            
            if obj.createMode && obj.cellPickOn
                ctxImSurfs = [obj.hContextImages(:).visibleSurfs];
                cpSurfs = {};
                
                for i = 1:numel(ctxImSurfs)
                    srf = ctxImSurfs(i);
                    cdsz = size(srf.CData);
                    cpSurfs{end+1} = surface(srf.XData,srf.YData,srf.ZData +.01,'Parent',obj.h2DMainViewAxes,'FaceColor','texturemap','CData',zeros(cdsz,'uint8'),...
                        'FaceAlpha','texturemap','AlphaData',zeros(cdsz(1:2)),'EdgeColor','none','ButtonDownFcn',@obj.cellPickHit,'userdata',srf,'Visible',srf.Visible);
                end
                obj.cellPickSurfs = [cpSurfs{:}];
                
                obj.redrawCellPickSurfs();
            end
        end
        
        function cellPickHit(obj,stop,varargin)
            persistent hitpt;
            persistent cpsurf;
            
            if nargin > 2
                hitpt = most.gui.getPointerLocation(obj.h2DMainViewAxes);
                cpsurf = stop;
                
                set(obj.hFig,'WindowButtonMotionFcn',@(varargin)obj.cellPickHit(false),'WindowButtonUpFcn',@(varargin)obj.cellPickHit(true));
                waitfor(obj.hFig,'WindowButtonMotionFcn',[]);
            elseif stop
                set(obj.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
                
                %try to pick a cell!
                obj.pickCell(cpsurf,hitpt);
            else
                % cursor moved. let this be a pan instead of a cell pick
                set(obj.hFig,'WindowButtonMotionFcn',[]);
                obj.mainPan(obj,false,[]);
            end
        end
        
        pickCell(obj,cpSurf,hitPt);
        
        function updateCellPickButtons(obj)
            CreationButtons = [...
                obj.hNewImagingRoiPanelCtls.pbCreate.hCtl,...
                obj.hNewStimRoiPanelCtls.pbCreate.hCtl,...
                obj.hNewAnalysisRoiPanelCtls.pbCreate.hCtl];
            set(CreationButtons, 'enable', most.gui.OnOff(0 < numel(obj.cellPickZs)));
            
            ErosionButtons = [...
                obj.hNewImagingRoiPanelCtls.pbErode,...
                obj.hNewStimRoiPanelCtls.pbErode,...
                obj.hNewAnalysisRoiPanelCtls.pbErode];
            DilationButtons = [...
                obj.hNewImagingRoiPanelCtls.pbDilate...
                obj.hNewStimRoiPanelCtls.pbDilate...
                obj.hNewAnalysisRoiPanelCtls.pbDilate];
            DeletionButtons = [...
                obj.hNewImagingRoiPanelCtls.pbDelete,...
                obj.hNewStimRoiPanelCtls.pbDelete,...
                obj.hNewAnalysisRoiPanelCtls.pbDelete];
            set([ErosionButtons, DilationButtons, DeletionButtons], ...
                'enable', most.gui.OnOff(~isempty(obj.cellPickSelectedCellIdx)));
        end
        
        function redrawCellPickSurfs(obj)
            obj.cellPickSurfsIdMap = cell(numel(obj.cellPickSurfs),1);
            for i = 1:numel(obj.cellPickSurfs)
                cdat = zeros(size(obj.cellPickSurfs(i).CData),'uint8');
                adat = zeros(size(obj.cellPickSurfs(i).AlphaData));
                idMap = adat;
                
                [tf, j] = ismember(obj.editorZ, obj.cellPickZs);
                if tf
                    for k = 1:numel(obj.cellPickCellsAtZ{j})
                        cll = obj.cellPickCellsAtZ{j}(k);
                        if cll.surfIdx == i
                            if ~isempty(obj.cellPickSelectedCellIdx) && (k == obj.cellPickSelectedCellIdx)
                                cdat(sub2ind(size(cdat),cll.pts(:,1),cll.pts(:,2),ones(length(cll.pts),1))) = 0;
                                cdat(sub2ind(size(cdat),cll.pts(:,1),cll.pts(:,2),2*ones(length(cll.pts),1))) = 255;
                            else
                                cdat(sub2ind(size(cdat),cll.pts(:,1),cll.pts(:,2),ones(length(cll.pts),1))) = 255;
                            end
                            adat(sub2ind(size(adat),cll.pts(:,1),cll.pts(:,2))) = .5;
                            idMap(sub2ind(size(adat),cll.pts(:,1),cll.pts(:,2))) = k;
                        end
                    end
                end
                
                obj.cellPickSurfs(i).CData = cdat;
                obj.cellPickSurfs(i).AlphaData = adat;
                obj.cellPickSurfsIdMap{i} = idMap;
            end
        end
        
        function pbDilateCell(obj,varargin)
            [tf, i] = ismember(obj.editorZ, obj.cellPickZs);
            if tf && ~isempty(obj.cellPickSelectedCellIdx)
                cll = obj.cellPickCellsAtZ{i}(obj.cellPickSelectedCellIdx);
                wkngIm = double(max(obj.cellPickSurfs(cll.surfIdx).UserData.CData,[],3));
                obj.cellPickCellsAtZ{i}(obj.cellPickSelectedCellIdx).pts = obj.cellPickFunc('dilate', wkngIm, cll.pts);
                obj.redrawCellPickSurfs();
            end
        end
        
        function pbErodeCell(obj,varargin)
            [tf, i] = ismember(obj.editorZ, obj.cellPickZs);
            if tf && ~isempty(obj.cellPickSelectedCellIdx)
                cll = obj.cellPickCellsAtZ{i}(obj.cellPickSelectedCellIdx);
                wkngIm = double(max(obj.cellPickSurfs(cll.surfIdx).UserData.CData,[],3));
                obj.cellPickCellsAtZ{i}(obj.cellPickSelectedCellIdx).pts = obj.cellPickFunc('erode', wkngIm, cll.pts);
                obj.redrawCellPickSurfs();
            end
        end
        
        function pbDeleteCell(obj,varargin)
            [tf, i] = ismember(obj.editorZ, obj.cellPickZs);
            if tf && ~isempty(obj.cellPickSelectedCellIdx)
                obj.cellPickCellsAtZ{i}(obj.cellPickSelectedCellIdx) = [];
                obj.cellPickSelectedCellIdx = min(obj.cellPickSelectedCellIdx, numel(obj.cellPickCellsAtZ{i}));
                
                if obj.cellPickSelectedCellIdx < 1
                    obj.cellPickSelectedCellIdx = [];
                    obj.cellPickCellsAtZ(i) = [];
                    obj.cellPickZs(i) = [];
                end
                
                obj.redrawCellPickSurfs();
                obj.updateCellPickButtons();
            end
        end
        
        endCellPick(obj,tfCreate);
        
        function pts = diskCellPickFunc(obj, op, imData, xyPt)
            import scanimage.guis.roigroupeditor.cellpick.cellDetSemiautoGradient;
            import scanimage.guis.roigroupeditor.cellpick.dilateRoiIndices;
            import scanimage.guis.roigroupeditor.cellpick.erodeRoiIndices;

            pts = [];
            
            switch op
                case 'pick'
                    indices = cellDetSemiautoGradient(xyPt,imData,obj.diskCellPickParams);
                    
                case 'dilate'
                    indices = sub2ind(size(imData),xyPt(:,1),xyPt(:,2));
                    indices = dilateRoiIndices(indices, 2, size(imData));
                    
                case 'erode'
                    indices = sub2ind(size(imData),xyPt(:,1),xyPt(:,2));
                    indices = erodeRoiIndices(indices, 2, size(imData));
            end
            
            if ~isempty(indices)
                [pts(:,1), pts(:,2)] = ind2sub(size(imData),indices);
            end
        end
        
        function pts = annularCellPickFunc(obj, op, imData, xyPt)
            import scanimage.guis.roigroupeditor.cellpick.cellDetSemiautoGradient;
            import scanimage.guis.roigroupeditor.cellpick.dilateRoiIndices;
            import scanimage.guis.roigroupeditor.cellpick.erodeRoiIndices;

            pts = [];
            
            switch op
                case 'pick'
                    indices = cellDetSemiautoGradient(xyPt,imData,obj.annularCellPickParams);
                    
                case 'dilate'
                    indices = sub2ind(size(imData),xyPt(:,1),xyPt(:,2));
                    indices = dilateRoiIndices(indices, 2, size(imData));
                    
                case 'erode'
                    indices = sub2ind(size(imData),xyPt(:,1),xyPt(:,2));
                    indices = erodeRoiIndices(indices, 2, size(imData));
            end
            
            if ~isempty(indices)
                [pts(:,1), pts(:,2)] = ind2sub(size(imData),indices);
            end
        end
        
        function pts = manualCellPickFunc(obj, op, imData, xyPt, rad)
            if nargin < 5 || isempty(rad)
                rad = 6; % default radius
            end
            
            crad = ceil(rad);
            
            switch op
                case 'pick'
                    pts = xyPt;
                    for j = max((xyPt(2)-crad),1):min((xyPt(2)+crad),size(imData,2))
                        for i = max((xyPt(1)-crad),1):min((xyPt(1)+crad),size(imData,1))
                            if norm(xyPt - [i j]) <= rad
                                pts(end+1,:) = [i j];
                            end
                        end
                    end
                    
                case 'dilate'
                    ctr = xyPt(1,:); %first point is the center point
                    diffs = xyPt - repmat(ctr,size(xyPt,1),1); % distance of each point from centroid
                    r = max(sqrt(sum(diffs.^2,2))); % max distance
                    r = 1.1*r; % increase r by 10%
                    pts = obj.manualCellPickFunc('pick', imData, round(ctr), r); % find the new points
                    
                case 'erode'
                    ctr = xyPt(1,:); %first point is the center point
                    diffs = xyPt - repmat(ctr,size(xyPt,1),1); % distance of each point from centroid
                    r = max(sqrt(sum(diffs.^2,2))); % max distance
                    r = 0.9*r; % increase r by 10%
                    pts = obj.manualCellPickFunc('pick', imData, round(ctr), r); % find the new points
            end
        end
        
        function quickAddPause(obj,pos,silentUpdate)
            if nargin < 2
                pos = [];
            end
            
            if nargin < 3 || isempty(silentUpdate)
                silentUpdate = false;
            end
            
            if ~silentUpdate
                obj.enableListeners = false;
            end
            
            roi = scanimage.mroi.Roi;
            sf = scanimage.mroi.scanfield.fields.StimulusField('scanimage.mroi.stimulusfunctions.pause',{},obj.stimQuickAddDuration/1000,...
                1,[obj.defaultRoiPositionX obj.defaultRoiPositionY],[obj.defaultRoiWidth obj.defaultRoiHeight]/2,0,obj.defaultStimPower);
            roi.add(obj.editorZ,sf);
            
            if isempty(pos)
                obj.editingGroup.add(roi);
            else
                if pos > 0
                    obj.editingGroup.insertAfterId(pos,roi);
                else
                    obj.editingGroup.insertAfterId(1,roi);
                    obj.editingGroup.moveById(roi.uuiduint64,-1);
                end
            end
            
            if ~silentUpdate
                obj.enableListeners = true;
                obj.updateScanPathCache();
                obj.updateTable();
                obj.updateDisplay();
            end
        end
        
        function quickAddPark(obj,pos)
            if nargin < 2
                pos = [];
            end
            
            obj.enableListeners = false;
            
            roi = scanimage.mroi.Roi;
            sf = scanimage.mroi.scanfield.fields.StimulusField('scanimage.mroi.stimulusfunctions.park',{},obj.stimQuickAddDuration/1000,...
                1,[obj.defaultRoiPositionX obj.defaultRoiPositionY],[obj.defaultRoiWidth obj.defaultRoiHeight]/2,0,obj.defaultStimPower);
            roi.add(obj.editorZ,sf);
            
            if isempty(pos)
                obj.editingGroup.add(roi);
            else
                if pos > 0
                    obj.editingGroup.insertAfterId(pos,roi);
                else
                    obj.editingGroup.insertAfterId(1,roi);
                    obj.editingGroup.moveById(roi.uuiduint64,-1);
                end
            end
            
            obj.enableListeners = true;
            obj.updateScanPathCache();
            obj.updateTable();
            obj.updateDisplay();
        end
        
        function newRatio = cleanResolutionRatioValue(obj, val)
            if ~isempty(val) && ~isnan(val) && ~isinf(val) && (val > 0)
                newRatio = abs(round(val));
                
                if isempty(newRatio) || isnan(newRatio) || (newRatio <= 0)
                    newRatio = 1;
                elseif isinf(newRatio)
                    newRatio = 1000000000;
                end
            else
                if isinf(val)
                    newRatio = 1000000000;
                else
                    newRatio = 1;
                end
            end
        end
        
        function loadBitmapFromFile(obj,varargin)
            [fn, pth] = uigetfile({'*.png' 'PNGs'; '*.bmp' 'Bitmap'; '*.mat' 'MAT file'},'Import Bitmap Data...',obj.getClassDataVar('lastSlmFile'));
            if fn==0;return;end
            filename = fullfile(pth,fn);
            obj.setClassDataVar('lastSlmFile',filename);
            
            [~, ~, ext] = fileparts(filename);
            
            switch(ext)
                case {'.bmp' '.png'}
                    slmPattern = mean(double(imread(filename)),3);
                    
                case '.mat'
                    load(filename);
                    if ~exist('slmPattern','var')
                        errordlg('MAT file must include a variable called ''slmPattern''.','SLM Pattern Import');
                        return;
                    end
                    
                otherwise
                    errordlg('Invalid extension/file type.','SLM Pattern Import');
            end
            
            ss = obj.scannerSet;
            if isa(ss,'scanimage.mroi.scannerset.GalvoGalvo')
                ss = ss.slm;
            end
            nwSz = size(slmPattern);
            if (numel(nwSz) ~= 2) || ~all(nwSz == fliplr(ss.scanners{1}.hDevice.pixelResolutionXY))
                errordlg('Incorrect SLM pattern size.', 'SLM Pattern Import', 'modal');
                return;
            end
            
            obj.slmPatternSfParent.slmPattern = slmPattern;
        end
        
        function loadBitmapFromVar(obj,varargin)
            answer=inputdlg('Enter the name of a variable on the workspace (or a MATLAB expression) to import the pattern from.','SLM Pattern Editor',1,{'slmPattern'},struct('WindowStyle', 'modal'));
            if ~isempty(answer)
                try
                    newPat = evalin('base',answer{1});
                catch ME
                    errordlg(sprintf('Error evaluating input: %s',ME.message), 'SLM Pattern Import', 'modal');
                    return;
                end
                
                nwSz = size(newPat);
                
                ss = obj.scannerSet;
                if isa(ss,'scanimage.mroi.scannerset.GalvoGalvo')
                    ss = ss.slm;
                end
                
                if isempty(newPat)
                    obj.slmPatternSfParent.slmPattern = zeros(fliplr(ss.scanners{1}.pixelResolutionXY));
                    return;
                elseif (numel(nwSz) ~= 2) || ~all(nwSz == fliplr(ss.scanners{1}.pixelResolutionXY))
                    errordlg('Incorrect SLM pattern size.', 'SLM Pattern Import', 'modal');
                    return;
                end
                
                obj.slmPatternSfParent.slmPattern = newPat;
            end
        end
        
        function saveBitmapToFile(obj,varargin)
            [fn, pth] = uiputfile({'*.png' 'PNG'; '*.bmp' 'Bitmap'; '*.mat' 'MAT file'},'Export Bitmap Data...',obj.getClassDataVar('lastSlmFile'));
            if fn==0;return;end
            filename = fullfile(pth,fn);
            obj.setClassDataVar('lastSlmFile',filename);
            
            [~, ~, ext] = fileparts(filename);
            
            slmPattern = obj.h2DScannerFovSurf.CData(:,:,3);
            
            switch(ext)
                case '.png'
                    imwrite(repmat(slmPattern,1,1,3), filename, 'PNG');
                    
                case '.bmp'
                    imwrite(repmat(slmPattern,1,1,3), filename, 'BMP');
                    
                case '.mat'
                    slmPattern = double(slmPattern)/255;
                    save(filename,'slmPattern');
                    
                otherwise
                    errordlg('Invalid extension/file type.','SLM Pattern Export');
            end
        end
        
        function saveBitmapToVar(obj,varargin)
            answer=inputdlg('Enter the name of a variable to export the pattern into.','SLM Pattern Editor',1,{'slmPattern'},struct('WindowStyle', 'modal'));
            if ~isempty(answer)
                assignin('base',answer{1},obj.slmPatternSfParent.slmPattern);
            end
        end
        
        function clearBitmap(obj,varargin)
            slmPattern = obj.h2DScannerFovSurf.CData;
            if ~isempty(slmPattern) && (sum(slmPattern(:)) > 0)
                answer = questdlg('Are you sure you want to clear the bitmap?', 'SLM Pattern Editor','Yes','Cancel','Cancel');
                if strcmp(answer, 'Yes')
                    ss = obj.scannerSet;
                    if isa(ss,'scanimage.mroi.scannerset.GalvoGalvo')
                        ss = ss.slm;
                    end
                    obj.slmPatternSfParent.slmPattern = zeros(fliplr(ss.scanners{1}.hDevice.pixelResolutionXY));
                end
            end
        end
        
        function updateScrollPatch(obj)
            YLim = obj.h2DZScrollAxes.YLim;
            
            xx = linspace(0,.8,100);
            yy1 = spline(xx([1 end]),[0 YLim(1) obj.editorZ (obj.editorZ-YLim(1))/2],xx);
            yy2 = spline(xx([1 end]),[0 YLim(2) obj.editorZ (obj.editorZ-YLim(2))/2],xx);
            
            patchVertices = [        xx(:) ,        yy1(:) ;
                flipud(xx(:)), flipud(yy2(:)) ];
            
            obj.h2DScrollPatch.Vertices = patchVertices;
            obj.h2DScrollPatch.Faces = 1:size(patchVertices,1);
            
            
            textHeight = diff(YLim) / obj.h2DZScrollAxes.Position(4) * 20;
            position = [-0.25 obj.editorZ-textHeight/2 0.9 textHeight];
            obj.hZCursorTextRect.Position = position;
            obj.hZCursorTextRect.Curvature = [0.2 1];
            
            obj.hZCursorText.Position = [0.2 obj.editorZ];
            
            z_meter = obj.editorZ / 1e6;
            obj.hZCursorText.String = most.idioms.engineersStyle(z_meter,'m','%.1f');
            
            obj.h2DScrollKnob.Color = 'black';
        end

        setPowerBoxName(obj,varargin);
        
        addPowerBox(obj, varargin);

        deletePowerBox(obj, varargin);

        function lockPowerBox(obj,src,~)
            tf = logical(src.Value);
            obj.selectedPowerBox.locked = tf;
            obj.pmPowerBoxLocation.Enable = most.gui.OnOff(~tf);
        end

        setPowerBoxLocation(obj, ~, ~);

        setPowerBoxEnableMask(obj, varargin);

        setPowerBoxMaskResolution(obj, varargin);

        function resetPowerBoxMask(obj, varargin)
            obj.selectedPowerBoxDisplay.resetMask();
            obj.hModel.hBeams.updateBeamBufferAsync(true);
        end

        setPowerBoxType(obj, src, ~);

        function setPowerBoxPower(obj, varargin)
            obj.hModel.hBeams.updateBeamBufferAsync(true);
        end

        setPowerBoxBackground(obj, src, evt);

        selectPowerBoxContextImage(obj, src, evt);

        addPowerBoxContextImageToMask(obj, src, evt);

        updatePowerBoxContextImageThreshold(obj, src, evt);

        updatePowerBoxContextImageValue(obj, src, evt);

        setPowerBoxBrushEnable(obj, varargin);

        powerBoxBrushHover(obj, varargin);

        function centerPowerBoxBrushPreview(obj, varargin)
            obj.selectedPowerBoxDisplay.centerBrush();
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

function initGui(obj)
    kpf = {'KeyPressFcn',@obj.keyPressFcn};
    set(obj.hFig,'Name','ROI Group Editor','WindowScrollWheelFcn',@obj.scrollWheelFcn,kpf{:});

    hMainFlow = most.gui.uiflowcontainer('Parent', obj.hFig,'FlowDirection','RightToLeft');

    %% right side panel
    hRightPanel = uipanel('Parent', hMainFlow);
    set(hRightPanel, 'WidthLimits', [400 400]);
    hRightFlow = most.gui.uiflowcontainer('Parent', hRightPanel,'FlowDirection','TopDown');

    %% Save/Load/Clear Buttons
    obj.hButtonFlow = most.gui.uiflowcontainer('Parent', hRightFlow,...
        'FlowDirection', 'LeftToRight',...
        'HeightLimits', 30);
    uicontrol('Parent',obj.hButtonFlow,'String','Save Group...','callback',@obj.saveGroup,kpf{:});
    uicontrol('Parent',obj.hButtonFlow,'String','Load Group...','callback',@obj.loadGroup,kpf{:});
    uicontrol('Parent',obj.hButtonFlow,'String','Clear Group','callback',@obj.clearGroup,kpf{:});

    %% Analysis Copy Button
    obj.hCopyButtonFlow = most.gui.uiflowcontainer('Parent', hRightFlow, ...
        'FlowDirection', 'LeftToRight',...
        'HeightLimits', 30, ...
        'visible','off');
    uicontrol('Parent', obj.hCopyButtonFlow, ...
        'String', 'Copy Imaging ROIs', ...
        'callback',@obj.copyImagingRois,kpf{:});

    %% ROI Group Name
    obj.hNameFlow = most.gui.uiflowcontainer('Parent', hRightFlow, ...
        'FlowDirection', 'LeftToRight', ...
        'HeightLimits', 24);
    most.gui.staticText('Parent',obj.hNameFlow,'String','ROI Group Name:','WidthLimits',90);
    obj.etName = most.gui.uicontrol('Parent',obj.hNameFlow, ...
        'String', 'Awesome ROIs', ...
        'Style', 'Edit', ...
        'HorizontalAlignment', 'left', ...
        'callback',@obj.chgName);

    %% SLM Pattern Selector
    obj.hSlmPatternTypeFlow = most.gui.uiflowcontainer('Parent', hRightFlow, ...
        'FlowDirection', 'LeftToRight', ...
        'HeightLimits', 30, ...
        'visible','off');
    most.gui.staticText('Parent',obj.hSlmPatternTypeFlow, ...
        'String', 'SLM Pattern Type:', ...
        'WidthLimits',100);
    most.gui.uicontrol('Parent',obj.hSlmPatternTypeFlow, ...
        'String', 'Point Array', ...
        'style', 'togglebutton', ...
        'Bindings',{obj 'slmPatternType' 'match' 'point'}, ...
        kpf{:});
    most.gui.uicontrol('Parent', obj.hSlmPatternTypeFlow, ...
        'String', 'Bitmap', ...
        'style', 'togglebutton', ...
        'Bindings', {obj 'slmPatternType' 'match' 'bitmap'}, ...
        kpf{:});

    %% SLM Bitmap Options
    obj.hSlmBitmapFlow = most.gui.uiflowcontainer('Parent', hRightFlow, ...
        'FlowDirection','TopDown', ...
        'visible','off', ...
        'margin',.0001);
    hSlmSaveLoadFlow = most.gui.uiflowcontainer('Parent', obj.hSlmBitmapFlow, ...
        'FlowDirection','LeftToRight', ...
        'HeightLimits', 30);
    most.gui.uicontrol('Parent',hSlmSaveLoadFlow, ...
        'String','Load From File', ...
        'callback',@obj.loadBitmapFromFile, ...
        kpf{:});
    most.gui.uicontrol('Parent',hSlmSaveLoadFlow, ...
        'String','Load From Var', ...
        'callback',@obj.loadBitmapFromVar, ...
        kpf{:});
    most.gui.uicontrol('Parent',hSlmSaveLoadFlow, ...
        'String','Save To File', ...
        'callback',@obj.saveBitmapToFile, ...
        kpf{:});
    most.gui.uicontrol('Parent',hSlmSaveLoadFlow, ...
        'String','Save To Var', ...
        'callback',@obj.saveBitmapToVar, ...
        kpf{:});
    most.gui.uicontrol('Parent',hSlmSaveLoadFlow, ...
        'String','Clear', ...
        'callback',@obj.clearBitmap, ...
        'WidthLimits',50, ...
        kpf{:});

    hSlmTransparencyFlow = most.gui.uiflowcontainer('Parent', obj.hSlmBitmapFlow, ...
        'FlowDirection','LeftToRight', ...
        'HeightLimits', 26);
    most.gui.staticText('Parent',hSlmTransparencyFlow, ...
        'String','Bitmap Display Transparency:', ...
        'WidthLimits',148);
    most.gui.slider('parent',hSlmTransparencyFlow, ...
        'Bindings', {obj 'slmBitmapDisplayTransparency' 1});

    brushPanel = most.gui.uipanel('Parent', obj.hSlmBitmapFlow, ...
        'title', 'Brush Tool', ...
        'HeightLimits', 116);
    brushPanelFlow = most.gui.uiflowcontainer('Parent', brushPanel, ...
        'FlowDirection','TopDown', ...
        'margin',.0001);

    brushEnableFlow = most.gui.uiflowcontainer('Parent', brushPanelFlow, ...
        'FlowDirection','LeftToRight', ...
        'HeightLimits', 24);
    most.gui.uicontrol('Parent',brushEnableFlow, ...
        'string', 'Enable Brush', ...
        'style','checkbox', ...
        'Bindings',{obj 'slmBitmapBrushEnable' 'value'},kpf{:});

    brushValueFlow = most.gui.uiflowcontainer('Parent', brushPanelFlow, ...
        'FlowDirection','LeftToRight', ...
        'HeightLimits', 24);
    most.gui.staticText('Parent',brushValueFlow, ...
        'String','Brush Value:', ...
        'WidthLimits',90);
    most.gui.uicontrol('Parent',brushValueFlow, ...
        'style','edit', ...
        'Bindings',{obj 'slmBitmapBrushValue' 'value'}, ...
        'WidthLimits',40);
    most.gui.slider('parent',brushValueFlow, 'Bindings', {obj 'slmBitmapBrushValue' 1});

    brushSizeFlow = most.gui.uiflowcontainer('Parent', brushPanelFlow, ...
        'FlowDirection','LeftToRight', ...
        'HeightLimits', 24);
    most.gui.staticText('Parent',brushSizeFlow, ...
        'String','Brush Size:', ...
        'WidthLimits',90);
    most.gui.uicontrol('Parent',brushSizeFlow, ...
        'style','edit', ...
        'Bindings',{obj 'slmBitmapBrushSize' 'value'}, ...
        'WidthLimits',40);
    most.gui.slider('parent',brushSizeFlow, ...
        'Bindings', {obj 'slmBitmapBrushSize' 1}, ...
        'max', 256, ...
        'min', 1);

    brushSoftFlow = most.gui.uiflowcontainer('Parent', brushPanelFlow, ...
        'FlowDirection','LeftToRight', ...
        'HeightLimits', 24);
    most.gui.staticText('Parent',brushSoftFlow,'String','Brush Soft Edge:','WidthLimits',90);
    most.gui.uicontrol('Parent',brushSoftFlow, ...
        'style','edit', ...
        'Bindings',{obj 'slmBitmapBrushSoftEdgePct' 'value'}, ...
        'WidthLimits',40);
    most.gui.slider('parent',brushSoftFlow, 'Bindings', {obj 'slmBitmapBrushSoftEdgePct' 1});


    %% Power Box Controls
    obj.hSamplePowerBoxFlow = most.gui.uiflowcontainer('Parent', hRightFlow,'FlowDirection','TopDown', 'visible','off','margin',.0001);
    
    titleBar(obj.hSamplePowerBoxFlow,'Power Box Settings');

    hPbNameFlow = most.gui.uiflowcontainer('Parent', obj.hSamplePowerBoxFlow,'FlowDirection','LeftToRight','HeightLimits', 26);
    most.gui.staticText('Parent',hPbNameFlow,'String','Power box name:','WidthLimits',148);
    obj.etPowerBoxName = most.gui.uicontrol('Parent',hPbNameFlow,'Style','edit','String','','callback',@obj.setPowerBoxName);
    
    hPbTypeFlow = most.gui.uiflowcontainer('Parent', obj.hSamplePowerBoxFlow,'FlowDirection','LeftToRight','HeightLimits', 26);
    most.gui.staticText('Parent',hPbTypeFlow,'String','Power box type:','WidthLimits',148);
    obj.pmPowerBoxType = most.gui.uicontrol('Parent',hPbTypeFlow,'Style','popupmenu','String',{'Reference' 'Sample'},'callback',@obj.setPowerBoxType);

    hPbPowerFlow = most.gui.uiflowcontainer('Parent', obj.hSamplePowerBoxFlow,'FlowDirection','LeftToRight','HeightLimits', 26);
    most.gui.staticText('Parent',hPbPowerFlow,'String','Power [%]:','WidthLimits',148);
    obj.etPowerBoxPower = most.gui.uicontrol('Parent',hPbPowerFlow,'Style','edit','String','','callback',@obj.setPowerBoxPower);

    hPbLockFlow = most.gui.uiflowcontainer('Parent', obj.hSamplePowerBoxFlow,'FlowDirection','LeftToRight','HeightLimits', 26);
    most.gui.staticText('Parent',hPbLockFlow,'String','Powerbox Location:','WidthLimits',100);
    obj.pmPowerBoxLocation = most.gui.uicontrol('Parent',hPbLockFlow,'Style','popupmenu','String',{''},'callback',@obj.setPowerBoxLocation);
    obj.pmPowerBoxLocked = most.gui.uicontrol('Parent',hPbLockFlow,'Style','checkbox','String','Lock Position/Scaling','callback',@obj.lockPowerBox,'WidthLimits',120);

    hPbMaskEnableFlow = most.gui.uiflowcontainer('Parent', obj.hSamplePowerBoxFlow,'FlowDirection','LeftToRight','HeightLimits', 26);
    obj.pmPowerBoxMaskEnable = most.gui.uicontrol('Parent',hPbMaskEnableFlow,'Style','checkbox','String','Enable Mask','callback',@obj.setPowerBoxEnableMask);

    obj.powerBoxMaskSettingsPanel = most.gui.uipanel('Parent', obj.hSamplePowerBoxFlow, 'title', 'Mask Settings', 'HeightLimits', 550);
    maskSettingsFlow = most.gui.uiflowcontainer('Parent', obj.powerBoxMaskSettingsPanel,'FlowDirection','TopDown','margin',.0001);

    hPbMaskResFlow = most.gui.uiflowcontainer('Parent', maskSettingsFlow,'FlowDirection','LeftToRight','HeightLimits', 26);
    most.gui.staticText('Parent',hPbMaskResFlow,'String','X Resolution [Pixels]:','WidthLimits',110);
    obj.etPowerBoxMaskResX = most.gui.uicontrol('Parent',hPbMaskResFlow,'Style','edit','callback',@obj.setPowerBoxMaskResolution,'WidthLimits',70);
    most.gui.staticText('Parent',hPbMaskResFlow,'String','   Y Resolution [Pixels]:','WidthLimits',110);
    obj.etPowerBoxMaskResY = most.gui.uicontrol('Parent',hPbMaskResFlow,'Style','edit','callback',@obj.setPowerBoxMaskResolution,'WidthLimits',70);

    hPbBackgroundFlow = most.gui.uiflowcontainer('Parent', maskSettingsFlow,'FlowDirection','LeftToRight','HeightLimits', 26);
    most.gui.staticText('Parent',hPbBackgroundFlow,'String','Power box background:','WidthLimits',120);
    obj.pmPowerBoxMaskBackground = most.gui.uicontrol('Parent',hPbBackgroundFlow,'Style','popupmenu','String',{'Use beam controls' 'Zero'},'callback',@obj.setPowerBoxBackground);
    most.gui.uicontrol('Parent',hPbBackgroundFlow,'String',{'Reset Mask'},'callback',@obj.resetPowerBoxMask);

    contextImageImportPanel = most.gui.uipanel('Parent', maskSettingsFlow, 'title', 'Context Image Import', 'HeightLimits', 360);
    contextImageImportFlow = most.gui.uiflowcontainer('Parent', contextImageImportPanel,'FlowDirection','TopDown','margin',.0001);
    contextImageSelectionFlow = most.gui.uiflowcontainer('Parent', contextImageImportFlow,'FlowDirection','LeftToRight','HeightLimits', 26);
    most.gui.staticText('Parent',contextImageSelectionFlow,'String','Context Image:','WidthLimits',120);
    contextImageOptions = arrayfun(@(ci)ci.name,obj.hContextImages,'UniformOutput',false);
    contextImageOptions = [{''} contextImageOptions{:}];
    obj.pmPowerBoxContextImage = most.gui.uicontrol('Parent',contextImageSelectionFlow,'String',contextImageOptions,'style','popupmenu','callback',@obj.selectPowerBoxContextImage);
    most.gui.uicontrol('Parent',contextImageSelectionFlow,'String','Add to mask','callback',@obj.addPowerBoxContextImageToMask);
    most.gui.uiflowcontainer('Parent', contextImageImportFlow,'FlowDirection','LeftToRight','HeightLimits', 24); %empty line for aesthetics
    hAxFlow = most.gui.uiflowcontainer('Parent',contextImageImportFlow,'FlowDirection','LeftToRight','HeightLimits',200);
    contextImageAxis = most.idioms.axes('Parent',hAxFlow,'Units','normalized','Position',[0 0 1 1],'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'Visible','off','XLimSpec','tight','YLimSpec','tight');
    [xx,yy,zz] = ndgrid([-0.5,0.5]*1,[-0.5,0.5]*1,0);
    obj.hPowerBoxMaskImage = surface(contextImageAxis,xx,yy,zz,0,'FaceColor','texturemap','CDataMapping','scaled','FaceLighting','none');
    colormap(contextImageAxis,'gray');
    most.gui.uiflowcontainer('Parent', contextImageImportFlow,'FlowDirection','LeftToRight','HeightLimits', 18); %empty line for aesthetics
    hContrastColumnsFlow = most.gui.uiflowcontainer('Parent', contextImageImportFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    most.gui.staticText('Parent',hContrastColumnsFlow,'String','','WidthLimits',130);
    most.gui.staticText('Parent',hContrastColumnsFlow,'String','Threshold','WidthLimits',180);
    most.gui.staticText('Parent',hContrastColumnsFlow,'String','Value','WidthLimits',50);
    hContrastFlow = most.gui.uiflowcontainer('Parent', contextImageImportFlow,'FlowDirection','LeftToRight','HeightLimits', 55);
    contrastTextFlow = most.gui.uiflowcontainer('Parent', hContrastFlow,'FlowDirection','TopDown','margin',.0001,'WidthLimits',105);
    contrastForegroundFlow = most.gui.uiflowcontainer('Parent', contrastTextFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    most.gui.staticText('Parent',contrastForegroundFlow,'String','Foreground:','WidthLimits',60);
    obj.etPbCIFgThreshold = most.gui.uicontrol('Parent',contrastForegroundFlow,'style','edit','WidthLimits',40,'callback',@obj.updatePowerBoxContextImageThreshold);
    contrastBackgroundFlow = most.gui.uiflowcontainer('Parent', contrastTextFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    most.gui.staticText('Parent',contrastBackgroundFlow,'String','Background:','WidthLimits',60);
    obj.etPbCIBgThreshold = most.gui.uicontrol('Parent',contrastBackgroundFlow,'style','edit','WidthLimits',40,'callback',@obj.updatePowerBoxContextImageThreshold);

    contrastSliderFlow = most.gui.uiflowcontainer('Parent', hContrastFlow,'FlowDirection','TopDown','margin',.0001,'WidthLimits',110);
    most.gui.staticText('Parent',contrastSliderFlow,'String','','HeightLimits',8);
    obj.slPowerBoxContextImageThreshold = most.gui.constrastSlider('parent',contrastSliderFlow,'WidthLimits',[],'HeightLimits',36,...
        'min',0,'max',1,'Bindings',{obj,'pbCIThreshold'},'BackgroundColor',[0.94 0.94 0.94],'DarkColor',[0.3 0 0],'BrightColor',[0.9 0 0],'BorderColor',[0.2 0.2 0.2],'BarColorL',[0.5 0.25 0],'BarColorH',[0.7 0 0]);
    obj.slPowerBoxContextImageThreshold.callback = @obj.updatePowerBoxContextImageThreshold;

    contrastTextFlow = most.gui.uiflowcontainer('Parent', hContrastFlow,'FlowDirection','TopDown','margin',.0001,'WidthLimits',50);
    contrastForegroundFlow = most.gui.uiflowcontainer('Parent', contrastTextFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    obj.etPbCIFgValue = most.gui.uicontrol('Parent',contrastForegroundFlow,'style','edit','WidthLimits',40,'callback', @obj.updatePowerBoxContextImageValue);
    contrastBackgroundFlow = most.gui.uiflowcontainer('Parent', contrastTextFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    obj.etPbCIBgValue = most.gui.uicontrol('Parent',contrastBackgroundFlow,'style','edit','WidthLimits',40,'callback', @obj.updatePowerBoxContextImageValue);

    contrastSliderFlow = most.gui.uiflowcontainer('Parent', hContrastFlow,'FlowDirection','TopDown','margin',.0001,'WidthLimits',105);
    most.gui.staticText('Parent',contrastSliderFlow,'String','','HeightLimits',8);
    obj.slPowerBoxContextImageValue = most.gui.constrastSlider('parent',contrastSliderFlow,'WidthLimits',[],'HeightLimits',36,...
        'min',0,'max',1,'Bindings',{obj,'pbCIValue'},'BackgroundColor',[0.94 0.94 0.94],'DarkColor',[0 0 0],'BrightColor',[1 1 1],'BorderColor',[0.2 0.2 0.2],'BarColorL',[0.94 0.94 0.94],'BarColorH',[0.94 0.94 0.94]);
    obj.slPowerBoxContextImageValue.callback = @obj.updatePowerBoxContextImageValue;

    brushPanel = most.gui.uipanel('Parent', maskSettingsFlow, 'title', 'Brush Tool', 'HeightLimits', 116);
    brushPanelFlow = most.gui.uiflowcontainer('Parent', brushPanel,'FlowDirection','TopDown','margin',.0001);

    brushEnableFlow = most.gui.uiflowcontainer('Parent', brushPanelFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    obj.cbPowerBoxBrushEnable = most.gui.uicontrol('Parent',brushEnableFlow,'string', 'Enable Brush','style','checkbox','callback',@obj.setPowerBoxBrushEnable);

    brushValueFlow = most.gui.uiflowcontainer('Parent', brushPanelFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    most.gui.staticText('Parent',brushValueFlow,'String','Brush Value:','WidthLimits',90);
    obj.etPowerBoxBrushValue = most.gui.uicontrol('Parent',brushValueFlow,'style','edit','WidthLimits',40);
    obj.slPowerBoxBrushValue = most.gui.slider('parent',brushValueFlow,'max',1,'min',0);
    obj.slPowerBoxBrushValue.callback = @obj.centerPowerBoxBrushPreview;

    brushSizeFlow = most.gui.uiflowcontainer('Parent', brushPanelFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    most.gui.staticText('Parent',brushSizeFlow,'String','Brush Size:','WidthLimits',90);
    obj.etPowerBoxBrushSize = most.gui.uicontrol('Parent',brushSizeFlow,'style','edit','WidthLimits',40);
    obj.slPowerBoxBrushSize = most.gui.slider('parent',brushSizeFlow, 'max', 1, 'min', 0);
    obj.slPowerBoxBrushSize.callback = @obj.centerPowerBoxBrushPreview;

    pbEditExitFlow = most.gui.uiflowcontainer('Parent', obj.hSamplePowerBoxFlow,'FlowDirection','LeftToRight','HeightLimits', 24);
    most.gui.uicontrol('Parent',pbEditExitFlow,'String','Done','callback',@obj.finishPowerBoxEdit);
    most.gui.uicontrol('Parent',pbEditExitFlow,'String','Delete power box','callback',@obj.deletePowerBox);
    %% ROI Table and Controls
    obj.roiTable = most.gui.uitable(...
        'Parent',hRightFlow,...
        'FontUnits',get(0,'defaultuitableFontUnits'),...
        'Units','characters',...
        'BackgroundColor',get(0,'defaultuitableBackgroundColor'),...
        'ColumnName',{''; 'ID'; 'ROI Name/SF Type'; 'Time (ms)'; 'Enable'; 'Display'; 'Z [um]'},...
        'ColumnWidth',{ 20 28 120 59 43 45 58 },...
        'RowName','',...
        'Position',[1 4.3 54 10.9],...
        'ColumnEditable',[true false true true true true true],...
        'ColumnFormat',{'logical' 'char' 'char' 'char' 'char' 'char' 'char'},...
        'RearrangeableColumns','off',...
        'RowStriping','on',...
        'CellEditCallback',@obj.roiTableCB,...
        'ForegroundColor',get(0,'defaultuitableForegroundColor'),...
        'Tag','utSfTable',kpf{:});

    hRightFlow3 = most.gui.uiflowcontainer('Parent', hRightFlow, ...
        'FlowDirection','LeftToRight', ...
        'Margin',0.0001);
    hRightFlow3L = most.gui.uiflowcontainer('Parent', hRightFlow3,'FlowDirection','LeftToRight');
    hRightFlow3R = most.gui.uiflowcontainer('Parent', hRightFlow3,'FlowDirection','RightToLeft');
    set(hRightFlow3, 'HeightLimits', [30 30]);
    obj.pbNew = uicontrol('Parent',hRightFlow3L,'String','Add ROI...','callback',@obj.newRoi,kpf{:});
    obj.pbDel = uicontrol('Parent',hRightFlow3L,'String','Delete Selected','callback',@obj.delSelection,kpf{:});
    btArgs = {'Parent',hRightFlow3R,'FontName','Arial Unicode MS','FontSize',12,'FontWeight','Bold'};
    obj.pbMoveBottom = uicontrol(...
        btArgs{:},...
        'String', most.constants.Unicode.downwards_paired_arrow,...
        'callback',@(varargin)obj.moveButton(inf), ...
        kpf{:});
    obj.pbMoveDown = uicontrol( ...
        btArgs{:}, ...
        'String',most.constants.Unicode.downwards_arrow, ...
        'callback',@(varargin)obj.moveButton(1), ...
        kpf{:});
    obj.pbMoveUp = uicontrol( ...
        btArgs{:}, ...
        'String',most.constants.Unicode.upwards_arrow, ...
        'callback',@(varargin)obj.moveButton(-1), ...
        kpf{:});
    obj.pbMoveTop = uicontrol( ...
        btArgs{:}, ...
        'String',most.constants.Unicode.upwards_paired_arrow, ...
        'callback',@(varargin)obj.moveButton(-inf), ...
        kpf{:});
    set(obj.pbNew, 'WidthLimits', [80 80]);
    set(obj.pbDel, 'WidthLimits', [100 100]);
    set([obj.pbMoveTop obj.pbMoveUp obj.pbMoveDown obj.pbMoveBottom], 'WidthLimits', [30 30]);


    %% Find stim function options
    stimFunctionPackage = what('scanimage/mroi/stimulusfunctions');
    obj.stimFcnOptions = cellfun(@(mname)regexprep(mname,'\.m$',''), ...
        stimFunctionPackage.m, ...
        'UniformOutput',false);
    obj.slmScanOptions = setdiff(obj.stimFcnOptions, {'park' 'pause' 'waypoint'});

    for i = 1:numel(obj.stimFcnOptions)
        n = obj.stimFcnOptions{i};
        obj.stimFcnParamOptions.(n) = findParamOptions(fullfile(stimFunctionPackage.path, [n '.m']));
    end

    %% properties panel section
    obj.hBlankPanel = uipanel('Parent', hRightFlow);
    set(obj.hBlankPanel, 'HeightLimits', [200 200]);
    uicontrol('Parent',obj.hBlankPanel,'string','Select an item to view properties','units','normalized','position',[0 0.49 1 .1],'style','text','enable','off');

    createNewImRoiPropsPanel(obj,hRightFlow,kpf);
    createNewStimRoiPropsPanel(obj,hRightFlow,kpf);
    createNewAnalysisRoiPropsPanel(obj,hRightFlow,kpf);
    createImagingRoiPropsPanel(obj,hRightFlow,kpf);
    createGlobalImagingSfPropsPanel(obj,hRightFlow,kpf);
    createImagingSfPropsPanel(obj,hRightFlow,kpf);
    createStimRoiPropsPanel(obj,hRightFlow,kpf);
    createAnalysisRoiPropsPanel(obj,hRightFlow,kpf);
    createAnalysisSfPropsPanel(obj,hRightFlow,kpf);
    createStimOptimizationPanel(obj,hRightFlow,kpf);
    createStimQuickAddPanel(obj,hRightFlow,kpf);
    createSlmPropsPanel(obj,hRightFlow,kpf);

    %% main view area
    hLeftPanel = uipanel('Parent', hMainFlow);
    hLeftFlow = most.gui.uiflowcontainer('Parent', hLeftPanel,'FlowDirection','TopDown');

    %% 2D main view
    obj.h2DViewPanel = uipanel('Parent', hLeftFlow,'BorderType','None');
    c = most.constants.Colors.orange;
    obj.h2DProjectionViewAxes = most.idioms.axes('parent',obj.h2DViewPanel, ...
        'box','on', ...
        'Color',most.constants.Colors.black, ...
        'ydir','reverse', ...
        'XTick',[],'XTickLabel',[], ...
        'YTick',[],'YTickLabel',[], ...
        'ButtonDownFcn',@obj.zPan);
    obj.h2DProjectionViewTickAxes = most.idioms.axes('parent',obj.h2DViewPanel, ...
        'box','off', ...
        'Color','none', ...
        'YAxisLocation','right', ...
        'hittest','off', ...
        'ydir','reverse');
    xlabel(obj.h2DProjectionViewTickAxes,'X [um]');
    ylabel(obj.h2DProjectionViewTickAxes,'Sample Z [um]');
    obj.h2DScrollLine2 = line([-999999 999999],[0 0], ...
        'color',most.constants.Colors.white, ...
        'parent',obj.h2DProjectionViewAxes, ...
        'linewidth',3, ...
        'ButtonDownFcn',@obj.zScroll);

    obj.h2DImagingPlaneLines = line(nan,nan, ...
        'color',most.constants.Colors.white, ...
        'parent',obj.h2DProjectionViewAxes, ...
        'linewidth',1.5, ...
        'ButtonDownFcn',@obj.imagingPlaneLineBDF);
    obj.h2DFocusPlaneLine = line(nan, nan, ...
        'color', most.constants.Colors.red, ...
        'parent',obj.h2DProjectionViewAxes, ...
        'linewidth',1.5, ...
        'ButtonDownFcn',@obj.zScroll);

    obj.h2DMainViewTickAxes = most.idioms.axes('parent',obj.h2DViewPanel, ...
        'box','off', ...
        'Color','none', ...
        'ydir','reverse');
    xlabel(obj.h2DMainViewTickAxes,'X [um]');
    ylabel(obj.h2DMainViewTickAxes,'Y [um]');
    obj.h2DMainViewAxes = most.idioms.axes('parent',obj.h2DViewPanel, ...
        'box','on', ...
        'Color',most.constants.Colors.black, ...
        'GridColor',most.constants.Colors.lightGray, ...
        'XTickLabel',[],'YTickLabel',[], ...
        'ydir','reverse', ...
        'ButtonDownFcn',@obj.mainPan, ...
        'ALim',[0 1]);
    grid(obj.h2DMainViewAxes,'on');

    obj.h2DMainViewOutlineAxes = most.idioms.axes('parent',obj.h2DViewPanel, ...
        'box','on', ...
        'Color','none','xcolor',c,'ycolor',c, ...
        'linewidth',3,...
        'XTick',[],'XTickLabel',[], ...
        'YTick',[],'YTickLabel',[], ...
        'hittest','off');

    obj.h2DZScrollAxes = most.idioms.axes('parent',obj.h2DViewPanel, ...
        'Color','none', ...
        'XTickLabelMode','manual','XTickLabel',[], ...
        'YTickLabelMode','manual','YTickLabel',[],...
        'XColor','none','YColor','none', ...
        'ydir','reverse', ...
        'ylim',[-5 100],'xlim',[0 1], ...
        'ButtonDownFcn',@obj.zScroll);
    obj.h2DScrollPatch = patch(nan,nan,.25*c, ...
        'parent',obj.h2DZScrollAxes, ...
        'EdgeColor',c, ...
        'linewidth',3, ...
        'hittest','off');
    obj.h2DScrollLine1 = line([.8 1],[0 0], ...
        'color',c, ...
        'parent',obj.h2DZScrollAxes, ...
        'linewidth',3, ...
        'hittest','off');
    obj.h2DScrollKnob = line(.8,0, ...
        'color',c, ...
        'parent',obj.h2DZScrollAxes, ...
        'markersize',15, ...
        'Marker','>', ...
        'MarkerFaceColor',c, ...
        'hittest','off', ...
        'color',most.constants.Colors.black, ...
        'linewidth',2);
    obj.hZCursorTextRect = rectangle('Parent',obj.h2DZScrollAxes, ...
        'EdgeColor',c, ...
        'FaceColor',most.constants.Colors.black, ...
        'ButtonDownFcn',@(src,evt)obj.selectZDialog, ...
        'Clipping','off');
    obj.hZCursorText = text('Parent',obj.h2DZScrollAxes, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'Color',c, ...
        'HitTest','off', ...
        'PickableParts','none', ...
        'Clipping','off');

    obj.h2DScannerFovSurf = surface([0 1], [0 1], ones(2), ...
        'FaceColor','texturemap', ...
        'edgecolor',most.constants.Colors.yellow, ...
        'linewidth',.5, ...
        'linestyle',':', ...
        'parent',obj.h2DMainViewAxes, ...
        'hittest','off', ...
        'ButtonDownFcn',@obj.fovSurfHit, ...
        'FaceAlpha',0.5);
    obj.h2DScannerFovLines = [...
        line([0 0],[-999999 999999], ...
        'color',most.constants.Colors.yellow, ...
        'parent',obj.h2DProjectionViewAxes, ...
        'linewidth',.5, ...
        'linestyle',':', ...
        'hittest','off')...
        line([1 1],[-999999 999999], ...
        'color',most.constants.Colors.yellow, ...
        'parent',obj.h2DProjectionViewAxes, ...
        'linewidth',.5, ...
        'linestyle',':', ...
        'hittest','off')];
    obj.h2DScannerFovHandles = line(nan(8,1),nan(8,1),ones(8,1), ...
        'parent',obj.h2DMainViewAxes, ...
        'color',most.constants.Colors.yellow, ...
        'Marker','s','MarkerSize',10, ...
        'ButtonDownFcn',@obj.fovSurfHit, ...
        'visible','off');
    obj.h2DScannerFovZeroOrder = line(nan(20,1),nan(20,1),ones(20,1), ...
        'parent',obj.h2DMainViewAxes, ...
        'color',most.constants.Colors.yellow, ...
        'linestyle',':', ...
        'ButtonDownFcn',@obj.fovSurfHit, ...
        'visible','off');

    obj.hSnapLineX = line([0,0],[-999999 999999],2*ones(1,2), ...
        'parent',obj.h2DMainViewAxes, ...
        'color',most.constants.Colors.cyan, ...
        'linestyle',':', ...
        'visible','off', ...
        'linewidth',1);
    obj.hSnapLineY = line([-999999 999999],[0,0],2*ones(1,2), ...
        'parent',obj.h2DMainViewAxes, ...
        'color',most.constants.Colors.cyan, ...
        'linestyle',':', ...
        'visible','off', ...
        'linewidth',1);
    obj.hSnapLineR = line([0 0],[0,0],2*ones(1,2), ...
        'parent',obj.h2DMainViewAxes, ...
        'color',most.constants.Colors.cyan, ...
        'linestyle',':', ...
        'visible','off', ...
        'linewidth',1);

    obj.h2DViewPanel.SizeChangedFcn = @obj.p2DViewSize;
    obj.p2DViewSize();

    obj.hSelObjHandles{end+1} = line(0,0,1, ...
        'Parent',obj.h2DMainViewAxes, ...
        'LineStyle','none', ...
        'Marker', 'o', ...
        'MarkerEdgeColor', most.constants.Colors.green, ...
        'MarkerFaceColor',most.constants.Colors.darkGreen, ...
        'Markersize',8, ...
        'LineWidth',1.5, ...
        'visible','off', ...
        'ButtonDownFcn',@obj.roiManip, ...
        'UserData','size');
    obj.hSelObjHandles{end+1} = line(zeros(2,1),zeros(2,1),[5.5;5.5], ...
        'Parent',obj.h2DMainViewAxes, ...
        'LineStyle','--', ...
        'Marker','none',...
        'Color',[0 1 0], ...
        'Markersize',8, ...
        'LineWidth',1.5, ...
        'visible','off', ...
        'ButtonDownFcn',@obj.roiManip, ...
        'UserData','move');
    obj.hSelObjHandles{end+1} = line(0,0,1, ...
        'Parent',obj.h2DMainViewAxes, ...
        'LineStyle','none', ...
        'Marker','o', ...
        'MarkerEdgeColor',most.constants.Colors.green,...
        'MarkerFaceColor','none', ...
        'Markersize',8, ...
        'LineWidth',1.5, ...
        'visible','off', ...
        'ButtonDownFcn',@obj.roiManip, ...
        'UserData','rotate');

    %% 3d main view
    obj.h3DViewPanel = uipanel('Parent', hLeftFlow,'BorderType','None','backgroundcolor',most.constants.Colors.black);
    obj.h3DViewAxes = most.idioms.axes('parent',obj.h3DViewPanel,'color',most.constants.Colors.black,'PlotBoxAspectRatio', ones(1,3),'XColor',most.constants.Colors.white,'YColor',most.constants.Colors.white,'ZColor',most.constants.Colors.white,'Projection','perspective',...
        'box','on','ZDir','reverse','YDir','reverse','ButtonDownFcn',@obj.pan3DView);
    zlabel(obj.h3DViewAxes,'Sample Z [um]');
    grid(obj.h3DViewAxes,'on');
    camtarget(obj.h3DViewAxes,[.5 .5 0]);
    view(obj.h3DViewAxes,45,45);
    obj.h3DViewPanel.Visible = 'off';
    obj.h3DViewMouseFindAxes = most.idioms.axes('parent',obj.h3DViewPanel,'color','none','XColor','none','YColor','none','position',[0 0 1 1],'hittest','off');


    %% bottom area
    hBottomLeftFlow = most.gui.uiflowcontainer('Parent', hLeftFlow,'FlowDirection','LeftToRight');
    createBottomControlsPnl(obj,hBottomLeftFlow,kpf);

    %% legend
    hLegendContPanel = uipanel('Parent', hBottomLeftFlow, 'title', 'Layers/Legend');
    hLegendFlow = most.gui.uiflowcontainer('Parent', hLegendContPanel,'FlowDirection','LeftToRight');
    obj.hLegendScrollingPanel = uipanel('Parent',hLegendFlow,'bordertype','none','SizeChangedFcn',@obj.resizeLegend);
    obj.hLegendGrid = uigridcontainer('v0','Parent',obj.hLegendScrollingPanel,'Margin',0.0001);
    obj.slLegendScroll = most.gui.uicontrol('Parent',hLegendFlow,'style','slider','callback',@obj.legendScrl,'LiveUpdate',true,kpf{:});
    set(obj.slLegendScroll, 'WidthLimits', 18*ones(1,2));

    obj.editingGroup = scanimage.mroi.RoiGroup;
    obj.hPowerBoxDisplayManager = scanimage.guis.roigroupeditor.powerbox.powerBoxDisplayManager(obj);

    obj.initDone = true;
    obj.resetContextImages();

    %% init props
    if most.idioms.isValidObj(obj.hModel)
        obj.TileController = scanimage.guis.roigroupeditor.TileController(...
            obj, ...
            obj.hModel.hTileManager, ...
            obj.h2DMainViewAxes, ...
            obj.h2DProjectionViewAxes);

        obj.hSIListeners = [...
            addPostSetListener(obj.hModel.hStackManager, 'zs', @obj.updateZs), ...
            addPostSetListener(obj.hModel.hMotors, 'samplePosition', @obj.updateFocalPointZ), ...
            addEventListener(obj.hModel.hCoordinateSystems.hCSFocus, 'changed', @obj.updateFocalPointZ), ...
            addPostSetListener(obj.hModel, 'hScan2D', @obj.imagingSystemChange), ...
            addPostSetListener(obj.hModel.hRoiManager, 'scanFrameRate', @obj.frameRateUpdate)...
            addEventListener(obj.TileController, 'ViewSizeChanged', @(~,~)obj.updateMaxViewFov())...
            addEventListener(obj.TileController, 'ZProjectionsUpdated', @(~,~)obj.setZProjectionLimits())...
            ];
    end

    obj.defaultStimFunction = obj.defaultStimFunction;
    obj.editorMode = 'imaging';
    obj.scannerSet = obj.hModel.hScan2D.scannerset;
    obj.stagePos = nan;
    obj.editorZ = 0;
    obj.zProjectionRange = obj.zProjectionDefaultRange;
    obj.units = 'microns';
    obj.updateZs();
    obj.cellPickMode = obj.cellPickMode;

    obj.ensureClassDataFile(struct('lastFile','roigroup.roi'));
    obj.ensureClassDataFile(struct('lastSlmFile','slmPattern'));
end

function listener = addEventListener(model, event, callback)
    listener = most.ErrorHandler.addCatchingListener(model, event, callback);
end

function listener = addPostSetListener(model, property, callback)
    listener = most.ErrorHandler.addCatchingListener(model, property, 'PostSet', callback);
end

function options = findParamOptions(filename)
    options = {};
    try
        rows = strsplit(fileread(filename),'\n');

        sch = '%% parameter options:';
        n = length(sch);
        i = find(strncmp(rows,sch,n),1);
        if ~isempty(i)
            options = strtrim(strsplit(rows{i}(n+1:end),','));
        end
    catch
    end
end

function titleBar(parent,title)
    t = most.gui.staticText('parent',parent, ...
        'BackgroundColor',.4*ones(1,3), ...
        'string',title, ...
        'FontSize',10, ...
        'HorizontalAlignment', 'center');
    set(t.hPnl,'HeightLimits',20*ones(1,2));
    t.hTxt.FontWeight = 'bold';
    t.hTxt.Color = 'w';
end

function createGlobalImagingSfPropsPanel(obj,parent,kpf)
    obj.hGlobalImagingSfPropsPanel = uipanel('Parent', parent);
    set(obj.hGlobalImagingSfPropsPanel, 'HeightLimits', 170*ones(1,2));

    hf = most.gui.uiflowcontainer('Parent', obj.hGlobalImagingSfPropsPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(hf,'Global Scanfield Properties');

    cols = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 194*ones(1,2));

    up1 = uipanel('parent',col1,'title','Scanfield Position/Size');
    up = most.gui.uiflowcontainer('Parent', up1,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'centerXY',1,true,true));
    set(ctls.etCenterX, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'centerXY',2,true,true));
    set(ctls.etCenterY, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Width:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etWidth = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'sizeXY',1,true,false));
    ctls.cbWidthLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldWidth' 'value'},kpf{:});
    set(ctls.etWidth, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Height:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etHeight = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'sizeXY',2,true,false));
    ctls.cbHeightLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldHeight' 'value'},kpf{:});
    set(ctls.etHeight, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Rotation:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'rotation',1,false,false));
    set(ctls.etRotation, 'WidthLimits', 60*ones(1,2));


    up2 = uipanel('parent',col2,'title','Scanfield Resolution');
    up = most.gui.uiflowcontainer('Parent', up2,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Pixel Count X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.etPixCountX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'pixelResolutionXY',1,false,false));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Pixel Count Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.etPixCountY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'pixelResolutionXY',2,false,false));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stPixRatioX = most.gui.staticText('Parent',hf1,'String','Pixel Ratio [Pix/um] X:','HorizontalAlignment','right');
    set(ctls.stPixRatioX, 'WidthLimits', 120*ones(1,2));
    ctls.etPixRatioX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'pixelRatio',1,-1,false));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stPixRatioY = most.gui.staticText('Parent',hf1,'String','Pixel Ratio [Pix/um] Y:','HorizontalAlignment','right');
    set(ctls.stPixRatioY, 'WidthLimits', 120*ones(1,2));
    ctls.etPixRatioY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@(src,~)obj.globalPnlCallback(src,'pixelRatio',2,-1,false));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    most.gui.staticText('Parent',hf1,'String','Frame Rate:','HorizontalAlignment','right', 'WidthLimits', 60);
    ctls.etFrameRate = most.gui.uicontrol('Parent',hf1,'Style','edit','enable','inactive','BackgroundColor',.95*ones(1,3));

    set(up1, 'HeightLimits', 142*ones(1,2));
    set(up2, 'HeightLimits', 117*ones(1,2));

    obj.hGlobalImagingSfPropsPanelCtls = ctls;
    obj.hGlobalImagingSfPropsPanelCtls.all = {};
    obj.hGlobalImagingSfPropsPanelCtls.allFields = {};
    for n = fieldnames(ctls)'
        if strcmp(ctls.(n{1}).Style, 'edit')
            obj.hGlobalImagingSfPropsPanelCtls.allFields{end+1} = ctls.(n{1});
            obj.hGlobalImagingSfPropsPanelCtls.all{end+1} = ctls.(n{1});
        end
        if strcmp(ctls.(n{1}).Style, 'checkbox')
            obj.hGlobalImagingSfPropsPanelCtls.all{end+1} = ctls.(n{1});
        end
    end
    obj.hGlobalImagingSfPropsPanel.Visible = 'off';
end

function createImagingRoiPropsPanel(obj,parent,kpf)
    obj.hImagingRoiPropsPanel = uipanel('Parent', parent);
    set(obj.hImagingRoiPropsPanel, 'HeightLimits', 240*ones(1,2));
    hf = most.gui.uiflowcontainer('Parent', obj.hImagingRoiPropsPanel,'FlowDirection','TopDown','Margin',0.0001);

    titleBar(hf,'Selected ROI Properties');

    hf1 = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','ROI Name:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.etName = most.gui.uicontrol('Parent',hf1,'Style','Edit','HorizontalAlignment','left','callback',@obj.roiPropsPanelCtlCb,'tag','etName');

    hf1 = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Unique ID:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.etUUID = most.gui.uicontrol('Parent',hf1,'Style','Edit','enable','inactive','HorizontalAlignment','left','BackgroundColor',.95*ones(1,3));


    cols = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight','Margin',0.0001);
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 160*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Enabled:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.cbEnable = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','callback',@obj.roiPropsPanelCtlCb,'tag','cbEnable',kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Show In Image Display:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.cbDisplay = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','callback',@obj.roiPropsPanelCtlCb,'tag','cbDisplay',kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Discrete Plane Mode:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.cbDiscrete = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','callback',@obj.roiPropsPanelCtlCb,'tag','cbDiscrete',kpf{:});

    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Number of Scanfield Control Points:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 175*ones(1,2));
    ctls.etCPs = most.gui.uicontrol('Parent',hf1,'Style','Edit','HorizontalAlignment','left','enable','inactive','BackgroundColor',.95*ones(1,3));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','ROI Minimum Z [um]:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 175*ones(1,2));
    ctls.etZmin = most.gui.uicontrol('Parent',hf1,'Style','Edit','HorizontalAlignment','left','enable','inactive','BackgroundColor',.95*ones(1,3));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','ROI Maximum Z [um]:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 175*ones(1,2));
    ctls.etZmax = most.gui.uicontrol('Parent',hf1,'Style','Edit','HorizontalAlignment','left','enable','inactive','BackgroundColor',.95*ones(1,3));


    ctls.pbCreateSf = most.gui.uicontrol('Parent',col2,'String','Add ScanField at Current Z','callback',@obj.editOrCreateScanfieldAtZ,kpf{:});
    set(ctls.pbCreateSf, 'HeightLimits', 24*ones(1,2));


    hf1 = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');
    pp = uipanel('parent',hf1,'title','ROI Specific Power Controls');
    ppf = most.gui.uiflowcontainer('Parent', pp,'FlowDirection','LeftToRight','Margin',0.0001);
    ppfL = most.gui.uiflowcontainer('Parent', ppf,'FlowDirection','TopDown','Margin',0.0001);
    ppfR = most.gui.uiflowcontainer('Parent', ppf,'FlowDirection','TopDown','Margin',0.0001);

    ppf1 = most.gui.uiflowcontainer('Parent', ppfL,'FlowDirection','LeftToRight');
    set(ppf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',ppf1,'String','Powers%:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 100*ones(1,2));
    ctls.etPowers = most.gui.uicontrol('Parent',ppf1,'Style','Edit','HorizontalAlignment','left','callback',@obj.roiPropsPanelCtlCb,'tag','etPowers');

    ppf1 = most.gui.uiflowcontainer('Parent', ppfL,'FlowDirection','LeftToRight');
    set(ppf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',ppf1,'String','Enable P/z Adjust:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 100*ones(1,2));
    ctls.etPZ = most.gui.uicontrol('Parent',ppf1,'Style','Edit','HorizontalAlignment','left','callback',@obj.roiPropsPanelCtlCb,'tag','etPZ');

    ppf1 = most.gui.uiflowcontainer('Parent', ppfR,'FlowDirection','LeftToRight');
    set(ppf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',ppf1,'String','Length Constants:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 100*ones(1,2));
    ctls.etLzs = most.gui.uicontrol('Parent',ppf1,'Style','Edit','HorizontalAlignment','left','callback',@obj.roiPropsPanelCtlCb,'tag','etLzs');

    set(hf1, 'HeightLimits', 72*ones(1,2));

    obj.hImagingRoiPropsPanelCtls = ctls;
    obj.hImagingRoiPropsPanel.Visible = 'off';
end

function createImagingSfPropsPanel(obj,parent,kpf)
    obj.hImagingSfPropsPanel = uipanel('Parent', parent);
    set(obj.hImagingSfPropsPanel, 'HeightLimits', 208*ones(1,2));

    hf = most.gui.uiflowcontainer('Parent', obj.hImagingSfPropsPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(hf,'Selected Scanfield Properties');

    cols = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 194*ones(1,2));

    up1 = uipanel('parent',col1,'title','Scanfield Position/Size');
    up = most.gui.uiflowcontainer('Parent', up1,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Z:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etZ = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etZ');
    set(ctls.etZ, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etCenterX');
    set(ctls.etCenterX, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etCenterY');
    set(ctls.etCenterY, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Width:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etWidth = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etWidth');
    ctls.cbWidthLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldWidth' 'value'},kpf{:});
    set(ctls.etWidth, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Height:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etHeight = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etHeight');
    ctls.cbHeightLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldHeight' 'value'},kpf{:});
    set(ctls.etHeight, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Rotation:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etRotation');
    set(ctls.etRotation, 'WidthLimits', 60*ones(1,2));


    up2 = uipanel('parent',col2,'title','Scanfield Resolution');
    up = most.gui.uiflowcontainer('Parent', up2,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Pixel Count X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.etPixCountX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etPixCountX');

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Pixel Count Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.etPixCountY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etPixCountY');

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stPixRatioX = most.gui.staticText('Parent',hf1,'String','Pixel Ratio [Pix/um] X:','HorizontalAlignment','right');
    set(ctls.stPixRatioX, 'WidthLimits', 120*ones(1,2));
    ctls.etPixRatioX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etPixRatioX');

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stPixRatioY = most.gui.staticText('Parent',hf1,'String','Pixel Ratio [Pix/um] Y:','HorizontalAlignment','right');
    set(ctls.stPixRatioY, 'WidthLimits', 120*ones(1,2));
    ctls.etPixRatioY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.imSfPropsPanelCtlCb,'tag','etPixRatioY');

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','TopDown');
    nm = most.gui.staticText('Parent',hf1,'String','Resize Behavior:','HorizontalAlignment','left');
    set(nm, 'HeightLimits', 24*ones(1,2));
    ctls.rbMaintainPixCount = most.gui.uicontrol('Parent',hf1,'Style','radiobutton','string','Maintain Pixel Count','callback',@obj.imSfPropsPanelCtlCb,'tag','rbMaintainPixCount',kpf{:});
    ctls.rbMaintainPixRatio = most.gui.uicontrol('Parent',hf1,'Style','radiobutton','string','Maintain Pixel Ratio','callback',@obj.imSfPropsPanelCtlCb,'tag','rbMaintainPixRatio',kpf{:});

    set(up1, 'HeightLimits', 168*ones(1,2));
    set(up2, 'HeightLimits', 180*ones(1,2));

    obj.hImagingSfPropsPanelCtls = ctls;
    obj.hImagingSfPropsPanel.Visible = 'off';
    obj.scanfieldResizeMaintainPixelProp = 'count';
end

function createStimRoiPropsPanel(obj,parent,kpf)
    obj.hStimRoiPropsPanel = uipanel('Parent', parent);
    set(obj.hStimRoiPropsPanel, 'HeightLimits', 196*ones(1,2));

    hf = most.gui.uiflowcontainer('Parent', obj.hStimRoiPropsPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(hf,'Selected Stimulus Function Properties');

    cols = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 194*ones(1,2));

    up1 = uipanel('parent',col1,'title','Stimulus Position/Size');
    up = most.gui.uiflowcontainer('Parent', up1,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Z:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etZ = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etZ');
    set(ctls.etZ, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etCenterX');
    set(ctls.etCenterX, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etCenterY');
    set(ctls.etCenterY, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Width:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etWidth = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etWidth');
    ctls.cbWidthLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldWidth' 'value'},kpf{:});
    set(ctls.etWidth, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Height:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etHeight = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etHeight');
    ctls.cbHeightLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldHeight' 'value'},kpf{:});
    set(ctls.etHeight, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Rotation:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etRotation');
    set(ctls.etRotation, 'WidthLimits', 60*ones(1,2));


    ctls.paramPanel = most.gui.uipanel('parent',col2,'title','Stimulus Parameters');
    up = most.gui.uiflowcontainer('Parent', ctls.paramPanel,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Function:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 50*ones(1,2));
    ctls.pmFunction = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',obj.stimFcnOptions,'callback',@obj.stimRoiPropsPanelCtlCb,'tag','pmFunction',kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Fcn Args:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 50*ones(1,2));
    ctls.etArgs = most.gui.paramCellArrayEdit('Parent',hf1,'callback',@obj.stimRoiPropsPanelCtlCb,'tag','etArgs');

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Duration (ms):','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etDuration = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etDuration');
    set(ctls.etDuration, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Repetitions:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etReps = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etReps');
    set(ctls.etReps, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Beam Power%','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etPower = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.stimRoiPropsPanelCtlCb,'tag','etPower');
    set(ctls.etPower, 'WidthLimits', 40*ones(1,2));

    ctls.slmFlow = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight','HeightLimits', 24);
    most.gui.staticText('Parent',ctls.slmFlow,'String','SLM Pattern:','HorizontalAlignment','right','WidthLimits', 70);
    ctls.etPattern = most.gui.uicontrol('Parent',ctls.slmFlow,'Style','edit','ButtonDownFcn',@obj.editSlmPattern,'enable','inactive','BackgroundColor',.95*ones(1,3),'WidthLimits', 60);
    ctls.pbEditSlm = most.gui.uicontrol('Parent',ctls.slmFlow,'Callback',@obj.editOrClearSlmPattern,'string','Clear','WidthLimits', 40);


    set(up1, 'HeightLimits', 168*ones(1,2));
    set(ctls.paramPanel, 'HeightLimits', 164*ones(1,2));


    obj.hStimRoiPropsPanelCtls = ctls;
    obj.hStimRoiPropsPanel.Visible = 'off';
end

function createNewStimRoiPropsPanel(obj,parent,kpf)
    obj.hNewStimRoiPanel = uipanel('Parent', parent);
    set(obj.hNewStimRoiPanel, 'HeightLimits', 240*ones(1,2));

    flw = most.gui.uiflowcontainer('Parent',obj.hNewStimRoiPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(flw,'New Stimulus Function');

    topStuff = most.gui.uiflowcontainer('Parent',flw,'FlowDirection','TopDown','Margin',0.0001);
    botStuff = most.gui.uiflowcontainer('Parent',flw,'FlowDirection','BottomUp','Margin',0.0001);


    topRow = most.gui.uiflowcontainer('Parent', topStuff,'FlowDirection','LeftToRight');
    set(topRow, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',topRow,'String','Draw By:','HorizontalAlignment','left');
    set(nm, 'WidthLimits', 50*ones(1,2));
    ctls.rbTopLeftRect = most.gui.uicontrol('Parent',topRow,'Style','radiobutton','string','Top Left Rectangle','callback',@(varargin)set(obj,'newRoiDrawMode','top left rectangle'),kpf{:});
    ctls.rbCenterPtRect = most.gui.uicontrol('Parent',topRow,'Style','radiobutton','string','Center Point Rectangle','callback',@(varargin)set(obj,'newRoiDrawMode','center point rectangle'),kpf{:});
    ctls.rbCellPick = most.gui.uicontrol('Parent',topRow,'Style','radiobutton','string','Cell Picker','callback',@(varargin)set(obj,'newRoiDrawMode','cell picker'),kpf{:});
    set(ctls.rbTopLeftRect, 'WidthLimits', 115*ones(1,2));
    set(ctls.rbCenterPtRect, 'WidthLimits', 135*ones(1,2));
    set(ctls.rbCellPick, 'WidthLimits', 70*ones(1,2));



    botRow = most.gui.uiflowcontainer('Parent', botStuff,'FlowDirection','LeftToRight','Margin',0.0001);
    botRowL = most.gui.uiflowcontainer('Parent', botRow,'FlowDirection','LeftToRight');
    set(botRowL, 'WidthLimits', 160*ones(1,2));
    botRowR = most.gui.uiflowcontainer('Parent', botRow,'FlowDirection','RightToLeft');
    set(botStuff, 'HeightLimits', 28*ones(1,2));
    ctls.stDraw = most.gui.staticText('Parent',botRowL,'String','   Draw new ROI...','HorizontalAlignment','left','FontWeight','bold','FontSize',12);
    ctl = most.gui.uicontrol('Parent',botRowR,'string','Cancel','callback',@obj.newRoiPropsPanelCtlCb,'tag','pbCancel');
    set(ctl, 'WidthLimits', 70*ones(1,2));
    ctls.pbCreate = most.gui.uicontrol('Parent',botRowR,'string','Create Using Defaults','callback',@obj.newRoiPropsPanelCtlCb,'tag','pbCreateDefault');
    set(ctls.pbCreate, 'WidthLimits', 140*ones(1,2));



    cols = most.gui.uiflowcontainer('Parent', topStuff,'FlowDirection','LeftToRight');
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 194*ones(1,2));

    up1 = uipanel('parent',col1,'title','Default Stimulus Position/Size');
    up = most.gui.uiflowcontainer('Parent', up1,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterX = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etCenterX','callback',@obj.newRoiPropsPanelCtlCb);
    set(ctls.etCenterX, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterY = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etCenterY','callback',@obj.newRoiPropsPanelCtlCb);
    set(ctls.etCenterY, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Width:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etWidth = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etWidth','callback',@obj.newRoiPropsPanelCtlCb);
    ctls.cbWidthLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldWidth' 'value'},kpf{:});
    set(ctls.etWidth, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Height:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etHeight = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etHeight','callback',@obj.newRoiPropsPanelCtlCb);
    ctls.cbHeightLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldHeight' 'value'},kpf{:});
    set(ctls.etHeight, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Rotation:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    %ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'defaultRoiRotation' 'value'});
    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.newRoiPropsPanelCtlCb,'tag','etRotation');
    set(ctls.etRotation, 'WidthLimits', 60*ones(1,2));



    upCp = uipanel('parent',col1,'bordertype','none');
    up = most.gui.uiflowcontainer('Parent', upCp,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Selection Mode:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 84*ones(1,2));
    ctls.pmSelMode = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',[obj.cellPickModes {'Custom...'}],'Bindings',{obj 'cellPickMode' 'choice'},kpf{:});

    upSel = uipanel('parent',up,'title','Selected Cell');
    set(upSel, 'HeightLimits', 42*ones(1,2));
    upf = most.gui.uiflowcontainer('Parent', upSel,'FlowDirection','LeftToRight');
    ctls.pbDilate = uicontrol('Parent',upf,'string','Dilate','enable','off','callback',@obj.pbDilateCell,kpf{:});
    ctls.pbErode = uicontrol('Parent',upf,'string','Erode','enable','off','callback',@obj.pbErodeCell,kpf{:});
    ctls.pbDelete = uicontrol('Parent',upf,'string','Delete','enable','off','callback',@obj.pbDeleteCell,kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Pause between stims (ms):','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 135*ones(1,2));
    ctls.etPause = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'cellPickPauseDuration' 'Value'});
    set(ctls.etPause, 'WidthLimits', 50*ones(1,2));


    up2 = uipanel('parent',col2,'title','Default Stimulus Parameters');
    up = most.gui.uiflowcontainer('Parent', up2,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Function:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 50*ones(1,2));
    ctls.pmFunction = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',obj.stimFcnOptions,'Bindings',{obj 'defaultStimFunction' 'Choice'},kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Fcn Args:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 50*ones(1,2));
    ctls.etArgs = most.gui.paramCellArrayEdit('Parent',hf1,'Bindings',{obj 'defaultStimFunctionArgs'});

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Duration (ms):','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etDuration = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'defaultStimDuration' 'Value'});
    set(ctls.etDuration, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Repetitions:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etReps = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'defaultStimRepetitions' 'Value'});
    set(ctls.etReps, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Beam Power%','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etPower = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'defaultStimPower' 'Value'});
    set(ctls.etPower, 'WidthLimits', 40*ones(1,2));

    set(up1, 'HeightLimits', 141*ones(1,2));
    set(up2, 'HeightLimits', 141*ones(1,2));

    ctls.cbDrawMultiple = most.gui.uicontrol('Parent',col2,'Style','Checkbox','string','Draw Multiple','Bindings',{obj 'drawMultipleRois' 'value'},kpf{:});


    ctls.rectCtls = up1;
    ctls.cellCtls = upCp;
    obj.hNewStimRoiPanelCtls = ctls;
    obj.hNewStimRoiPanel.Visible = 'off';
end

function createAnalysisRoiPropsPanel(obj,parent,kpf)
    obj.hAnalysisRoiPropsPanel = uipanel('Parent', parent);
    set(obj.hAnalysisRoiPropsPanel, 'HeightLimits', 197*ones(1,2));
    hf = most.gui.uiflowcontainer('Parent', obj.hAnalysisRoiPropsPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(hf,'Selected ROI Properties');

    hf1 = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','ROI Name:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 65*ones(1,2));
    ctls.etName = most.gui.uicontrol('Parent',hf1,'Style','Edit','HorizontalAlignment','left','callback',@obj.analysisRoiPropsPanelCtlCb,'tag','etName');

    hf1 = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Unique ID:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 65*ones(1,2));
    ctls.etUUID = most.gui.uicontrol('Parent',hf1,'Style','Edit','enable','inactive','HorizontalAlignment','left','BackgroundColor',.95*ones(1,3));


    cols = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight','Margin',0.0001);
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 220*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Enabled:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 175*ones(1,2));
    ctls.cbEnable = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','callback',@obj.analysisRoiPropsPanelCtlCb,'tag','cbEnable',kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Show In Integration Display:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 175*ones(1,2));
    ctls.cbDisplay = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','callback',@obj.analysisRoiPropsPanelCtlCb,'tag','cbDisplay',kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Discrete Plane Mode:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 175*ones(1,2));
    ctls.cbDiscrete = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','callback',@obj.analysisRoiPropsPanelCtlCb,'tag','cbDiscrete',kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Number of Scanfield Control Points:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 175*ones(1,2));
    ctls.etCPs = most.gui.uicontrol('Parent',hf1,'Style','Edit','HorizontalAlignment','left','enable','inactive','BackgroundColor',.95*ones(1,3));

    ctls.pbCreateSf = most.gui.uicontrol('Parent',col1,'String','Create ScanField at Current Z','callback',@obj.editOrCreateScanfieldAtZ,kpf{:});
    set(ctls.pbCreateSf, 'HeightLimits', 24*ones(1,2));


    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Channel:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.pmChannel = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',{'1' '2' '3' '4'},'callback',@obj.analysisRoiPropsPanelCtlCb,'tag','pmChannel',kpf{:});
    set(ctls.pmChannel, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Threshold:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etThreshold = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.analysisRoiPropsPanelCtlCb,'tag','etThreshold','Enable','off');
    set(ctls.etThreshold, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Processor:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.pmProcessor = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',{'CPU' 'FPGA'},'callback',@obj.analysisRoiPropsPanelCtlCb,'tag','pmProcessor','Enable','off',kpf{:});
    set(ctls.pmProcessor, 'WidthLimits', 60*ones(1,2));


    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','ROI Minimum Z [um]:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.etZmin = most.gui.uicontrol('Parent',hf1,'Style','Edit','HorizontalAlignment','left','enable','inactive','BackgroundColor',.95*ones(1,3));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','ROI Maximum Z [um]:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 120*ones(1,2));
    ctls.etZmax = most.gui.uicontrol('Parent',hf1,'Style','Edit','HorizontalAlignment','left','enable','inactive','BackgroundColor',.95*ones(1,3));

    obj.hAnalysisRoiPropsPanelCtls = ctls;
    obj.hAnalysisRoiPropsPanel.Visible = 'off';
end

function createAnalysisSfPropsPanel(obj,parent,kpf)
    obj.hAnalysisSfPropsPanel = uipanel('Parent', parent);
    set(obj.hAnalysisSfPropsPanel, 'HeightLimits', 148*ones(1,2));

    hf = most.gui.uiflowcontainer('Parent', obj.hAnalysisSfPropsPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(hf,'Selected Scanfield Properties');

    uu = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','TopDown');

    up1 = uipanel('parent',uu,'title','Analysis ROI Position/Size');

    cols = most.gui.uiflowcontainer('Parent', up1,'FlowDirection','LeftToRight');
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 180*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Z:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 90*ones(1,2));
    ctls.etZ = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.analysisSfPropsPanelCtlCb,'tag','etZ');
    set(ctls.etZ, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 90*ones(1,2));
    ctls.etCenterX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.analysisSfPropsPanelCtlCb,'tag','etCenterX');
    set(ctls.etCenterX, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 90*ones(1,2));
    ctls.etCenterY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.analysisSfPropsPanelCtlCb,'tag','etCenterY');
    set(ctls.etCenterY, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Width:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etWidth = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.analysisSfPropsPanelCtlCb,'tag','etWidth');
    ctls.cbWidthLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldWidth' 'value'},kpf{:});
    set(ctls.etWidth, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Height:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etHeight = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.analysisSfPropsPanelCtlCb,'tag','etHeight');
    ctls.cbHeightLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldHeight' 'value'},kpf{:});
    set(ctls.etHeight, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Rotation:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.analysisSfPropsPanelCtlCb,'tag','etRotation');
    set(ctls.etRotation, 'WidthLimits', 60*ones(1,2));


    hf1 = most.gui.uiflowcontainer('Parent', uu,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Mask:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 30*ones(1,2));
    ctls.etMask = most.gui.uicontrol('Parent',hf1,'Style','edit','HorizontalAlignment','left','callback',@obj.analysisSfPropsPanelCtlCb,'tag','etMask');
    clr = most.gui.uicontrol('Parent',hf1,'String','Clear','callback',@obj.analysisSfPropsPanelCtlCb,'tag','pbClearMask',kpf{:});
    set(clr, 'WidthLimits', 50*ones(1,2));

    obj.hAnalysisSfPropsPanelCtls = ctls;
    obj.hAnalysisSfPropsPanel.Visible = 'off';
end

function createNewAnalysisRoiPropsPanel(obj,parent,kpf)
    obj.hNewAnalysisRoiPanel = uipanel('Parent', parent);
    set(obj.hNewAnalysisRoiPanel, 'HeightLimits', 220*ones(1,2));

    flw = most.gui.uiflowcontainer('Parent',obj.hNewAnalysisRoiPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(flw,'New ROI');

    topStuff = most.gui.uiflowcontainer('Parent',flw,'FlowDirection','TopDown','Margin',0.0001);
    botStuff = most.gui.uiflowcontainer('Parent',flw,'FlowDirection','BottomUp','Margin',0.0001);


    topRow = most.gui.uiflowcontainer('Parent', topStuff,'FlowDirection','LeftToRight');
    set(topRow, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',topRow,'String','Draw By:','HorizontalAlignment','left');
    set(nm, 'WidthLimits', 50*ones(1,2));
    ctls.rbTopLeftRect = most.gui.uicontrol('Parent',topRow,'Style','radiobutton','string','Top Left Rectangle','callback',@(varargin)set(obj,'newRoiDrawMode','top left rectangle'),kpf{:});
    ctls.rbCenterPtRect = most.gui.uicontrol('Parent',topRow,'Style','radiobutton','string','Center Point Rectangle','callback',@(varargin)set(obj,'newRoiDrawMode','center point rectangle'),kpf{:});
    ctls.rbCellPick = most.gui.uicontrol('Parent',topRow,'Style','radiobutton','string','Cell Picker','callback',@(varargin)set(obj,'newRoiDrawMode','cell picker'),kpf{:});
    set(ctls.rbTopLeftRect, 'WidthLimits', 115*ones(1,2));
    set(ctls.rbCenterPtRect, 'WidthLimits', 135*ones(1,2));
    set(ctls.rbCellPick, 'WidthLimits', 70*ones(1,2));



    botRow = most.gui.uiflowcontainer('Parent', botStuff,'FlowDirection','LeftToRight','Margin',0.0001);
    botRowL = most.gui.uiflowcontainer('Parent', botRow,'FlowDirection','LeftToRight');
    set(botRowL, 'WidthLimits', 160*ones(1,2));
    botRowR = most.gui.uiflowcontainer('Parent', botRow,'FlowDirection','RightToLeft');
    set(botStuff, 'HeightLimits', 28*ones(1,2));
    ctls.stDraw = most.gui.staticText('Parent',botRowL,'String','   Draw new ROI...','HorizontalAlignment','left','FontWeight','bold','FontSize',12);
    ctl = most.gui.uicontrol('Parent',botRowR,'string','Cancel','callback',@obj.newRoiPropsPanelCtlCb,'tag','pbCancel',kpf{:});
    set(ctl, 'WidthLimits', 70*ones(1,2));
    ctls.pbCreate = most.gui.uicontrol('Parent',botRowR,'string','Create Using Defaults','callback',@obj.newRoiPropsPanelCtlCb,'tag','pbCreateDefault',kpf{:});
    set(ctls.pbCreate, 'WidthLimits', 140*ones(1,2));



    cols = most.gui.uiflowcontainer('Parent', topStuff,'FlowDirection','LeftToRight');
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 194*ones(1,2));

    up1 = uipanel('parent',col1,'title','Default Stimulus Position/Size');
    up = most.gui.uiflowcontainer('Parent', up1,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterX = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etCenterX','callback',@obj.newRoiPropsPanelCtlCb);
    set(ctls.etCenterX, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterY = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etCenterY','callback',@obj.newRoiPropsPanelCtlCb);
    set(ctls.etCenterY, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Width:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etWidth = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etWidth','callback',@obj.newRoiPropsPanelCtlCb);
    ctls.cbWidthLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldWidth' 'value'},kpf{:});
    set(ctls.etWidth, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Height:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etHeight = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etHeight','callback',@obj.newRoiPropsPanelCtlCb);
    ctls.cbHeightLock = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Lock','Bindings',{obj 'lockScanfieldHeight' 'value'},kpf{:});
    set(ctls.etHeight, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Rotation:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    %    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'defaultRoiRotation' 'value'});
    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit', 'callback',@obj.newRoiPropsPanelCtlCb,'tag','etRotation');
    set(ctls.etRotation, 'WidthLimits', 60*ones(1,2));



    upCp = uipanel('parent',col1,'bordertype','none');
    up = most.gui.uiflowcontainer('Parent', upCp,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Selection Mode:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 84*ones(1,2));
    ctls.pmSelMode = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',[obj.cellPickModes {'Custom...'}],'Bindings',{obj 'cellPickMode' 'choice'},kpf{:});

    upSel = uipanel('parent',up,'title','Selected Cell');
    set(upSel, 'HeightLimits', 42*ones(1,2));
    upf = most.gui.uiflowcontainer('Parent', upSel,'FlowDirection','LeftToRight');
    ctls.pbDilate = uicontrol('Parent',upf,'string','Dilate','enable','off','callback',@obj.pbDilateCell,kpf{:});
    ctls.pbErode = uicontrol('Parent',upf,'string','Erode','enable','off','callback',@obj.pbErodeCell,kpf{:});
    ctls.pbDelete = uicontrol('Parent',upf,'string','Delete','enable','off','callback',@obj.pbDeleteCell,kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stMargin = most.gui.staticText('Parent',hf1,'String','ROI Margin [um]:','HorizontalAlignment','right');
    set(ctls.stMargin, 'WidthLimits', 90*ones(1,2));
    ctls.etMargin = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etMargin','callback',@obj.newRoiPropsPanelCtlCb);
    set(ctls.etMargin, 'WidthLimits', 60*ones(1,2));

    ctls.cbCreateDiscrete = most.gui.uicontrol('Parent',up,'Style','Checkbox','string','Create as discrete plane ROI','Bindings',{obj 'cellPickCreateAsDiscrete' 'Value'},kpf{:});
    set(ctls.cbCreateDiscrete, 'HeightLimits', 24*ones(1,2));

    ctls.cbCreateDiscrete = most.gui.uicontrol('Parent',up,'Style','Checkbox','string','Create with mask','Bindings',{obj 'cellPickCreateWithMask' 'Value'},kpf{:});
    set(ctls.cbCreateDiscrete, 'HeightLimits', 24*ones(1,2));


    up2 = uipanel('parent',col2,'title','Default Analysis Parameters');
    up = most.gui.uiflowcontainer('Parent', up2,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Channel:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.pmChannel = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',{'1' '2' '3' '4'},'Bindings',{obj 'defaultAnalysisRoiChannel' 'Value'},kpf{:});
    set(ctls.pmChannel, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Threshold:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etThreshold = most.gui.uicontrol('Parent',hf1,'Style','edit','Enable','off','Bindings',{obj 'defaultAnalysisRoiThreshold' 'Value'});
    set(ctls.etThreshold, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Processor:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.pmProcessor = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',{'CPU' 'FPGA'},'Bindings',{obj 'defaultAnalysisRoiProcessor' 'choice'},'Enable','off',kpf{:});
    set(ctls.pmProcessor, 'WidthLimits', 60*ones(1,2));

    set(up1, 'HeightLimits', 141*ones(1,2));
    set(up2, 'HeightLimits', 94*ones(1,2));

    ctls.cbDrawMultiple = most.gui.uicontrol('Parent',col2,'Style','Checkbox','string','Draw Multiple','Bindings',{obj 'drawMultipleRois' 'value'},kpf{:});

    ctls.rectCtls = up1;
    ctls.cellCtls = upCp;
    obj.hNewAnalysisRoiPanelCtls = ctls;
    obj.hNewAnalysisRoiPanel.Visible = 'off';
    obj.newRoiDrawMode = 'top left rectangle';
end

function createBottomControlsPnl(obj,parent,kpf)
    set(parent, 'HeightLimits', 124*ones(1,2));

    hViewPropsFlow = most.gui.uiflowcontainer('Parent', parent,'FlowDirection','TopDown','Margin',0.0001);
    set(hViewPropsFlow, 'WidthLimits', 356*ones(1,2));

    % gap
    hg = uipanel('parent',hViewPropsFlow,'bordertype','none');
    set(hg, 'HeightLimits', 12*ones(1,2));

    hViewPropsTopFlow = most.gui.uiflowcontainer('Parent', hViewPropsFlow,'FlowDirection','LeftToRight','Margin',0.0001);
    set(hViewPropsTopFlow, 'HeightLimits', [24 24]);

    gap = most.gui.staticText('Parent',hViewPropsTopFlow,'String','');
    set(gap, 'WidthLimits', 10*ones(1,2));

    nm = most.gui.staticText('Parent',hViewPropsTopFlow,'String','Z plane:');
    set(nm, 'WidthLimits', 44*ones(1,2));
    %zctl = most.gui.uicontrol('Parent',hViewPropsTopFlow,'Style','Edit','HorizontalAlignment','center','Bindings',{obj 'editorZ' 'value'});
    obj.hZPlaneCtl = most.gui.uicontrol('Parent',hViewPropsTopFlow,'Style','Edit','HorizontalAlignment','center','callback',@obj.zPlaneCtlCb,'tag','etZPlane');
    set(obj.hZPlaneCtl, 'WidthLimits', [40 40]);
    set(obj.hZPlaneCtl, 'String', num2str(obj.editorZ));

    gap = most.gui.staticText('Parent',hViewPropsTopFlow,'String','');
    set(gap, 'WidthLimits', 12*ones(1,2));

    nm = most.gui.staticText('Parent',hViewPropsTopFlow,'String','View:');
    set(nm, 'WidthLimits', 30*ones(1,2));
    obj.tbViewMode2D = uicontrol('Parent',hViewPropsTopFlow,'String','2D','value',true,'style','togglebutton','callback',@(varargin)set(obj,'viewMode','2D'),kpf{:});
    obj.tbViewMode3D = uicontrol('Parent',hViewPropsTopFlow,'String','3D','value',false,'style','togglebutton','callback',@(varargin)set(obj,'viewMode','3D'),kpf{:});
    set([obj.tbViewMode2D obj.tbViewMode3D], 'WidthLimits', 36*ones(1,2));

    gap = most.gui.staticText('Parent',hViewPropsTopFlow,'String','');
    set(gap, 'WidthLimits', 12*ones(1,2));

    nm = most.gui.staticText('Parent',hViewPropsTopFlow,'String','Projection:');
    set(nm, 'WidthLimits', 50*ones(1,2));
    obj.tbProjectionModeXZ = uicontrol('Parent',hViewPropsTopFlow,'String','XZ','value',true,'style','togglebutton','callback',@(varargin)set(obj,'projectionMode','XZ'),kpf{:});
    obj.tbProjectionModeYZ = uicontrol('Parent',hViewPropsTopFlow,'String','YZ ','value',false,'style','togglebutton','callback',@(varargin)set(obj,'projectionMode','YZ'),kpf{:});
    set([obj.tbProjectionModeXZ obj.tbProjectionModeYZ], 'WidthLimits', 36*ones(1,2));


    % gap
    hg = uipanel('parent',hViewPropsFlow,'bordertype','none');
    set(hg, 'HeightLimits', 12*ones(1,2));

    %% display units section
    hViewPropsBottomFlow = most.gui.uiflowcontainer('Parent', hViewPropsFlow,'FlowDirection','LeftToRight');
    up = uipanel('parent',hViewPropsBottomFlow,'title','XY Display Units');
    set(up, 'WidthLimits', 148*ones(1,2));
    set(up, 'HeightLimits', 72*ones(1,2));
    hUnitPanelFlow = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight','Margin',0.0001);

    % gap
    hg = uipanel('parent',hUnitPanelFlow,'bordertype','none');
    set(hg, 'WidthLimits', 6*ones(1,2));

    hUnitPanelLeftFlow = most.gui.uiflowcontainer('Parent', hUnitPanelFlow,'FlowDirection','TopDown');
    set(hUnitPanelLeftFlow, 'WidthLimits', 140*ones(1,2));
    obj.pbUnitsUM = most.gui.uicontrol('Parent',hUnitPanelLeftFlow,'String','Microns','value',true,'style','radiobutton','Bindings',{obj 'units' 'match' 'microns'},kpf{:});
    obj.pbUnitsSA = most.gui.uicontrol('Parent',hUnitPanelLeftFlow,'String','Scan Angle (Degrees)','value',false,'style','radiobutton','Bindings',{obj 'units' 'match' 'degrees'},kpf{:});
    set([obj.pbUnitsUM.hCtl obj.pbUnitsSA.hCtl], 'HeightLimits', 22*ones(1,2));

    %% stage position section
    hUnitPanelRightFlow = most.gui.uiflowcontainer('Parent', hViewPropsBottomFlow,'FlowDirection','TopDown');
    nm = most.gui.staticText('Parent',hUnitPanelRightFlow,'String','Stage Position:');
    set(nm, 'WidthLimits', 76*ones(1,2));
    set(nm, 'HeightLimits', 20*ones(1,2));
    sp = most.gui.uicontrol('Parent',hUnitPanelRightFlow,'String','[0.0, 0.0, 0.0]','style','edit','enable','inactive','BackgroundColor',.95*ones(1,3),'Bindings',{obj 'stagePos' 'string'});
    set(sp, 'HeightLimits', 20*ones(1,2));
    set(sp, 'WidthLimits', 198*ones(1,2));
    hUnitPanelRightButtonFlow = most.gui.uiflowcontainer('Parent', hUnitPanelRightFlow,'FlowDirection','LeftToRight','Margin',0.0001, 'HeightLimits', 26);
    upb = uicontrol('Parent',hUnitPanelRightButtonFlow,'String','Update','callback',@(varargin)obj.set('stagePos', nan),kpf{:});
    set(upb, 'WidthLimits', 56*ones(1,2));
    set(upb, 'HeightLimits', 22*ones(1,2));
end

function createStimOptimizationPanel(obj,parent,kpf)
    obj.hStimOptimizationPanel = uipanel('Parent', parent);
    set(obj.hStimOptimizationPanel, 'HeightLimits', 128*ones(1,2));

    hf = most.gui.uiflowcontainer('Parent', obj.hStimOptimizationPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(hf,'Scan Path Optimization');

    mainFlow = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight','Margin',0.0001);
    leftFlow = most.gui.uiflowcontainer('Parent', mainFlow,'FlowDirection','TopDown','Margin',0.0001);
    rightFlow = most.gui.uiflowcontainer('Parent', mainFlow,'FlowDirection','TopDown','Margin',0.0001);


    xyFlow1 = most.gui.uiflowcontainer('Parent', leftFlow,'FlowDirection','LeftToRight');
    set(xyFlow1, 'HeightLimits', 22*ones(1,2));
    ctls.stXYMaxVel = most.gui.staticText('Parent',xyFlow1,'String','XY Max Velocity [deg/ms]:','HorizontalAlignment','right');
    set(ctls.stXYMaxVel, 'WidthLimits', 142*ones(1,2));
    ctl = most.gui.uicontrol('parent',xyFlow1,'style','edit','Bindings',{obj 'xyMaxVel' 'Value' '%f' 'scaling' 1e-3});
    set(ctl, 'WidthLimits', 40*ones(1,2));

    xyFlow2 = most.gui.uiflowcontainer('Parent', rightFlow,'FlowDirection','LeftToRight');
    set(xyFlow2, 'HeightLimits', 22*ones(1,2));
    ctls.stXYMaxAccel = most.gui.staticText('Parent',xyFlow2,'String','XY Max Accel. [deg/ms]:','HorizontalAlignment','right');
    set(ctls.stXYMaxAccel, 'WidthLimits', 142*ones(1,2));
    ctl = most.gui.uicontrol('parent',xyFlow2,'style','edit','Bindings',{obj 'xyMaxAccel' 'Value' '%f' 'scaling' 1e-6});
    set(ctl, 'WidthLimits', 40*ones(1,2));


    zFlow1 = most.gui.uiflowcontainer('Parent', leftFlow,'FlowDirection','LeftToRight');
    set(zFlow1, 'HeightLimits', 22*ones(1,2));
    ctls.stZMaxVel = most.gui.staticText('Parent',zFlow1,'String','Z Max Velocity [um/ms]:','HorizontalAlignment','right');
    set(ctls.stZMaxVel, 'WidthLimits', 142*ones(1,2));
    ctl = most.gui.uicontrol('parent',zFlow1,'style','edit','Bindings',{obj 'zMaxVel' 'Value' '%f' 'scaling' 1e-3});
    set(ctl, 'WidthLimits', 40*ones(1,2));

    zFlow2 = most.gui.uiflowcontainer('Parent', rightFlow,'FlowDirection','LeftToRight');
    set(zFlow2, 'HeightLimits', 22*ones(1,2));
    ctls.stZMaxAccel = most.gui.staticText('Parent',zFlow2,'String','Z Max Accel. [um/ms]:','HorizontalAlignment','right');
    set(ctls.stZMaxAccel, 'WidthLimits', 142*ones(1,2));
    ctl = most.gui.uicontrol('parent',zFlow2,'style','edit','Bindings',{obj 'zMaxAccel' 'Value' '%f' 'scaling' 1e-6});
    set(ctl, 'WidthLimits', 40*ones(1,2));

    leftBottomFlow = most.gui.uiflowcontainer('Parent', leftFlow,'FlowDirection','TopDown','Margin',6);
    most.gui.uicontrol('parent',leftBottomFlow,'style','checkbox','string','Optimize Transition Durations','Bindings',{obj 'optimizeTransitions' 'Value'});
    most.gui.uicontrol('parent',leftBottomFlow,'style','checkbox','string','Optimize Stimulation Durations','Bindings',{obj 'optimizeStimuli' 'Value'});

    rightBottomFlow = most.gui.uiflowcontainer('Parent', rightFlow,'FlowDirection','BottomUp');
    hg = uipanel('parent',rightBottomFlow,'bordertype','none');
    set(hg, 'HeightLimits', 3*ones(1,2));
    b = most.gui.uicontrol('parent',rightBottomFlow,'string','Optimize Now','callback',@(varargin)obj.optimizePath);
    set(b.hCtl, 'WidthLimits', 188*ones(1,2));
    set(b.hCtl, 'HeightLimits', 28*ones(1,2));

    obj.hStimOptimizationPanelCtls = ctls;
end

function createStimQuickAddPanel(obj,parent,kpf)
    obj.hStimQuickAddPanel = uipanel('Parent', parent);
    set(obj.hStimQuickAddPanel, 'HeightLimits', 50*ones(1,2));

    hf = most.gui.uiflowcontainer('Parent', obj.hStimQuickAddPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(hf,'Quick Add');

    uu = most.gui.uiflowcontainer('Parent', hf,'FlowDirection','LeftToRight');

    ctl = uicontrol('parent',uu,'string','Add Pause','callback',@(varargin)obj.quickAddPause,kpf{:});
    set(ctl, 'WidthLimits', 80*ones(1,2));

    ctl = uicontrol('parent',uu,'string','Add Park','callback',@(varargin)obj.quickAddPark,kpf{:});
    set(ctl, 'WidthLimits', 80*ones(1,2));

    nm = most.gui.staticText('Parent',uu,'String','Duration (ms):','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 80*ones(1,2));
    ctl = most.gui.uicontrol('parent',uu,'style','edit','Bindings',{obj 'stimQuickAddDuration' 'Value'});
    set(ctl, 'WidthLimits', 40*ones(1,2));
end

function createSlmPropsPanel(obj,parent,kpf)
    obj.hSlmPropsPanel = uipanel('Parent', parent);
    set(obj.hSlmPropsPanel, 'HeightLimits', 162*ones(1,2));

    flw = most.gui.uiflowcontainer('Parent',obj.hSlmPropsPanel,'FlowDirection','TopDown','Margin',0.0001);
    titleBar(flw,'SLM Pattern Properties');

    cols = most.gui.uiflowcontainer('Parent', flw,'FlowDirection','LeftToRight');
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown');
    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown');
    set(col1, 'WidthLimits', 194*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Scan Function:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 75*ones(1,2));
    ctls.pmFunction = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',obj.slmScanOptions,'callback',@obj.slmPropsPanelCtlCb,'tag','pmFunction',kpf{:});

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Fcn Args:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 50*ones(1,2));
    ctls.etArgs = most.gui.paramCellArrayEdit('Parent',hf1,'callback',@obj.slmPropsPanelCtlCb,'tag','etArgs');

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Duration (ms):','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 75*ones(1,2));
    ctls.etDuration = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.slmPropsPanelCtlCb,'tag','etDuration');
    set(ctls.etDuration, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col1,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Repetitions:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 75*ones(1,2));
    ctls.etReps = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.slmPropsPanelCtlCb,'tag','etReps');
    set(ctls.etReps, 'WidthLimits', 40*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Width:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etWidth = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.slmPropsPanelCtlCb,'tag','etWidth');
    set(ctls.etWidth, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Height:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etHeight = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.slmPropsPanelCtlCb,'tag','etHeight');
    set(ctls.etHeight, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Rotation:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.slmPropsPanelCtlCb,'tag','etRotation');
    set(ctls.etRotation, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', col2,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Beam Power%','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 70*ones(1,2));
    ctls.etPower = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.slmPropsPanelCtlCb,'tag','etPower');
    set(ctls.etPower, 'WidthLimits', 60*ones(1,2));

    ctls.etDone = most.gui.uicontrol('Parent',col2,'String','Done','callback',@obj.finishSlmEdit);

    obj.hSlmPropsPanelCtls = ctls;
    obj.hSlmPropsPanel.Visible = 'off';
end

function createNewImRoiPropsPanel(obj,parent,kpf)
    obj.hNewImagingRoiPanel = uipanel('Parent', parent);
    set(obj.hNewImagingRoiPanel, 'HeightLimits', 220*ones(1,2));

    flw = most.gui.uiflowcontainer('Parent',obj.hNewImagingRoiPanel,'FlowDirection','TopDown', ...
        'Margin',0.0001);
    titleBar(flw,'New ROI');

    topStuff = most.gui.uiflowcontainer('Parent',flw,'FlowDirection','TopDown','Margin',0.0001);
    botStuff = most.gui.uiflowcontainer('Parent',flw,'FlowDirection','BottomUp','Margin',0.0001);


    topRow = most.gui.uiflowcontainer('Parent', topStuff,'FlowDirection','LeftToRight');
    set(topRow, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',topRow,'String','Draw By:','HorizontalAlignment','left');
    set(nm, 'WidthLimits', 50*ones(1,2));
    ctls.rbTopLeftRect = most.gui.uicontrol('Parent',topRow, ...
        'Style','radiobutton', ...
        'string','Top Left Rectangle', ...
        'callback',@(varargin)set(obj,'newRoiDrawMode','top left rectangle'), ...
        kpf{:});
    ctls.rbCenterPtRect = most.gui.uicontrol('Parent',topRow, ...
        'Style','radiobutton', ...
        'string','Center Point Rectangle', ...
        'callback',@(varargin)set(obj,'newRoiDrawMode','center point rectangle'), ...
        kpf{:});
    ctls.rbCellPick = most.gui.uicontrol('Parent',topRow, ...
        'Style','radiobutton', ...
        'string','Cell Picker', ...
        'callback',@(varargin)set(obj,'newRoiDrawMode','cell picker'), ...
        kpf{:});
    set(ctls.rbTopLeftRect, 'WidthLimits', 115*ones(1,2));
    set(ctls.rbCenterPtRect, 'WidthLimits', 135*ones(1,2));
    set(ctls.rbCellPick, 'WidthLimits', 70*ones(1,2));


    botRow = most.gui.uiflowcontainer('Parent', botStuff,'FlowDirection','LeftToRight','Margin',0.0001);
    botRowL = most.gui.uiflowcontainer('Parent', botRow,'FlowDirection','LeftToRight');
    set(botRowL, 'WidthLimits', 160*ones(1,2));
    botRowR = most.gui.uiflowcontainer('Parent', botRow,'FlowDirection','RightToLeft');
    set(botStuff, 'HeightLimits', 28*ones(1,2));
    ctls.stDraw = most.gui.staticText('Parent',botRowL, ...
        'String','   Draw new ROI...', ...
        'HorizontalAlignment','left', ...
        'FontWeight','bold', ...
        'FontSize',12);
    ctl = most.gui.uicontrol('Parent',botRowR, ...
        'string','Cancel', ...
        'callback',@obj.newRoiPropsPanelCtlCb, ...
        'tag','pbCancel', ...
        kpf{:});
    set(ctl, 'WidthLimits', 70*ones(1,2));
    ctls.pbCreate = most.gui.uicontrol('Parent',botRowR, ...
        'string','Create Using Defaults', ...
        'callback',@obj.newRoiPropsPanelCtlCb, ...
        'tag','pbCreateDefault', ...
        kpf{:});
    set(ctls.pbCreate, 'WidthLimits', 140*ones(1,2));

    cols = most.gui.uiflowcontainer('Parent', topStuff,'FlowDirection','LeftToRight');
    col1 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    col2 = most.gui.uiflowcontainer('Parent', cols,'FlowDirection','TopDown','Margin',0.0001);
    set(col1, 'WidthLimits', 194*ones(1,2));

    up1 = uipanel('parent',col1,'title','Default Scanfield Position/Size');
    up = most.gui.uiflowcontainer('Parent', up1,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center X:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterX = most.gui.uicontrol('Parent',hf1, ...
        'Style','edit', ...
        'tag','etCenterX', ...
        'callback',@obj.newRoiPropsPanelCtlCb);
    set(ctls.etCenterX, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Center Y:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etCenterY = most.gui.uicontrol('Parent',hf1, ...
        'Style','edit', ...
        'tag','etCenterY', ...
        'callback',@obj.newRoiPropsPanelCtlCb);
    set(ctls.etCenterY, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Width:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etWidth = most.gui.uicontrol('Parent',hf1, ...
        'Style','edit', ...
        'tag','etWidth', ...
        'callback',@obj.newRoiPropsPanelCtlCb);
    ctls.cbWidthLock = most.gui.uicontrol('Parent',hf1, ...
        'Style','Checkbox', ...
        'string','Lock', ...
        'Bindings',{obj 'lockScanfieldWidth' 'value'}, ...
        kpf{:});
    set(ctls.etWidth, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Height:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    ctls.etHeight = most.gui.uicontrol('Parent',hf1, ...
        'Style','edit', ...
        'tag','etHeight', ...
        'callback',@obj.newRoiPropsPanelCtlCb);
    ctls.cbHeightLock = most.gui.uicontrol('Parent',hf1, ...
        'Style','Checkbox', ...
        'string','Lock', ...
        'Bindings',{obj 'lockScanfieldHeight' 'value'}, ...
        kpf{:});
    set(ctls.etHeight, 'WidthLimits', 60*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Rotation:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 60*ones(1,2));
    %ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'defaultRoiRotation' 'value'});
    ctls.etRotation = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.newRoiPropsPanelCtlCb,'tag','etRotation');
    set(ctls.etRotation, 'WidthLimits', 60*ones(1,2));



    upCp = uipanel('parent',col1,'bordertype','none');
    up = most.gui.uiflowcontainer('Parent', upCp,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    nm = most.gui.staticText('Parent',hf1,'String','Selection Mode:','HorizontalAlignment','right');
    set(nm, 'WidthLimits', 84*ones(1,2));
    ctls.pmSelMode = most.gui.uicontrol('Parent',hf1,'Style','popupmenu','string',[obj.cellPickModes {'Custom...'}],'Bindings',{obj 'cellPickMode' 'choice'},kpf{:});

    upSel = uipanel('parent',up,'title','Selected Cell');
    set(upSel, 'HeightLimits', 42*ones(1,2));
    upf = most.gui.uiflowcontainer('Parent', upSel,'FlowDirection','LeftToRight');
    ctls.pbDilate = uicontrol('Parent',upf,'string','Dilate','enable','off','callback',@obj.pbDilateCell,kpf{:});
    ctls.pbErode = uicontrol('Parent',upf,'string','Erode','enable','off','callback',@obj.pbErodeCell,kpf{:});
    ctls.pbDelete = uicontrol('Parent',upf,'string','Delete','enable','off','callback',@obj.pbDeleteCell,kpf{:});



    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stMargin = most.gui.staticText('Parent',hf1,'String','ROI Margin [um]:','HorizontalAlignment','right');
    set(ctls.stMargin, 'WidthLimits', 90*ones(1,2));
    ctls.etMargin = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etMargin','callback',@obj.newRoiPropsPanelCtlCb);
    set(ctls.etMargin, 'WidthLimits', 60*ones(1,2));

    ctls.cbCreateDiscrete = most.gui.uicontrol('Parent',up,'Style','Checkbox','string','Create as discrete plane ROI','Bindings',{obj 'cellPickCreateAsDiscrete' 'Value'},kpf{:});
    set(ctls.cbCreateDiscrete, 'HeightLimits', 24*ones(1,2));



    up2 = uipanel('parent',col2,'title','Default Scanfield Resolution');
    up = most.gui.uiflowcontainer('Parent', up2,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', up,'FlowDirection','LeftToRight');
    ctls.rbPixCount = most.gui.uicontrol('Parent',hf1,'Style','radiobutton','string','Pixel Count','callback',@(varargin)set(obj,'newRoiDefaultResolutionMode','pixel count'),kpf{:});
    ctls.rbPixRatio = most.gui.uicontrol('Parent',hf1,'Style','radiobutton','string','Pixel Ratio','callback',@(varargin)set(obj,'newRoiDefaultResolutionMode','pixel ratio'),kpf{:});
    set(hf1, 'HeightLimits', 24*ones(1,2));


    ctls.pixCntCtls = most.gui.uiflowcontainer('Parent', up,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', ctls.pixCntCtls,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stPixCountX = most.gui.staticText('Parent',hf1,'String','Pixel Count X:','HorizontalAlignment','right');
    set(ctls.stPixCountX, 'WidthLimits', 120*ones(1,2));
    %ctls.etPixCountX = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'defaultRoiPixelCountX' 'value'});
    ctls.etPixCountX = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.newRoiPropsPanelCtlCb,'tag','etPixCountX');

    hf1 = most.gui.uiflowcontainer('Parent', ctls.pixCntCtls,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stPixCountY = most.gui.staticText('Parent',hf1,'String','Pixel Count Y:','HorizontalAlignment','right');
    set(ctls.stPixCountY, 'WidthLimits', 120*ones(1,2));
    %ctls.etPixCountY = most.gui.uicontrol('Parent',hf1,'Style','edit','Bindings',{obj 'defaultRoiPixelCountY' 'value'});
    ctls.etPixCountY = most.gui.uicontrol('Parent',hf1,'Style','edit','callback',@obj.newRoiPropsPanelCtlCb,'tag','etPixCountY');


    ctls.pixRatCtls = most.gui.uiflowcontainer('Parent', up,'FlowDirection','TopDown','Margin',0.0001);

    hf1 = most.gui.uiflowcontainer('Parent', ctls.pixRatCtls,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stPixRatioX = most.gui.staticText('Parent',hf1,'String','Pixel Ratio [Pix/um] X:','HorizontalAlignment','right');
    set(ctls.stPixRatioX, 'WidthLimits', 120*ones(1,2));
    ctls.etPixRatioX = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etPixRatioX','callback',@obj.newRoiPropsPanelCtlCb);

    hf1 = most.gui.uiflowcontainer('Parent', ctls.pixRatCtls,'FlowDirection','LeftToRight');
    set(hf1, 'HeightLimits', 24*ones(1,2));
    ctls.stPixRatioY = most.gui.staticText('Parent',hf1,'String','Pixel Ratio [Pix/um] Y:','HorizontalAlignment','right');
    set(ctls.stPixRatioY, 'WidthLimits', 120*ones(1,2));
    ctls.etPixRatioY = most.gui.uicontrol('Parent',hf1,'Style','edit','tag','etPixRatioY','callback',@obj.newRoiPropsPanelCtlCb);

    set(up1, 'HeightLimits', 141*ones(1,2));
    set(up2, 'HeightLimits', 92*ones(1,2));

    hf1 = most.gui.uiflowcontainer('Parent',col2,'FlowDirection','LeftToRight');
    ctls.cbDrawMultiple = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Draw Multiple','Bindings',{obj 'drawMultipleRois' 'value'},kpf{:});
    ctls.cbDrawArray = most.gui.uicontrol('Parent',hf1,'Style','Checkbox','string','Draw Array','Bindings',{obj 'drawArray' 'value'},kpf{:});


    ctls.rectCtls = up1;
    ctls.cellCtls = upCp;
    obj.hNewImagingRoiPanelCtls = ctls;
    obj.hNewImagingRoiPanel.Visible = 'off';
    obj.newRoiDefaultResolutionMode = 'pixel count';
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

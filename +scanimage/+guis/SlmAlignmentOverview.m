classdef SlmAlignmentOverview < most.Gui
    properties
        hSlmScan
        hListeners = event.listener.empty();
        hScatteredAlignmentOverview = [];
    end
    
    properties (Dependent)
        hSI
        hSICtl
    end
    
    methods
        function obj = SlmAlignmentOverview(hSlmScan)
            obj = obj@most.Gui([],[],[60 15],'characters');
            obj.hSlmScan = hSlmScan;
        end
        
        function delete(obj)
            delete(obj.hListeners);
            if ~isempty(obj.hScatteredAlignmentOverview)
                most.idioms.safeDeleteObj(obj.hScatteredAlignmentOverview);
            end
        end
    end
    
    methods (Access = protected)
        function initGui(obj)
            set(obj.hFig,'Name',sprintf('%s ALIGNMENT',obj.hSlmScan.name),'Resize','off');
            
            mainFlow = most.gui.uiflowcontainer('Parent',obj.hFig,'FlowDirection','TopDown');
                hPanel = uipanel('Parent',mainFlow,'Title',sprintf('%s Alignment',obj.hSlmScan.name));
                panelFlow = most.gui.uiflowcontainer('Parent',hPanel,'FlowDirection','TopDown');
                    hTabGroup = uitabgroup('Parent',panelFlow);
                    hTab = uitab('Parent',hTabGroup,'Title','SLM+Galvos');
                        flow = most.gui.uiflowcontainer('Parent',hTab,'FlowDirection','TopDown');

                        HorizontalFlow = most.gui.uiflowcontainer('Parent',flow,'FlowDirection','lefttoright');
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbGGToImaging','String',['Galvos ' most.constants.Unicode.rightwards_arrow ' Imaging Path'],'Callback',@(varargin)obj.showGGAlignment);
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbResetGGtoImaging','String','Reset','Callback',@obj.resetGGAlignment,'WidthLimits',[50 50]);
                        
                        HorizontalFlow = most.gui.uiflowcontainer('Parent',flow,'FlowDirection','lefttoright');
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbSlmToGG','String',['SLM ' most.constants.Unicode.rightwards_arrow ' Galvos'],'Callback',@(varargin)obj.showLateralAlignment);
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbResetSlmToGG','String','Reset','Callback',@obj.resetLateralAlignment,'WidthLimits',[50 50]);

                        HorizontalFlow = most.gui.uiflowcontainer('Parent',flow,'FlowDirection','lefttoright');
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbSlmZToStage','String',['SLM Z ' most.constants.Unicode.rightwards_arrow ' Stage'],'Callback',@(varargin)obj.showZAlignment);
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbResetSLMToZ','String','Reset','Callback',@obj.resetZAlignment,'WidthLimits',[50 50]);

                        HorizontalFlow = most.gui.uiflowcontainer('Parent',flow,'FlowDirection','lefttoright');
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbSlmDiffractionEfficiency1','String','SLM Diffraction efficiency','Callback',@(varargin)obj.showDiffractionEfficiencyTool(false));
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbResetSlmDiffractionEfficiency1','String','Reset','Callback',@obj.resetDiffractionEfficiencyCalibration,'WidthLimits',[50 50]);

                    hTab = uitab('Parent',hTabGroup,'Title','SLM (standalone)');
                        flow = most.gui.uiflowcontainer('Parent',hTab,'FlowDirection','TopDown');

                        HorizontalFlow = most.gui.uiflowcontainer('Parent',flow,'FlowDirection','lefttoright');
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbSlmDiffractionEfficiency2','String','SLM Diffraction efficiency','Callback',@(varargin)obj.showDiffractionEfficiencyTool(true));
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','resetSlmOnlyDiffractionEfficiencyCalibration','String','Reset','Callback',@obj.resetDiffractionEfficiencyCalibration,'WidthLimits',[50 50]);

                        HorizontalFlow = most.gui.uiflowcontainer('Parent',flow,'FlowDirection','lefttoright');
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbSlmSpatialCalibrationTool','String','SLM Pattern burn tool','Callback',@(varargin)obj.showSlmSpatialCalibrationTool);
                        obj.addUiControl('Parent',HorizontalFlow,'Tag','pbResetSlmSpatialCalibration','String','Reset','Callback',@obj.resetSlmSpatialCalibration,'WidthLimits',[50 50]);

            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSlmScan,'ObjectBeingDestroyed',@(varargin)obj.delete);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSlmScan.hCSScannerToRef,'changed',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSlmScan.hCSSlmZAlignmentLut,'changed',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSlmScan.hSlm.hCSDiffractionEfficiency,'changed',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSlmScan.hSlm,'hCSDiffractionEfficiency','PostSet',@(varargin)obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSlmScan.hCSSlmAlignmentLut,'changed',@(varargin)obj.redraw);
            
            if most.idioms.isValidObj(obj.hSlmScan.hLinScan)
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSlmScan.hLinScan,'scannerToRefTransform','PostSet',@(varargin)obj.redraw);
            end
            
            obj.redraw();
        end
    end
    
    methods
        function showGGAlignment(obj)            
            obj.hSICtl.hAlignmentControls.showWindow = true;
            obj.hSICtl.hAlignmentControls.raise();
            obj.hSICtl.hAlignmentControls.Visible = true;
            obj.hSICtl.hAlignmentControls.videoImToRefImTransform = eye(3);
            most.idioms.figure(obj.hSICtl.hAlignmentControls.hAlignmentFig);
            
            most.gui.tetherGUIs(obj.hFig,obj.hSICtl.hAlignmentControls.hFig,'righttop');
            most.gui.tetherGUIs(obj.hSICtl.hAlignmentControls.hFig,obj.hSICtl.hAlignmentControls.hAlignmentFig,'righttop');
            
            msg = sprintf(['1) Copy a channel from the imaging path into the alignment window.\n' ...
                           '2) Start imaging with scanner ''%s''\n' ...
                           '3) Add alignment points by right clicking into the alignment window\n' ...
                           '4) Drag the alignment points to overlay the two images\n' ...
                           '5) Select ''Save Scanner Alignment'' to save the alignment'] ...
                           ,obj.hSI.hSlmScan.hLinScan.name);
            
            msgbox(msg,'Galvo Alignment','help');
        end
        
        function resetGGAlignment(obj,varargin)
            most.gui.nonBlockingDialog('Reset GG to RG Alignment','Do you really want to reset the Linear Scanner to Resonant Scanner alignment?',{{'Yes', @reset}, {'No', @false}},'r',...
                'Position',[0 0 700 150]);

            function reset()
                obj.hSlmScan.hLinScan.scannerToRefTransform = eye(3);
            end
        end

        function showLateralAlignment(obj)
            obj.hSlmScan.showLaterAlignmentControls();
            most.gui.tetherGUIs(obj.hFig,obj.hSlmScan.hLateralAlignmentControls.hFig,'righttop');
        end

        function resetLateralAlignment(obj,varargin)
            most.gui.nonBlockingDialog('Reset SLM Lateral Alignment','Do you really want to reset the SLM Lateral alignment?',{{'Yes', @reset}, {'No', @false}},'r',...
                'Position',[0 0 700 150]);

            function reset()
                obj.hSlmScan.hCSScannerToRef = eye(4);
            end
        end
        
        function showDiffractionEfficiencyTool(obj,allowSavingZCalibration)
            msg = sprintf('Choose a diffraction efficiency calibration method.\n\n');
            most.gui.nonBlockingDialog('SLM Diffraction Efficiency', msg, {{'Sub-stage camera' @useSubStageCameraSlmCalibration} {'Enter function' @set3DInterpolantByFunction} {'SLM uniform' @add3DInterpolantBySlmAcquiredImages} {'SLM scattered' @useScatteredTiffCalibration}},'b',...
                'Position',[0 0 700 150],'Name','Diffraction Efficiency Calibration');

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

                    %scanimage.util.setCustomSLMPowerInterpolant(fcn,numPoints,ranges_um,zeroOrderBeamBlockRadius_um)
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

                function ranges_um = reshapeRangesIfNeeded(ranges_um)
                    if isvector(ranges_um)
                        if isrow(ranges_um)
                            ranges_um = ranges_um';
                        end

                        ranges_um_ = zeros(3,2);
                        for idx = 1:3
                            ranges_um_(idx,:) = [-ranges_um(idx)/2, ranges_um(idx)/2];
                        end
                        ranges_um = ranges_um_;
                    end
                    validateattributes(ranges_um,{'numeric'},{"2d",'nrows',3,'ncols',2,'real'});
                end
            end
        
            function add3DInterpolantBySlmAcquiredImages()
                %Load Image and placement/orientation data from TIFF
                [FILENAME, PATHNAME, ~] = uigetfile({'*.tif', '*.tiff'},'Select SLM acquired TIFF files of a homogenously fluorescent sample from various SLM park positions.','MultiSelect','on');

                if isempty(FILENAME)
                    return;
                end

                if ~iscell(FILENAME)
                    FILENAME = {FILENAME};
                end

                totalPts_SLM = [];
                totalImageStack = [];
                for tifIdx = 1:numel(FILENAME)
                    [roiData, roiGroup, header, imageData] = scanimage.util.getMroiDataFromTiff(fullfile(PATHNAME,FILENAME{tifIdx}));

                    assert(isfield(header.SI.hScan2D,'parkPosition_um'),'TIFFs must be acquired with the SLM scanner.');

                    %Check Imaging parameters
                    assert(isscalar(roiGroup.rois) && isscalar(roiGroup.rois.scanfields),'Stack must be acquired without MROI');
                    assert(isscalar(roiData),'roiData must be scalar');

                    roiData = roiData{1};

                    scanfield = roiGroup.rois(1).scanfields;
                    assert(scanfield.rotationDegrees == 0,'There must be no rotation of the imaging field');
                    assert(scanfield.pixelResolutionXY(1) == scanfield.pixelResolutionXY(2),'Pixels per line must equal lines per frame.');
                    pixelResolution = scanfield.pixelResolutionXY(1);

                    assert(pixelResolution < 65,'Image resolution must be less than 65 pixels in either direction');
                    assert(numel(roiData.zs) < 65,'Stack must contain 64 or fewer slices.');

                    % Generate points for each pixel in the coordinate system of the
                    % SLM
                    [xx_pix, yy_pix, zz_um] = ndgrid(1:pixelResolution,1:pixelResolution,header.SI.hScan2D.parkPosition_um(1,3)); %SLMScan acquires at the parked depth.
                    pts_ref = scanimage.mroi.util.xformPoints([xx_pix(:) yy_pix(:)],scanfield.pixelToRefTransform);

                    pts_ref = scanimage.mroi.coordinates.Points(obj.hSI.hCoordinateSystems.hCSReference,[pts_ref zz_um(:)]);
                    pts_SLM = pts_ref.transform(obj.hSlmScan.hSlm.hCoordinateSystem);
                    totalPts_SLM = cat(1,totalPts_SLM, pts_SLM.points);

                    %Reshape image matrix
                    imageData = double(imageData);
                    imageData = pagetranspose(imageData); %Can't get whether it's transposed from the ROI Data since this is a roiDataSimple object. Assume that it is.
                    totalImageStack = cat(3,totalImageStack,imageData);
                end

                %efficiency is the reciprocal of the scale factor to apply to
                %excitation power. This is applied in scanimage.mroi.scanners.SLM
                %in function
                maxPixelValue = max(totalImageStack,[],'all');
                assert(maxPixelValue>0);
                imageStack_emission_Norm = totalImageStack ./ maxPixelValue; %This assumes that the PMT offset is calibrated.
                efficiency = sqrt(imageStack_emission_Norm); %For 2P effect. Probability of 2P absorption increases with the square of excitation intensity.
                efficiency(efficiency<0.02) = 0.02; %Cap efficiency at 0.02 (50x the power at efficiency of 1)


                X = reshape(totalPts_SLM(:,1),pixelResolution,pixelResolution,numel(FILENAME));
                Y = reshape(totalPts_SLM(:,2),pixelResolution,pixelResolution,numel(FILENAME));
                Z = reshape(totalPts_SLM(:,3),pixelResolution,pixelResolution,numel(FILENAME));

                V = efficiency;
                
                x = squeeze(X(:,1,1));
                y = squeeze(Y(1,:,1));
                z = squeeze(Z(1,1,:));
                
                % This assumes the TIFF-derived samples lie on one rectilinear
                % XY grid that is reused at every Z plane.
                [x, ix] = sort(x);
                [y, iy] = sort(y);
                [z, iz] = sort(z);
                
                V = V(ix, iy, iz);
                
                interpolant = griddedInterpolant({x, y, z}, V, 'nearest', 'nearest');
               


                obj.hSlmScan.hSlm.hCSDiffractionEfficiency.fromParentInterpolant{1} = interpolant;
                obj.hSI.hCoordinateSystems.save();

                debug = true;
                if debug
                    %This will plot a bunch of points that are not the points making up
                    %the interpolant. This gives a broad
                    pts = interpolant.GridVectors;
                    [a,b,c] = ndgrid(linspace(min(pts{1}),max(pts{1}),100),...
                        linspace(min(pts{2}),max(pts{2}),100),...
                        linspace(min(pts{3}),max(pts{3}),20));
                    eff = interpolant(a(:),b(:),c(:));
                    hFig = figure(105);
                    hold off;
                    scatter3(a(:),b(:),c(:),5,eff,'filled',MarkerFaceAlpha=0.05);
                    colorbar();
                    colormap(hFig,'turbo')
                    xlabel('x');
                    ylabel('y');
                    set ( gca, 'YDir', 'reverse' );
                    set ( gca, 'ZDir', 'reverse' );
                end
            end

            function useScatteredTiffCalibration()
                obj.showScatteredDiffractionEfficiencyTool(allowSavingZCalibration);
            end
        end

        function showScatteredDiffractionEfficiencyTool(obj,allowSavingZCalibration)
            if isempty(obj.hScatteredAlignmentOverview) || ~isvalid(obj.hScatteredAlignmentOverview)
                obj.hScatteredAlignmentOverview = scanimage.guis.SlmAlignmentOverviewScattered(obj.hSlmScan);
            end

            try
                obj.hScatteredAlignmentOverview.show();
            catch
            end

            try
                most.gui.tetherGUIs(obj.hFig,obj.hScatteredAlignmentOverview.hFig,'righttop');
            catch
            end

            obj.hScatteredAlignmentOverview.showDiffractionEfficiencyTool(allowSavingZCalibration);
        end

        function resetDiffractionEfficiencyCalibration(obj,varargin)
            most.gui.nonBlockingDialog('Reset SLM Diffraction Efficiency Calibration','Do you really want to reset the Diffraction Efficiency Calibration?',{{'Yes', @reset}, {'No', @false}},'r',...
                'Position',[0 0 700 150]);

            function reset()
                hCS = obj.hSlmScan.hSlm.hCSDiffractionEfficiency;
                hCS.reset();
            end
        end

        function showSlmSpatialCalibrationTool(obj)
            obj.hSICtl.hGuiClasses.SlmSpatialCalibration.raise();
        end

        function resetSlmSpatialCalibration(obj)
            most.gui.nonBlockingDialog('Reset Z Alignment','Do you really want to reset the SLM Z to Stage Z alignment?',{{'Yes', @reset}, {'No', @false}},'r',...
                'Position',[0 0 700 150]);

            function reset()
                obj.hSlmScan.hCSSlmAlignmentLut.reset();
            end
        end
        
        function showZAlignment(obj)
            obj.hSlmScan.showZAlignmentControls();
        end

        function resetZAlignment(obj,varargin)
            most.gui.nonBlockingDialog('Reset Z Alignment','Do you really want to reset the SLM Z to Stage Z alignment?',{{'Yes', @reset}, {'No', @false}},'r',...
                'Position',[0 0 700 150]);

            function reset()
                hCS = obj.hSlmScan.hCSSlmZAlignmentLut;
                hCS.reset();
            end
        end
        
        function redraw(obj)
            redrawPbGGToImaging();
            redrawPbSlmToGG();
            redrawPbSlmZToStage();
            redrawPbSlmDiffractionEfficiency();
            redrawPbSlmSpatialCalibrationTool();
            
            function redrawPbGGToImaging()
                if most.idioms.isValidObj(obj.hSlmScan.hLinScan)
                    enable = true;
                    T = obj.hSlmScan.hLinScan.scannerToRefTransform;
                    if isequal(T,eye(size(T)))
                        color = most.constants.Colors.lightGray;
                    else
                        color = most.constants.Colors.lightGreen;
                    end
                    
                    tooltip = mat2str_(T);
                else
                    enable = false;
                    color = most.constants.Colors.lightGray;
                    tooltip = '';
                end
                
                obj.pbGGToImaging.Enable = enable;
                obj.pbGGToImaging.hCtl.BackgroundColor = color;
                obj.pbGGToImaging.hCtl.TooltipString = tooltip;
            end
            
            function redrawPbSlmToGG()
                hCS = obj.hSlmScan.hCSScannerToRef;
                isSetToParentAffine   = ~isempty(hCS.toParentAffine)   && ~isequal(hCS.toParentAffine,  eye(4));
                isSetFromParentAffine = ~isempty(hCS.fromParentAffine) && ~isequal(hCS.fromParentAffine,eye(4));
                
                if isSetToParentAffine
                    color = most.constants.Colors.lightGreen;
                    T = hCS.toParentAffine;
                    tooltip = mat2str_(T);
                elseif isSetFromParentAffine
                    color = most.constants.Colors.lightGreen;
                    T = hCS.fromParentAffine;
                    tooltip = mat2str_(T);
                else
                    color = most.constants.Colors.lightGray;
                    tooltip = '';
                end
                
                obj.pbSlmToGG.hCtl.BackgroundColor = color;
                obj.pbSlmToGG.hCtl.TooltipString = tooltip;
            end
            
            function redrawPbSlmZToStage()
                hCS = obj.hSlmScan.hCSSlmZAlignmentLut;
                if isempty(hCS.toParentLutEntries) && isempty(hCS.fromParentLutEntries)
                    color = most.constants.Colors.lightGray;
                else
                    color = most.constants.Colors.lightGreen;
                end
                
                obj.pbSlmZToStage.hCtl.BackgroundColor = color;
            end
            
            function redrawPbSlmDiffractionEfficiency()
                hCS = obj.hSlmScan.hSlm.hCSDiffractionEfficiency;

                if isempty(hCS)
                    unCalibrated = true;
                else
                    if isa(hCS,'scanimage.mroi.coordinates.CSLut')
                        hInterpolant = hCS.fromParentInterpolant{1};
                        unCalibrated = isa(hInterpolant,'griddedInterpolant');
                    elseif isa(hCS,'scanimage.mroi.coordinates.CSFunction')
                        hFunction = hCS.fromParentFunction;
                        unCalibrated = isempty(hFunction);
                    end
                end
                
                if unCalibrated
                    color = most.constants.Colors.lightGray;
                else
                    color = most.constants.Colors.lightGreen;
                end
                
                obj.pbSlmDiffractionEfficiency1.hCtl.BackgroundColor = color;
                obj.pbSlmDiffractionEfficiency2.hCtl.BackgroundColor = color;
            end
            
            function redrawPbSlmSpatialCalibrationTool()
                hCS = obj.hSlmScan.hCSSlmAlignmentLut;
                
                toParentInterpolantSet   = all(cellfun(@(c)isempty(c),{hCS.toParentInterpolant}));
                fromParentInterpolantSet = all(cellfun(@(c)isempty(c),{hCS.fromParentInterpolant}));
                
                if toParentInterpolantSet || fromParentInterpolantSet
                    color = most.constants.Colors.lightGreen;
                else
                    color = most.constants.Colors.lightGray;
                end
                
                obj.pbSlmSpatialCalibrationTool.hCtl.BackgroundColor = color;
            end
        end
    end
    
    methods
        function val = get.hSI(obj)
            val = obj.hSlmScan.hSI;
        end
        
        function val = get.hSICtl(obj)
            val = obj.hSlmScan.hSI.hController{1};
        end
    end
end

%%% Local function
function str = mat2str_(T)
    str = mat2str(T,3);
    str = regexprep(str,';',';\n');
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

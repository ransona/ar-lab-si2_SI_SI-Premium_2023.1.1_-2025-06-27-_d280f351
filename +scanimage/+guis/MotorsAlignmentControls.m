classdef MotorsAlignmentControls < most.Gui
    properties
        autoRead = true;
    end

    properties (Hidden)
        guiState = 'undetermined';

        hListeners;

        upSetup;
        upCalibrationPoints;
        upAlignmentInfo;
    end

    properties (Constant,Hidden)
        FIGURE_Y_SIZE = [258; 71]; %ON;OFF
    end

    %% LIFECYCLE
    methods
        function obj = MotorsAlignmentControls(hModel, hController)
            if nargin < 1
                hModel = [];
            end
            
            if nargin < 2
                hController = [];
            end
            
            obj = obj@most.Gui(hModel, hController, [363 258], 'pixels');
        end

        function delete(obj)
            most.idioms.safeDeleteObj(obj.hListeners);
        end
    end

    methods (Access=protected)
        function initGui(obj)
            set(obj.hFig,'Name','MOTOR ALIGNMENT CONTROLS','Resize','off');

            % main panels
            hMainFlow = most.gui.uiflowcontainer('Parent',obj.hFig,'FlowDirection','TopDown');
            obj.upSetup = most.gui.uipanel(...
                'Parent',hMainFlow,...
                'Title','Setup',...
                'HeightLimits',[65 65],...
                'Tag','upSetup');

            hBottomFlow = most.gui.uiflowcontainer('Parent',hMainFlow,'FlowDirection','LeftToRight');
            obj.upCalibrationPoints = most.gui.uipanel(...
                'Parent',hBottomFlow,...
                'Title','Calibration Points',...
                'WidthLimits',[184 184],...
                'Tag','upCalibrationPoints');

            obj.upAlignmentInfo = most.gui.uipanel(...
                'Parent',hBottomFlow,...
                'Title','Alignment Info',...
                'Tag','upAlignmentInfo');

            % SETUP panel
            hFlow = most.gui.uiflowcontainer('Parent',obj.upSetup,'FlowDirection','LeftToRight');
            tt = ['Activates Motion Correction, move the stage and add calibration\n'...
                  'points to correlate raw stage motor position with detected\n'...
                  'motion to generate the Stage-Scanner Alignment'];
            obj.addUiControl(...
                'Parent',hFlow,...
                'Style','pushbutton',...
                'String','Motion Detection',...
                'Callback',@obj.pbMotionDetectionAlignment_Callback,...
                'TooltipString',sprintf(tt),...
                'Tag','pbMotionDetectionAlignment');

            tt = ['Manually create the Stage-Scanner Alignment by moving the\n'...
                  'stage and shifting the video feed via a graphical user interface'];
            obj.addUiControl(...
                'Parent',hFlow,...
                'Style','pushbutton',...
                'String','Manual Shift',...
                'Callback',@obj.pbManualShiftAlignment_Callback,...
                'TooltipString',sprintf(tt),...
                'Tag','pbManualShiftAlignment');

            % CALIBRATION POINTS panel
            % labels
            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'Style','text',...
                'String','Stage position',...
                'Position',[25 152 79 14],...
                'Tag','txStagePositionLabel');

            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'Style','text',...
                'String','X',...
                'Position',[7 132 24 14],...
                'Tag','txXPositionLabel');

            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'Style','text',...
                'String','Y',...
                'Position',[7 112 24 14],...
                'Tag','txYPositionLabel');

            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'Style','text',...
                'String','Calibration Points:',...
                'HorizontalAlignment','right',...
                'Position',[16 91 89 14],...
                'Tag','txCalibrationPoints');

            % edit-texts
            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'Style','edit',...
                'String','',...
                'Position',[33 129 64 21],...
                'Tag','etXStagePosition');

            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'Style','edit',...
                'String','',...
                'Position',[33 108 64 21],...
                'Tag','etYStagePosition');

            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'Style','edit',...
                'String','',...
                'Position',[110 89 52 20],...
                'Enable','inactive',...
                'Tag','etNumberCalibrationPoints');

            % buttons
            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'String','Add Calibration Point',...
                'Callback',@obj.pbAddCalibrationPoint_Callback,...
                'Position',[13 58 151 23],...
                'Tag','pbAddCalibrationPoint');

            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'String','Reset Points',...
                'Callback',@obj.pbResetCalibrationPoints_Callback,...
                'Position',[13 35 151 23],...
                'Tag','pbResetCalibrationPoints');

            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'String','Generate Alignment',...
                'Callback',@obj.pbGenerateAlignment_Callback,...
                'Position',[13 12 151 23],...
                'Tag','pbGenerateAlignment');

            % checkbox
            obj.addUiControl(...
                'Parent',obj.upCalibrationPoints,...
                'Style','checkbox',...
                'String','Auto Read',...
                'Callback',@obj.cbAutoRead_Callback,...
                'Position',[99 118 75 24],...
                'Tag','cbAutoRead');

            % ALIGNMENT INFO panel
            % labels
            obj.addUiControl(...
                'Parent',obj.upAlignmentInfo,...
                'Style','text',...
                'String','Rotation',...
                'HorizontalAlignment','right',...
                'Position',[54 150 46 14],...
                'Tag','txRotationLabel');

            obj.addUiControl(...
                'Parent',obj.upAlignmentInfo,...
                'Style','text',...
                'String','Shear',...
                'HorizontalAlignment','right',...
                'Position',[55 129 44 14],...
                'Tag','txShearLabel');

            obj.addUiControl(...
                'Parent',obj.upAlignmentInfo,...
                'Style','text',...
                'String','Aspect Ratio X/Y',...
                'HorizontalAlignment','right',...
                'Position',[12 107 87 14],...
                'Tag','txAspectRatioXY');

            % edit-texts
            obj.addUiControl(...
                'Parent',obj.upAlignmentInfo,...
                'Style','edit',...
                'String','',...
                'Position',[109 146 50 21],...
                'Enable','inactive',...
                'Tag','etStageRotation');

            obj.addUiControl(...
                'Parent',obj.upAlignmentInfo,...
                'Style','edit',...
                'String','',...
                'Position',[109 125 50 21],...
                'Enable','inactive',...
                'Tag','etStageShear');

            obj.addUiControl(...
                'Parent',obj.upAlignmentInfo,...
                'Style','edit',...
                'String','',...
                'Position',[109 104 50 21],...
                'Enable','inactive',...
                'Tag','etStageAspectRatioXY');

            % buttons
            obj.addUiControl(...
                'Parent',obj.upAlignmentInfo,...
                'String','Reset Alignment',...
                'Callback',@obj.pbResetAlignment_Callback,...
                'Position',[19 52 130 29],...
                'Tag','pbResetAlignment');

            obj.addUiControl(...
                'Parent',obj.upAlignmentInfo,...
                'String','Fix Objective Resolution',...
                'Callback',@obj.pbFixObjectiveResolution_Callback,...
                'Position',[19 22 130 29],...
                'Tag','pbFixObjectiveResolution');

            obj.redraw();
            obj.initListeners();
        end

        function initListeners(obj)
            most.idioms.safeDeleteObj(obj.hListeners);

            obj.hListeners = event.listener.empty(0,1);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hMotors,'axesPosition','PostSet',@obj.redrawStagePosition);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hMotors,'calibrationPoints','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hMotors.hCSAlignment,'changed',@obj.redrawAlignmentInfo);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hMotors.hCSMicron,'changed',@obj.redrawAlignmentInfo);
        end
    end

    methods
        function redraw(obj,varargin)
            obj.redrawFigureSize();
            obj.redrawStagePosition();
            obj.redrawAlignmentInfo();
            obj.redrawSetupButtons();
            obj.updateCalibrationPointMarkers();
            
            obj.cbAutoRead.Value = obj.autoRead;

            numCalibrationPoints = size(obj.hModel.hMotors.calibrationPoints,1);
            obj.etNumberCalibrationPoints.String = num2str(numCalibrationPoints);
        end

        function redrawSetupButtons(obj,varargin)
            colorOn  = [0.35 0.35 1]; % lightish blue
            colorOff = most.constants.Colors.lightGray;

            motionColor = most.idioms.ifthenelse(strcmp(obj.guiState,'motion'),colorOn,colorOff);
            manualColor = most.idioms.ifthenelse(strcmp(obj.guiState,'manual'),colorOn,colorOff);
            obj.pbMotionDetectionAlignment.hCtl.BackgroundColor = motionColor;
            obj.pbManualShiftAlignment.hCtl.BackgroundColor     = manualColor;
        end

        function redrawFigureSize(obj,varargin)
            initialized = ~strcmp(obj.guiState,'undetermined');
            obj.upCalibrationPoints.Visible = initialized;
            obj.upAlignmentInfo.Visible = initialized;
            
            index = most.idioms.ifthenelse(initialized,1,2);
            obj.hFig.Position(4) = obj.FIGURE_Y_SIZE(index);
        end

        function redrawStagePosition(obj,varargin)
            enableXY = most.idioms.ifthenelse(obj.autoRead,'inactive','on');
            obj.etXStagePosition.Enable = enableXY;
            obj.etYStagePosition.Enable = enableXY;

            if obj.autoRead
                obj.etXStagePosition.String = num2str(obj.hModel.hMotors.axesPosition(1));
                obj.etYStagePosition.String = num2str(obj.hModel.hMotors.axesPosition(2));
            end
        end

        function redrawAlignmentInfo(obj,varargin)
            affine = obj.hModel.hMotors.hCSAlignment.toParentAffine;
            affine(:,3) = [];
            affine(3,:) = [];

            [~,~,~,~,rotation,shear] = scanimage.mroi.util.paramsFromTransform(affine);

            affine = obj.hModel.hMotors.hCSMicron.toParentAffine;
            scaleX = affine(1);
            scaleY = affine(6);

            obj.etStageRotation.String = sprintf('%.2f',rotation);
            obj.etStageShear.String = sprintf('%.2f',shear);
            obj.etStageAspectRatioXY.String = sprintf('%.2f',scaleX/scaleY);
        end

        function tfActivated = startManualAlignment(obj,channel,varargin)
            tfActivated = false;

            obj.assertRoiDataAvailable();
            if nargin < 2 || isempty(channel)
                channel = obj.dialogGetChannelForAlignment();
            end
            if isempty(channel)
                return
            end
            obj.assertRoiDataHasChannel(channel);

            % set up alignment controls for stage-scanner alignment
            obj.hController.hAlignmentControls.Visible = false; % initialize GUI
            obj.hController.hAlignmentControls.allowFixedControlPoints = false;
            obj.hController.hAlignmentControls.showMotionMarkers = true;
            obj.hController.hAlignmentControls.alignmentSource = sprintf('Channel %d',channel);
            obj.hController.hAlignmentControls.resetAlignmentFig();
            obj.hController.hAlignmentControls.resetVideoTransform();
            obj.hController.hAlignmentControls.copyChannel(channel);

            % turn off motion alignment if applicable
            obj.hModel.hMotors.abortCalibration();
            obj.hController.hMotionDisplay.Visible = false;

            % show manual alignment window (only alignment, not controls box)
            obj.hController.hAlignmentControls.Visible = false;
            obj.hController.hAlignmentControls.showWindow = true;
            
            tfActivated = true;
        end

        function tfActivated = startMotionAlignment(obj,channel,varargin)
            tfActivated = false;

            obj.assertRoiDataAvailable();
            if nargin < 2 || isempty(channel)
                channel = obj.dialogGetChannelForAlignment();
            end
            if isempty(channel)
                return
            end
            obj.assertRoiDataHasChannel(channel);

            tfActivated = obj.hModel.hMotionManager.activateMotionCorrectionSimple(channel);
            
            if tfActivated
                obj.hModel.hMotors.resetCalibrationPoints();
                obj.hController.hAlignmentControls.Visible = false;
                obj.hController.hAlignmentControls.showWindow = false;
            end
        end

        function channels = getAvailableChannels(obj)
            channels = [];
            stripeData = obj.hModel.hDisplay.lastStripeData;

            if ~isempty(stripeData) && ~isempty(stripeData.roiData)
                roiData = stripeData.roiData{1};
                channels = roiData.channels;
            end
        end

        function assertRoiDataAvailable(obj)
            stripeData = obj.hModel.hDisplay.lastStripeData;
            assert(~isempty(stripeData) && ~isempty(stripeData.roiData),'No image data in buffer. Take an image first and retry');

            channels = obj.getAvailableChannels();
            assert(~isempty(channels), 'Cannot align if no channels are selected for display/save.');
        end

        function assertRoiDataHasChannel(obj,channel)
            assert(~isempty(channel),'No channel selected');

            channels = obj.getAvailableChannels();
            assert(~isempty(channels), 'Cannot align if no channels are selected for display/save.');
            assert(ismember(channel,channels),'Invalid channel %d, should be one of %s',channel,mat2str(channels));
        end

        function channel = dialogGetChannelForAlignment(obj)
            channel = [];
            availableChannels = obj.getAvailableChannels();

            if isscalar(availableChannels)
                channel = availableChannels(1);
                return
            elseif isempty(availableChannels)
                channel = [];
                return
            end

            dialogFig = figure;
            dialogFig.Units = 'pixels';
            dialogFig.Name  = '';
            dialogFig.NumberTitle = 'off';
            dialogFig.MenuBar = 'none';
            dialogFig.Resize = 'off';
            dialogFig.Position = most.gui.centeredScreenPos([215 64],'pixels');
            
            availableChannelsStr = arrayfun(@(i){num2str(i)},availableChannels);
            most.gui.uicontrol('parent',dialogFig,'style','text','string','Channel to use for alignment:','HorizontalAlignment','right','Position', [0 40 150 15],'tag','txChannelInput');
            pmChannel = most.gui.uicontrol('parent',dialogFig,'style','popupmenu','string',availableChannelsStr,'Position', [155 43 50 15],'tag','pmChannelInput');
            
            most.gui.uicontrol('parent',dialogFig,'string','Enter','callback',@(varargin)enterInput,'Position', [73 6 63 25],'tag','bnEnter');
            most.gui.uicontrol('parent',dialogFig,'string','Cancel','callback',@(varargin)cancelInput,'Position', [143 6 63 25],'tag','bnCancel');
            waitfor(dialogFig);

            function cancelInput()
                close(dialogFig);
                delete(dialogFig);
            end
        
            function enterInput()
                channel = str2double(pmChannel.pmValue);
                close(dialogFig);
                delete(dialogFig);
            end
        end

        function updateCalibrationPointMarkers(obj,varargin)
            motionPoints = double.empty(0,3);
            if ~isempty(obj.hModel.hMotors.calibrationPoints)
                motionPoints = obj.hModel.hMotors.calibrationPoints(:,2);
                motionPoints = vertcat(motionPoints{:});
            end
            
            obj.hModel.hMotionManager.motionMarkersXY = motionPoints;
        end
    end

    % CALLBACKS
    methods
        function pbMotionDetectionAlignment_Callback(obj,varargin)
            lastGuiState = obj.guiState;
            obj.guiState = 'motion';
            obj.redrawSetupButtons();

            activated = false;
            try
                activated = obj.startMotionAlignment();
            catch ME
                msgbox(ME.message,'Error','Error');
                most.ErrorHandler.logAndReportError(ME);
            end

            if ~activated
                obj.guiState = lastGuiState;
            end

            obj.redraw();
        end

        function pbManualShiftAlignment_Callback(obj,varargin)
            lastGuiState = obj.guiState;
            obj.guiState = 'manual';
            obj.redrawSetupButtons();

            activated = false;
            try
                activated = obj.startManualAlignment();
            catch ME
                msgbox(ME.message,'Error','Error');
                most.ErrorHandler.logAndReportError(ME);
            end

            if ~activated
                obj.guiState = lastGuiState;
            end

            obj.redraw();
        end

        function pbAddCalibrationPoint_Callback(obj,varargin)
            motion = [];
            if strcmp(obj.guiState,'manual')
                motion = obj.hController.hAlignmentControls.videoImToRefImTransform(1:2,3)' .* -1;
            end

            if obj.autoRead
                obj.hModel.hMotors.addCalibrationPoint([],motion);
            else
                x = str2double(obj.etXStagePosition.String);
                y = str2double(obj.etYStagePosition.String);
                obj.hModel.hMotors.addCalibrationPoint([x y],motion);
            end
        end

        function pbResetCalibrationPoints_Callback(obj,varargin)
            obj.hModel.hMotors.resetCalibrationPoints();
        end

        function pbGenerateAlignment_Callback(obj,varargin)
            obj.hModel.hMotors.createCalibrationMatrix();
            obj.redraw();
        end

        function pbResetAlignment_Callback(obj,varargin)
            obj.hModel.hMotors.resetCalibrationMatrix();
            obj.redraw();
        end

        function pbFixObjectiveResolution_Callback(obj,varargin)
            obj.hModel.hMotors.correctObjectiveResolution();
        end

        function cbAutoRead_Callback(obj,varargin)
            obj.autoRead = obj.cbAutoRead.Value;
        end
    end

    % SETTERS/GETTERS
    methods
        function set.autoRead(obj,value)
            obj.autoRead = value;
            obj.redraw();
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

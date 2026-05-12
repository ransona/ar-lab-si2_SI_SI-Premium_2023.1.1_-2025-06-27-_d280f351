classdef  PhotostimControls < most.Gui
    
    properties (SetAccess=protected,Hidden)
        stimGroupsTable;
        currentlySelectedCell
        
        pbNewRg
        pbEditRg
        pbCopyRg
        pbDeleteRg
        pbMoveRgUp
        pbMoveRgDown
        
        pmMode
        pmTriggerSource
        pmSyncSource
        txSyncSource
        
        cbStimImmediately
        
        cbMonitorShow
        cbMonitorLogging
        
        pbCalibrate
        
        pbAbort
        pbTrigger
        pbSync
        
        etStatus
        etMotionCorrection
        pmScanner
        
        % On Demand only
        onDemandElements
        cbAllowMultiOutput
        cbEnableHotKeys
        
        extStimSelPanel
        pmExtStimSelTrigTerm
        txExtStimSelTrigTerm
        etExtStimSelTerms
        txExtStimSelTerms
        etExtStimSelRg
        txExtStimSelRg
        
        % Sequence only
        sequenceElements
        etStimSequence
        etNumSequences
    end
    
    properties (SetAccess=protected,SetObservable)
        hListeners = event.listener.empty(1,0);
        hIOListeners = event.listener.empty(1,0);
        stimRoiGroupNameListeners = event.listener.empty(1,0);
        hStimRoiGroupListener = event.listener.empty(1,0);
        vDAQStimSelectionTerms;
    end
    
    properties (Transient,Dependent)
        active;
        hScan;
        stimRoiGroups;
        stimulusMode;
        
        %Sequence Mode Props
        sequenceSelectedStimuli;
        numSequences;
        
        %On Demand Mode props
        allowMultipleOutputs;
        stimSelectionTriggerTerm;
        stimSelectionDevice;
        stimSelectionTerms;
        stimSelectionAssignment;
        
        %Both props
        stimTriggerTerm;
        syncTriggerTerm;
        stimImmediately;
        autoTriggerPeriod;
        
        %Monitoring Props
        monitoring;
        logging;
        
        %Motion Compensation
        compensateMotionEnabled;
        
        %Misc
        zMode
        laserActiveSignalAdvance
        
        status
        sequencePosition
        nextStimulus
        completedSequences
        numOutputs
        lastMotion
    end
    
    properties (Constant)
        MODE_OPTIONS = {'On Demand','Sequence'};
    end
    
    properties(SetAccess = private)
        RoiGroupSelection;
        zeroshift = 0;
    end
    
    %% getters/setters for dependent properties
    methods
        function val = get.active(obj)
            val = obj.hModel.hPhotostim.active;
        end
        
        function val = get.hScan(obj)
            val = obj.hModel.hPhotostim.hScan;
        end
        
        function set.hScan(obj, val)
            obj.hModel.hPhotostim.hScan = val;
        end
        
        function val = get.stimRoiGroups(obj)
            val = obj.hModel.hPhotostim.stimRoiGroups;
        end
        
        function set.stimRoiGroups(obj,val)
            obj.hModel.hPhotostim.stimRoiGroups = val;
        end
        
        function val = get.stimulusMode(obj)
            val = obj.hModel.hPhotostim.stimulusMode;
        end
        
        function set.stimulusMode(obj,val)
            obj.hModel.hPhotostim.stimulusMode = val;
        end
        
        function val = get.sequenceSelectedStimuli(obj)
            val = obj.hModel.hPhotostim.sequenceSelectedStimuli;
        end
        
        function set.sequenceSelectedStimuli(obj,val)
            obj.hModel.hPhotostim.sequenceSelectedStimuli = val;
        end
        
        function val = get.numSequences(obj)
            val = obj.hModel.hPhotostim.numSequences;
        end
        
        function set.numSequences(obj,val)
            obj.hModel.hPhotostim.numSequences = val;
        end
        
        function val = get.allowMultipleOutputs(obj)
            val = obj.hModel.hPhotostim.allowMultipleOutputs;
        end
        
        function set.allowMultipleOutputs(obj,val)
            obj.hModel.hPhotostim.allowMultipleOutputs = logical(val);
        end
        
        function val = get.stimSelectionTriggerTerm(obj)
            val = obj.hModel.hPhotostim.stimSelectionTriggerTerm;
            
        end
        
        function set.stimSelectionTriggerTerm(obj,val)
            obj.hModel.hPhotostim.stimSelectionTriggerTerm = val;
        end
        
        function val = get.stimSelectionDevice(obj)
            val = obj.hModel.hPhotostim.stimSelectionDevice;
        end
        
        function set.stimSelectionDevice(obj,val)
            obj.hModel.hPhotostim.stimSelectionDevice = val;
        end
        
        function val = get.stimSelectionTerms(obj)
            val = obj.hModel.hPhotostim.stimSelectionTerms;
        end
        
        function set.stimSelectionTerms(obj,val)
            obj.hModel.hPhotostim.stimSelectionTerms = val;
        end
        
        function val = get.stimSelectionAssignment(obj)
            val = obj.hModel.hPhotostim.stimSelectionAssignment;
        end
        
        function set.stimSelectionAssignment(obj,val)
            obj.hModel.hPhotostim.stimSelectionAssignment = val;
        end
        
        function val = get.stimTriggerTerm(obj)
            val = obj.hModel.hPhotostim.stimTriggerTerm;
        end
        
        function set.stimTriggerTerm(obj,val)
            obj.hModel.hPhotostim.stimTriggerTerm = val;
        end
        
        function val = get.syncTriggerTerm(obj)
            val = obj.hModel.hPhotostim.syncTriggerTerm;
        end
        
        function set.syncTriggerTerm(obj,val)
            obj.hModel.hPhotostim.syncTriggerTerm = val;
        end
        
        function val = get.stimImmediately(obj)
            val = obj.hModel.hPhotostim.stimImmediately;
        end
        
        function set.stimImmediately(obj,val)
            obj.hModel.hPhotostim.stimImmediately = logical(val);
        end
        
        function val = get.autoTriggerPeriod(obj)
            val = obj.hModel.hPhotostim.autoTriggerPeriod;
        end
        
        function set.autoTriggerPeriod(obj,val)
            obj.hModel.hPhotostim.autoTriggerPeriod = val;
        end
        
        function val = get.monitoring(obj)
            val = obj.hModel.hPhotostim.monitoring;
        end
        
        function set.monitoring(obj,val)
            obj.hModel.hPhotostim.monitoring = val;
        end
        
        function val = get.logging(obj)
            val = obj.hModel.hPhotostim.logging;
        end
        
        function set.logging(obj,val)
            obj.hModel.hPhotostim.logging = val;
        end
        
        function val = get.compensateMotionEnabled(obj)
            val = obj.hModel.hPhotostim.compensateMotionEnabled;
        end
        
        function set.compensateMotionEnabled(obj,val)
            obj.hModel.hPhotostim.compensateMotionEnabled = val;
        end
        
        function val = get.zMode(obj)
            val = obj.hModel.hPhotostim.zMode;
        end
        
        function set.zMode(obj,val)
            obj.hModel.hPhotostim.zMode = val;
        end
        
        function val = get.laserActiveSignalAdvance(obj)
            val = obj.hModel.hPhotostim.laserActiveSignalAdvance;
        end
        
        function set.laserActiveSignalAdvance(obj,val)
            obj.hModel.hPhotostim.laserActiveSignalAdvance = val;
        end
        
        function val = get.status(obj)
            val = obj.hModel.hPhotostim.status;
        end
        
        function val = get.sequencePosition(obj)
            val = obj.hModel.hPhotostim.sequencePosition;
        end
        
        function val = get.nextStimulus(obj)
            val = obj.hModel.hPhotostim.nextStimulus;
        end
        
        function val = get.completedSequences(obj)
            val = obj.hModel.hPhotostim.completedSequences;
        end
        
        function val = get.numOutputs(obj)
            val = obj.hModel.hPhotostim.numOutputs;
        end
        
        function val = get.lastMotion(obj)
            val = obj.hModel.hPhotostim.lastMotion;
        end
    end
    
    %% LIFECYCLE
    methods
        function obj = PhotostimControls(hModel, hController)
            if nargin < 1
                hModel = [];
            end
            
            if nargin < 2
                hController = [];
            end
            
            % note this width is updated in redraw, can't use constants in supercall
            obj = obj@most.Gui(hModel, hController, [385 350], 'pixels');
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.hListeners);
            most.idioms.safeDeleteObj(obj.hIOListeners);
            most.idioms.safeDeleteObj(obj.stimRoiGroupNameListeners);
            most.idioms.safeDeleteObj(obj.hStimRoiGroupListener);
        end
        
        function refreshGUI(obj)
            cellfun(@(el)most.idioms.safeDeleteObj(obj.(el)),allUIElements());
            obj.initGui();
        end
    end
    
    methods (Access = protected)
        function initGui(obj)
            obj.hFig.Name = 'PHOTOSTIMULATION CONTROLS';
            obj.hFig.Resize = 'off';
            
            obj.makeWindow();
            obj.onDemandElements = cellfun(@(tag)findobj(obj.hFig,'Tag',tag),onDemandTags(),'UniformOutput',false);
            obj.sequenceElements = cellfun(@(tag)findobj(obj.hFig,'Tag',tag),sequenceTags(),'UniformOutput',false);
            
            obj.addListeners();
            
            set(obj.hFig,'KeyPressFcn',@(src,evt)obj.photostimHotKey(src,evt));
            obj.redraw();
        end
    end
    
    methods
        function forceInitGui(obj)
            obj.initGui();
        end
    end
    
    %% GUI/DATA CONSTRUCTION
    methods (Access=protected,Hidden)
        function makeWindow(obj)
            hFlMain = most.gui.uiflowcontainer('Parent',obj.hFig,'FlowDirection','TopDown');
            hFlControl = most.gui.uiflowcontainer('Parent',hFlMain,'FlowDirection','LeftToRight','HeightLimits',[285, 285]);
            obj.makeStimGroupsPanel(hFlControl);
            obj.makeStimConfigPanel(hFlControl);
            hFlStatus = most.gui.uiflowcontainer('Parent',hFlMain,'FlowDirection','LeftToRight','HeightLimits',[80 80]);
            obj.makeStatusPanel(hFlStatus);
        end
        
        function makeStimGroupsPanel(obj,hFlParent)
            flo = most.gui.uiflowcontainer('Parent',hFlParent,'FlowDirection','TopDown','WidthLimits',[150 150]);
            hFlHeightLimit = most.gui.uiflowcontainer('Parent',flo,'FlowDirection','LeftToRight','HeightLimits',[280 280]);
            hPanel = uipanel('Parent',hFlHeightLimit,'Title', 'Stimulus Groups:');
            % Table shows all of the beams
            columnFormat = {'char'};
            columnEditable = false;
            columnName = {'Stimulus Groups'};
            columnWidth = {127};
            
            hPanelFlow = most.gui.uiflowcontainer('Parent', hPanel, 'FlowDirection','TopDown');
            hTblBeamsFlow = most.gui.uiflowcontainer('Parent',hPanelFlow,'FlowDirection','LeftToRight','HeightLimits',[210 210]);
            obj.stimGroupsTable = uitable('Parent',hTblBeamsFlow,'ColumnName',columnName,'ColumnWidth',columnWidth,'ColumnEditable',columnEditable,'ColumnFormat',columnFormat,'CellSelectionCallback',{@obj.tableCellSelectionCallback,obj.hFig},'RowName',{},'RowStriping','off');
            
            upChar =  ['<html><table border=0 width=16><TR><TD><center>' most.constants.Unicode.upwards_arrow  '</center></TD></TR></table></html>'];
            downChar =  ['<html><table border=0 width=16><TR><TD><center>' most.constants.Unicode.downwards_arrow  '</center></TD></TR></table></html>'];
            
            hButtonFlow = most.gui.uiflowcontainer('Parent',hPanelFlow,'FlowDirection','LeftToRight','HeightLimits',[20 20]);
            obj.pbNewRg = most.gui.uicontrol('Parent',hButtonFlow,'Style','pushbutton','Tag','pbNewRg','String','New','callback',@obj.addStimGroup);
            obj.pbEditRg = most.gui.uicontrol('Parent',hButtonFlow,'Style','pushbutton','Tag','pbEditRg','String','Edit','callback',@obj.editStimGroup);
            obj.pbMoveRgUp = most.gui.uicontrol('Parent',hButtonFlow,'Style','pushbutton','Tag','pbMoveRgUp','String',upChar,'callback',@obj.moveStimGroupUp);
            hButtonFlow2 = most.gui.uiflowcontainer('Parent',hPanelFlow,'FlowDirection','LeftToRight','HeightLimits',[20 20]);
            obj.pbCopyRg = most.gui.uicontrol('Parent',hButtonFlow2,'Style','pushbutton','Tag','pbCopyRg','String','Copy','callback',@obj.copyStimGroup);
            obj.pbDeleteRg = most.gui.uicontrol('Parent',hButtonFlow2,'Style','pushbutton','Tag','pbDeleteRg','String','Delete','callback',@obj.remStimGroup);
            obj.pbMoveRgDown = most.gui.uicontrol('Parent',hButtonFlow2,'Style','pushbutton','Tag','pbMoveRgUp','String',downChar,'callback',@obj.moveStimGroupDown);
        end
        
        function makeStimConfigPanel(obj,hFlParent)
            flo = most.gui.uiflowcontainer('Parent',hFlParent,'FlowDirection','TopDown','WidthLimits',[235 235]);
            hFlHeightLimit = most.gui.uiflowcontainer('Parent',flo,'FlowDirection','LeftToRight','HeightLimits',[280 280]);
            hPanel = uipanel('Parent',hFlHeightLimit,'Title','Settings');
            
            most.gui.uicontrol('Parent',hPanel,'Style','text','Tag','txMode','String','Photostim Mode:','RelPosition', [2.60000000000002 58.0000000000001 90 40]);
            obj.pmMode = most.gui.uicontrol('Parent',hPanel,'Style','popupmenu','Tag','pmMode','String',{''},'RelPosition', [95.6 41.0000000000001 117 25],'callback',@obj.pmModeCallback);
            
            most.gui.uicontrol('Parent',hPanel,'Style','text','Tag','txTriggerSource','String','Trigger Source:','RelPosition', [11.6 62.6 80 25]);
            obj.pmTriggerSource = most.gui.uicontrol('Parent',hPanel,'Style','popupmenu','Tag','pmTriggerSource','String',{''},'RelPosition', [95.6 60.4 117 24],'callback',@obj.pmTriggerSourceCallback);
            
            obj.txSyncSource = most.gui.uicontrol('Parent',hPanel,'Style','text','Tag','txSyncSource','String','Sync Source:','RelPosition', [20.8 99.5999999999999 70 40]);
            obj.pmSyncSource = most.gui.uicontrol('Parent',hPanel,'Style','popupmenu','Tag','pmSyncSource','String',{''},'RelPosition', [95.4 77.2 117 20],'callback',@obj.pmSyncSourceCallback);
            
            obj.cbStimImmediately = most.gui.uicontrol('Parent',hPanel,'Style','checkbox','Tag','cbStimImmediately','String','Stim immediately','RelPosition', [10.8 95.3999999999999 99 14],'callback',@obj.cbStimImmediatelyCallback);
            
            % On Demand only
            obj.cbAllowMultiOutput = most.gui.uicontrol('Parent',hPanel,'Style','checkbox','Tag','cbAllowMultiOutput','String','Allow Multiple Outputs','RelPosition', [10.6000000000001 110.8 135 15],'callback',@obj.cbAllowMultiOutputCallback);
            obj.cbEnableHotKeys = most.gui.uicontrol('Parent',hPanel,'Style','checkbox','Tag','cbEnableHotKeys','String','Enable hotkeys (0-9, t, s, a)','RelPosition', [10.2 124.4 190 15]);
            
            offsetx = 4;
            offsety = 128;
            obj.extStimSelPanel = most.gui.uicontrol('Parent',hPanel,'Style','uipanel','Tag','pExternalStimulus','Title','External Stimulus Selection:','RelPosition', [4.20000000000002 197.8 218 70]);
            obj.txExtStimSelTrigTerm = most.gui.uicontrol('Parent',obj.extStimSelPanel.hCtl,'Style','text','Tag','txExtStimSelTrigTerm','String','Trig Term:','RelPosition', [9.59999999999999-offsetx 174-offsety 51 25]);
            obj.pmExtStimSelTrigTerm = most.gui.uicontrol('Parent',obj.extStimSelPanel.hCtl,'Style','popupmenu','Tag','pmExtStimSelTrigTerm','String',{''},'RelPosition', [8.6-offsetx 187.2-offsety 55 20],'callback',@obj.pmExtStimSelTrigTermCallback);
            obj.txExtStimSelTerms = most.gui.uicontrol('Parent',obj.extStimSelPanel.hCtl,'Style','text','Tag','txExtStimSelTerms','String','Terms','RelPosition', [73-offsetx 171.4-offsety 36 23]);
            obj.etExtStimSelTerms = most.gui.uicontrol('Parent',obj.extStimSelPanel.hCtl,'Style','edit','Tag','etExtStimSelTerms','String','','RelPosition', [115.2-offsetx 165.8-offsety 100 20],'callback',@obj.etExtStimSelTermsCallback);
            obj.txExtStimSelRg = most.gui.uicontrol('Parent',obj.extStimSelPanel.hCtl,'Style','text','Tag','txExtStimSelRg','String','Stimuli','RelPosition', [71.6-offsetx 193-offsety 39 20]);
            obj.etExtStimSelRg = most.gui.uicontrol('Parent',obj.extStimSelPanel.hCtl,'Style','edit','Tag','etExtStimSelRg','String','','RelPosition', [115.6-offsetx 190.8-offsety 100 20],'callback',@obj.etExtStimSelRgCallback);
            
            % Sequence only
            most.gui.uicontrol('Parent',hPanel,'Style','text','Tag','txStimSequence','String','Stimulus Group Sequence:','RelPosition', [24 129 137 12]);
            obj.etStimSequence = most.gui.uicontrol('Parent',hPanel,'Style','edit','Tag','etStimSequence','String','','RelPosition', [25.8 157 167 23],'callback',@obj.etStimSequenceCallback);
            most.gui.uicontrol('Parent',hPanel,'Style','text','Tag','txNumSequences','String','Number of sequences','RelPosition', [26 198.8 108 27]);
            obj.etNumSequences = most.gui.uicontrol('Parent',hPanel,'Style','edit','Tag','etNumSequences','String','','RelPosition', [139.6 188.2 52 20],'callback',@obj.etNumSequencesCallback);
            
            %Montioring
            hMonitorPanel = most.gui.uicontrol('Parent',hPanel,'Style','uipanel','Tag','pMonitor','Title','Monitor','RelPosition', [4.20000000000002 237 218 39]);
            obj.cbMonitorShow = most.gui.uicontrol('Parent',hMonitorPanel.hCtl,'Style','checkbox','Tag','cbMonitorShow','String','Show','RelPosition', [13.6 43.2 50 40],'callback',@obj.cbMonitorShowCallback);
            obj.cbMonitorLogging = most.gui.uicontrol('Parent',hMonitorPanel.hCtl,'Style','checkbox','Tag','cbMonitorLogging','String','Logging','RelPosition', [73.4 42.4 60 40],'callback',@obj.cbMonitorLoggingCallback);
            obj.pbCalibrate = most.gui.uicontrol('Parent',hMonitorPanel.hCtl,'Style','pushbutton','Tag','pbCalibrate','String','Calibrate','RelPosition', [144.8 33.8 61 20],'callback',@obj.pbCalibrateCallback);
            
            %Main buttons
            obj.pbAbort = most.gui.uicontrol('Parent',hPanel,'Style','pushbutton','Tag','pbAbort','String','Start','RelPosition', [4.39999999999998 271 60 30],'FontSize',10,'FontWeight','bold','ForegroundColor',most.constants.Colors.darkGreen,'callback',@obj.pbAbortCallback);
            obj.pbTrigger = most.gui.uicontrol('Parent',hPanel,'Style','pushbutton','Tag','pbTrigger','String','Trigger','RelPosition', [71.0000000000001 270.8 80 30],'FontSize',10,'FontWeight','bold','ForegroundColor',most.constants.Colors.darkGreen,'callback',@obj.pbTriggerCallback);
            obj.pbSync = most.gui.uicontrol('Parent',hPanel,'Style','pushbutton','Tag','pbSync','String','Sync','RelPosition', [156 270.8 60 30],'FontSize',10,'FontWeight','bold','ForegroundColor',most.constants.Colors.darkGreen,'callback',@obj.pbSyncCallback);
        end
        
        function makeStatusPanel(obj,hFlParent)
            hStatusPanel = most.gui.uicontrol('Parent',hFlParent,'Style','uipanel','Tag','pStatus','RelPosition', [4.20000000000002 0 385 80],'BorderType','none');
            most.gui.uicontrol('Parent',hStatusPanel.hCtl,'Style','text','Tag','txStatus','String','Status','RelPosition', [-57 23.4 172 21]);
            obj.etStatus = most.gui.uicontrol('Parent',hStatusPanel.hCtl,'Style','edit','Tag','etStatus','String','Offline','RelPosition', [64.8 20.8 309 20],'Enable','off');
            
            most.gui.uicontrol('Parent',hStatusPanel.hCtl,'Style','text','Tag','txMotionCorrection','String','Motion Correction','RelPosition', [-5.2 64 72 37]);
            obj.etMotionCorrection = most.gui.uicontrol('Parent',hStatusPanel.hCtl,'Style','edit','Tag','etMotionCorrection','String',{''},'RelPosition', [64 51 60 23],'Enable','off');
            
            most.gui.uicontrol('Parent',hStatusPanel.hCtl,'Style','text','Tag','txScanner','String','Stim Scanner:','RelPosition', [126.4 55.6666666666667 80 22]);
            obj.pmScanner = most.gui.uicontrol('Parent',hStatusPanel.hCtl,'Style','popupmenu','Tag','pmScanner','String',{''},'RelPosition', [202.266666666667 53.9333333333334 171 24],'callback',@obj.changeScanner);
        end
        
        function addListeners(obj)
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'status','PostSet',@obj.setStatus);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'primedStimulus','PostSet',@obj.highlightTableCells);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'nextStimulus','PostSet',@obj.highlightTableCells);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'active','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'hScan','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'stimRoiGroups','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'stimulusMode','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'sequenceSelectedStimuli','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'numSequences','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'allowMultipleOutputs','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'stimSelectionTriggerTerm','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'stimSelectionDevice','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'stimSelectionTerms','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'stimSelectionAssignment','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'stimTriggerTerm','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'syncTriggerTerm','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'stimImmediately','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'autoTriggerPeriod','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'monitoring','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'logging','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'compensateMotionEnabled','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'zMode','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'laserActiveSignalAdvance','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim,'lastMotion','PostSet',@obj.updateLastMotion);
        end
        
        function setIOlisteners(obj,hDIs)
            most.idioms.safeDeleteObj(obj.hIOListeners);
            obj.hIOListeners = event.listener.empty(1,0);
            
            for i = 1:length(hDIs)
                hDI = hDIs(i);
                obj.hIOListeners(end+1) = most.ErrorHandler.addCatchingListener(hDI,'lastKnownValueChanged',@(src,evt)obj.extTriggeredOnDemandStim(src,evt));
            end
        end
    end
    
    methods
        redraw(obj, varargin);
        
        function updateLastMotion(obj,varargin)
            obj.etMotionCorrection.String = sprintf('%2.1f , %2.1f',obj.lastMotion(1),obj.lastMotion(2));
        end
        
        function setStatus(obj,varargin)
            obj.etStatus.String = obj.status;
        end
    end
    
    % callbacks
    methods
        function tableCellSelectionCallback(obj,src,evt,hFig)
            if isempty(evt.Indices)
                return;
            end
            
            obj.currentlySelectedCell = evt.Indices(1);
            obj.highlightTableCells();
            
            % pause(0.2); % to allow the user time to add a second click
            row = evt.Indices(1);
            if any(strcmpi(hFig.SelectionType, {'open','alt','extend'})) %double click
                obj.dblClickStimGroup(row);
            else %single click
                if most.idioms.isValidObj(obj.hScan)
                    obj.hController.hRoiGroupEditor.Visible = true;
                    obj.RoiGroupSelection = row;
                    obj.hController.hRoiGroupEditor.setEditorGroupAndMode(obj.hModel.hPhotostim.stimRoiGroups(row),obj.hModel.hPhotostim.stimScannerset,'stimulation');
                else
                    most.idioms.warn('Select a stim scanner to bring up the stimulation ROI Group Editor.')
                end
            end
        end
        
        function pmModeCallback(obj,varargin)
            if obj.pmMode.Value == 1
                obj.stimulusMode = 'onDemand';
            else
                obj.stimulusMode = 'sequence';
                
%                if ~isempty(obj.hIOListeners)
%                    most.idioms.safeDeleteObj(obj.hIOListeners);
%                    obj.hIOListeners = event.listener.empty(1,0);
%                end
            end
        end
        
        function pmTriggerSourceCallback(obj,varargin)
            obj.stimTriggerTerm = obj.pmTriggerSource.pmValue;
        end
        
        function pmSyncSourceCallback(obj,varargin)
            obj.syncTriggerTerm = obj.pmSyncSource.pmValue;
        end
        
        function cbStimImmediatelyCallback(obj,varargin)
            obj.stimImmediately = obj.cbStimImmediately.Value;
        end
        
        function cbMonitorShowCallback(obj,varargin)
            try
                obj.hModel.hPhotostim.monitoring = obj.cbMonitorShow.Value;
            catch ME
                obj.loggingErr(ME,'monitoring');
            end
        end
        
        function loggingErr(obj, ME, var)
            obj.hModel.hPhotostim.logging = obj.hModel.hPhotostim.logging;
            
            if strncmp(ME.message, 'Photostim feedback calibration is invalid.',42);
                msg = [ME.message ' Calibrate now?'];
                if strcmp('Calibrate', questdlg(msg,'ScanImage','Cancel','Calibrate','Cancel'))
                    obj.pbCalibrateCallback();
                    obj.hModel.hPhotostim.(var) = v;
                else
                    obj.hModel.hPhotostim.(var) = false;
                end
            else
                obj.hModel.hPhotostim.(var) = obj.hModel.hPhotostim.(var);
                warndlg(ME.message,'ScanImage');
            end
        end
        
        function cbMonitorLoggingCallback(obj,varargin)
            try
                obj.hModel.hPhotostim.logging = obj.cbMonitorLogging.Value;
            catch ME
                obj.loggingErr(ME,'logging');
            end
        end
        
        function pbCalibrateCallback(obj,varargin)
            try
                obj.hModel.hPhotostim.calibrateMonitorAndOffset();
                obj.redraw();
            catch ME
                warndlg(ME.message,'ScanImage');
            end
        end
        
        function pbAbortCallback(obj,varargin)
            try
                if obj.hModel.hPhotostim.active
                    obj.hModel.hPhotostim.abort();
                else
                    obj.hModel.hPhotostim.start();
                end
            catch ME
                errordlg(ME.message, 'Photostim')
                ME.rethrow();
            end
        end
        
        function pbTriggerCallback(obj,varargin)
            try
                obj.hModel.hPhotostim.triggerStim();
            catch ME
                warndlg(ME.message, 'Photostim')
                ME.rethrow();
            end
        end
        
        function pbSyncCallback(obj, varargin)
            obj.hModel.hPhotostim.triggerSync();
        end
        
        function cbAllowMultiOutputCallback(obj,varargin)
            obj.allowMultipleOutputs = obj.cbAllowMultiOutput.Value;
        end
        
        function pmExtStimSelTrigTermCallback(obj,varargin)
            obj.stimSelectionTriggerTerm = obj.qualifyPortName(obj.pmExtStimSelTrigTerm.pmValue);
        end
        
        function etExtStimSelTermsCallback(obj,varargin)
            if isempty(obj.etExtStimSelTerms.String)
                obj.setIOlisteners([]); %clear IO listeners
                return;
            end
            
            if obj.hModel.hPhotostim.isVdaq
                termStrings = split(obj.etExtStimSelTerms.String);
                hDIs = dabs.resources.ios.DIO.empty(numel(termStrings),0);
                for termStringIdx = 1:numel(termStrings)
                    termString = sprintf('/vDAQ0/%s',termStrings{termStringIdx});
                    hDI = dabs.resources.ResourceStore.filterByNameStatic(termString);
                    hDIs(termStringIdx) = hDI;
                end
                
                obj.vDAQStimSelectionTerms = hDIs;
                
                if numel(obj.vDAQStimSelectionTerms) == numel(obj.stimSelectionAssignment)
                    obj.setIOlisteners(hDIs);
                end
            else
                obj.stimSelectionTerms = cellfun(@(str)obj.qualifyPortName(str) ...
                    , split(obj.etExtStimSelTerms.String));
            end
        end
        
        function etExtStimSelRgCallback(obj,varargin)
            obj.stimSelectionAssignment = str2num(obj.etExtStimSelRg.String);
            
            if obj.hModel.hPhotostim.isVdaq && numel(obj.stimSelectionTerms) == numel(obj.stimSelectionAssignment)
                obj.setIOlisteners(obj.vDAQStimSelectionTerms);
            end
        end
        
        function etStimSequenceCallback(obj,varargin)
            obj.sequenceSelectedStimuli = str2num(obj.etStimSequence.String);
        end
        
        function etNumSequencesCallback(obj,varargin)
            obj.numSequences = str2double(obj.etNumSequences.String);
        end
    end
    
    %% Extra callbacks
    methods
        
        function addStimGroup(obj, ~, ~)
            most.ErrorHandler.assert(~isempty(obj.hScan) ...
                , ['Stim scanner was not defined.To use the photostim module, ' ... 
                'select a stimulation scanner from the dropdown menu at the bottom ' ...
                'right of the PHOTOSTIMULATION CONTROLS window.']);
            
            if isempty(obj.hModel.hPhotostim.stimRoiGroups)
                obj.hModel.hPhotostim.stimRoiGroups = scanimage.mroi.RoiGroup('New stimulus group');
            else
                obj.hModel.hPhotostim.stimRoiGroups(end+1) = scanimage.mroi.RoiGroup('New stimulus group');
            end
            
            obj.currentlySelectedCell = numel(obj.hModel.hPhotostim.stimRoiGroups);
            obj.changedStimRoiGroups();
        end
        
        function remStimGroup(obj, ~, ~)
            if numel(obj.hModel.hPhotostim.stimRoiGroups)
                obj.hModel.hPhotostim.stimRoiGroups(obj.currentlySelectedCell) = [];
                
                if obj.currentlySelectedCell > numel(obj.hModel.hPhotostim.stimRoiGroups)
                    obj.currentlySelectedCell = numel(obj.hModel.hPhotostim.stimRoiGroups);
                end
                
                obj.changedStimRoiGroups();
            end
        end
        
        function editStimGroup(obj, ~, ~)
            if numel(obj.hModel.hPhotostim.stimRoiGroups)
                % obj.mroiGuiSetGroup(obj.hModel.hPhotostim.stimRoiGroups(v), 'StimulusField');
                obj.hController.hRoiGroupEditor.Visible = 'On';
                obj.hController.hRoiGroupEditor.setEditorGroupAndMode( ...
                    obj.hModel.hPhotostim.stimRoiGroups(obj.currentlySelectedCell) ...
                    , obj.hModel.hPhotostim.stimScannerset ...
                    , 'stimulation');
                obj.hController.hRoiGroupEditor.defaultStimPower = inf;
                obj.hController.showGUI('RoiGroupEditor');
            end
        end
        
        function copyStimGroup(obj, ~, ~)
            hPhotostim = obj.hModel.hPhotostim;
            if numel(hPhotostim.stimRoiGroups)
                hPhotostim.stimRoiGroups(end+1) = hPhotostim.stimRoiGroups(obj.currentlySelectedCell).copy();
                obj.currentlySelectedCell = numel(hPhotostim.stimRoiGroups);
                obj.changedStimRoiGroups();
            end
        end
        
        function moveStimGroupUp(obj, ~, ~)
            obj.moveStimGroup(-1);
        end
        
        function moveStimGroupDown(obj, ~, ~)
            obj.moveStimGroup(1);
        end
        
        function moveStimGroup(obj, dir)
            try
                assert(~obj.active,'Stim group order cannot be changed while Photostimulation component is active.');
                hPhotostim = obj.hModel.hPhotostim;
                numRoiGroups = numel(hPhotostim.stimRoiGroups);
                if 0 < numRoiGroups 
                    v = obj.currentlySelectedCell;
                    nv = v + dir;
                    
                    if (nv > 0) && (nv <= numRoiGroups)
                        hPhotostim.stimRoiGroups([v,nv]) = hPhotostim.stimRoiGroups([nv,v]);
                        obj.currentlySelectedCell = nv;
                    end
                    obj.highlightTableCells();
                    obj.changedStimRoiGroups();
                end
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end
        end
        
        function highlightTableCells(obj,varargin)
            if isempty(obj.hModel.hPhotostim.stimRoiGroups)
                return;
            end
            
            nms = {obj.hModel.hPhotostim.stimRoiGroups.name};
            nms = cellfun(@(str,idx)sprintf('%d: %s', idx, str), nms, num2cell(1:numel(nms)), 'UniformOutput', false);
            
            blueHighlight = @(text) [ ...
                '<html><table border=0 width=400 bgcolor=#7cc9f2><TR><TD>' ...
                , text ...
                , '</TD></TR> </table></html>'];
            
            data = nms';
            if obj.active
                if strcmpi(obj.stimulusMode,'sequence')
                    tableIndex = obj.hModel.hPhotostim.nextStimulus;
                else
                    tableIndex = obj.hModel.hPhotostim.primedStimulus;
                end
            else
                tableIndex = obj.currentlySelectedCell;
            end
            
            if ~isempty(tableIndex) && tableIndex <= size(data,1)
                data{tableIndex} = blueHighlight(data{tableIndex});
            end
            % clear table selection so that a single cell can issue consecutive 
            % cell selection callbacks for consecutive clicks.
            obj.stimGroupsTable.Data = data; 
        end
        
        function setWindowFocus(obj)
            % Stupid hack to put focus on the window.
            % MATLAB introduced a focus method in 2022a, but it only works for uifigures.
            % https://www.mathworks.com/help/matlab/ref/matlab.ui.figure.focus.html
            obj.hFig.Visible = 'off';
            pause(0);
            obj.hFig.Visible = 'on';
        end
        
        function photostimHotKey(obj,src,evt)
            assert(isa(evt,'matlab.ui.eventdata.KeyData') ...
                , 'Event is not of class matlab.ui.eventdata.KeyData');
            isHotkeyFeatureEnabled = obj.cbEnableHotKeys.hCtl.Max == obj.cbEnableHotKeys.Value;
            isStimOnDemand = strcmp(obj.stimulusMode, 'onDemand');
            if ~isHotkeyFeatureEnabled || ~isStimOnDemand || ~obj.active
                return;
            end

            hotkey = evt.Key;
            numpadValue = str2double(strrep(hotkey, 'numpad', ''));
            hPhotostim = obj.hModel.hPhotostim;
            if ~isnan(numpadValue)
                if 0 == numpadValue
                    obj.zeroshift = obj.zeroshift + 1;
                    fprintf('Enter second digit to output stimulus %d*...\n' ...
                        , obj.zeroshift);
                else
                    hotkey = 10 * obj.zeroshift + numpadValue;
                    fprintf('Sending stimulus %d command...\n', hotkey);
                    obj.zeroshift = 0;
                    obj.hModel.hPhotostim.onDemandStimNow(hotkey);
                end
                return;
            end

            switch hotkey
                case 't'
                    disp('Sending photostim trigger...');
                    hPhotostim.triggerStim();
                case 's'
                    disp('Sending photostim sync...');
                    hPhotostim.triggerSync();
                case 'a'
                    disp('Aborting photostim...');
                    hPhotostim.abort();
            end
            obj.zeroshift = 0;
        end
        
        function extTriggeredOnDemandStim(obj,src,evt)
            if strcmpi(obj.stimulusMode,'sequence')
                return;
            end
            
            stimIdx = src == obj.vDAQStimSelectionTerms;
            if src.lastKnownValue
                obj.hModel.hPhotostim.onDemandStimNow(obj.stimSelectionAssignment(stimIdx));
            end
        end
    end
    
    
    %% PHOTOSTIM METHODS
    methods
        function changeScanner(obj,varargin)
            obj.hScan = obj.pmScanner.pmValue;
            
            scannerIsValid = most.idioms.isValidObj(obj.hScan);
            if most.idioms.isValidObj(obj.hScan)
                obj.hModel.hPhotostim.reinit();
                obj.pmSyncSourceCallback();
            end
            set([obj.pbAbort obj.pbTrigger obj.pbSync], 'Enable', most.gui.OnOff(scannerIsValid));
        end
        
        function changedStimRoiGroups(obj,src,evnt)
            obj.redraw();
            
            % add listener to name properties
            obj.stimRoiGroupNameListeners.delete(); % event listeners should not need safeDeleteObj
            obj.stimRoiGroupNameListeners = most.ErrorHandler.addCatchingListener(obj.hModel.hPhotostim.stimRoiGroups, 'name', 'PostSet', @obj.changedStimRoiGroupName);
            
            obj.setIOlisteners(obj.vDAQStimSelectionTerms);
        end
        
        function changedStimRoiGroupName(obj,~,~)
            if numel(obj.hModel.hPhotostim.stimRoiGroups)
                % update list
                nms = {obj.hModel.hPhotostim.stimRoiGroups.name};
                nms = cellfun(@(str,idx)sprintf('%d: %s', idx, str), nms, num2cell(1:numel(nms)), 'UniformOutput', false);
                obj.stimGroupsTable.Data = nms';
            end
        end
        
        function dblClickStimGroup(obj, idx)
            if obj.hModel.hPhotostim.active
                if strcmp(obj.hModel.hPhotostim.stimulusMode, 'onDemand')
                    fprintf('Sending stimulus %d command...\n', idx);
                    obj.hModel.hPhotostim.onDemandStimNow(idx);
                end
            else
                %                 obj.mroiGuiSetGroup(obj.hModel.hPhotostim.stimRoiGroups(idx), 'StimulusField');
                obj.hController.hRoiGroupEditor.Visible = true;
                obj.hController.hRoiGroupEditor.finishPowerBoxEdit();
                obj.hController.hRoiGroupEditor.setEditorGroupAndMode(obj.hModel.hPhotostim.stimRoiGroups(idx),obj.hModel.hPhotostim.stimScannerset,'stimulation');
                obj.hController.hRoiGroupEditor.defaultStimPower = inf;
                obj.hController.showGUI('RoiGroupEditor');
            end
        end
    end
    
    %% UTILITY METHODS
    methods
        function v = qualifyPortName(obj, v)
            if isempty(v)
                v = '';
                return;
            end
            
            if obj.hModel.hPhotostim.isVdaq
                % It is unclear if the following comments are suggestions, todo
                % items or appeals to an Elder God. The Deep History Archival
                % Society has requested the immediate archival and isolation of
                % the following inscriptions. DO NOT MODIFY.
                
                %Split strings
                %For each string, check if it can be passed to
                %photostim as is or modify to send to photostim
                return;
            end
            
            % Use str2num here because Port numbers could be evaluatable.
            % Furthermore, the regex is set up in such a way that PFI0 is not 
            % possible. If allowed, this ends up breaking the Photostim model itself.
            valueExtent = regexp(v, '([1-9]\d*)', 'tokenExtents', 'once');
            v = str2num(v(valueExtent(1):valueExtent(2)));
        end
    end
end

function out = onDemandTags()
    out = {'cbAllowMultiOutput',...
        'cbEnableHotKeys',...
        'pExternalStimulus',...
        'txExtStimSelTrigTerm',...
        'pmExtStimSelTrigTerm',...
        'txExtStimSelTerms',...
        'etExtStimSelTerms',...
        'txExtStimSelRg',...
        'etExtStimSelRg'};
end

function out = sequenceTags()
    out = {'txStimSequence',...
        'etStimSequence',...
        'txNumSequences',...
        'etNumSequences'};
end

function out = allUIElements()
    out = {'stimGroupsTable'
        
    'pbNewRg'
    'pbEditRg'
    'pbCopyRg'
    'pbDeleteRg'
    
    'pmMode'
    'pmTriggerSource'
    'pmSyncSource'  % NI only
    
    'cbStimImmediately'
    
    'cbMonitorShow'
    'cbMonitorLogging'
    
    'pbCalibrate'
    
    'pbAbort'
    'pbTrigger'
    'pbSync'
    
    'etStatus'
    'etMotionCorrection'
    
    'onDemandElements'
    'cbAllowMultiOutput'
    'cbEnableHotKeys'
    
    'pmExtStimSelTrigTerm'
    'txExtStimSelTrigTerm'
    'etExtStimSelTerms'
    'txExtStimSelTerms'
    'etExtStimSelRg'
    'txExtStimSelRg'
    
    'sequenceElements'
    'etStimSequence'
    'etNumSequences'};
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

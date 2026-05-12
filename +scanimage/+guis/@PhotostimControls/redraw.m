function redraw(obj,varargin)
    %% Update Table
    isVdaq = isa(obj.hScan, 'scanimage.components.scan2d.RggScan') ...
        || (isa(obj.hScan, 'scanimage.components.scan2d.SlmScan') && obj.hScan.hAcq.isVdaq);

    % update name list
    StimGroups = obj.hModel.hPhotostim.stimRoiGroups;
    stimGroupNames = cell(size(StimGroups));
    for iStimGroup = 1:numel(StimGroups)
        stimGroupNames{iStimGroup} = sprintf('%d: %s', iStimGroup, StimGroups(iStimGroup).name);
    end
    if ~iscolumn(stimGroupNames)
        stimGroupNames = stimGroupNames .';
    end
    obj.stimGroupsTable.Data = stimGroupNames;
    if ~isempty(StimGroups)
        obj.highlightTableCells();
    end

     offWhenhScanEmpty = most.gui.OnOff(~isempty(obj.hScan));
    
    %% Update based on active state
    if obj.active
        obj.pbAbort.String = 'Abort';
        obj.pbAbort.hCtl.ForegroundColor = most.constants.Colors.red;
        obj.etStatus.Enable = 'inactive';
        if obj.hModel.hMotionManager.enable
            obj.etMotionCorrection.Enable = 'inactive';
        end
    else
        obj.pbAbort.String = 'Start';
        obj.pbAbort.hCtl.ForegroundColor = most.constants.Colors.darkGreen;
        obj.etStatus.Enable = 'off';
        obj.etMotionCorrection.Enable = 'off';
    end
    
    offOnlyWhenActive = most.gui.OnOff(~obj.active);
    offWhenActiveAndhScanEmpty = most.gui.OnOff(~obj.active && ~isempty(obj.hScan));
    obj.pbCopyRg.Enable = offWhenActiveAndhScanEmpty;
    obj.pbDeleteRg.Enable = offWhenActiveAndhScanEmpty;
    obj.pbEditRg.Enable = offWhenhScanEmpty;
    obj.pbEditRg.String = most.idioms.ifthenelse(obj.active,'Show','Edit');
    obj.pbMoveRgDown.Enable = offWhenActiveAndhScanEmpty;
    obj.pbMoveRgUp.Enable = offWhenActiveAndhScanEmpty;
    obj.pbNewRg.Enable = offWhenActiveAndhScanEmpty;
    obj.pmExtStimSelTrigTerm.Enable = offOnlyWhenActive;
    obj.pmMode.Enable = offOnlyWhenActive;
    obj.pmScanner.Enable = offOnlyWhenActive;
    obj.pmTriggerSource.Enable = offOnlyWhenActive;
    obj.pmSyncSource.Enable = offOnlyWhenActive;
    obj.etExtStimSelTerms.Enable = offOnlyWhenActive;
    obj.pbCalibrate.Enable = offOnlyWhenActive;
    obj.etStimSequence.Enable = offOnlyWhenActive;
    obj.stimGroupsTable.Enable = offWhenhScanEmpty;
    
    onOnlyWhenActive = most.gui.OnOff(obj.active);
    obj.pbTrigger.Enable = onOnlyWhenActive;
    obj.pbSync.Enable = onOnlyWhenActive;
    
    onIfScannerIsValid = most.gui.OnOff(most.idioms.isValidObj(obj.hScan));
    obj.pbAbort.Enable = onIfScannerIsValid;
    obj.pmExtStimSelTrigTerm.Enable = onIfScannerIsValid;
    obj.pmMode.Enable = onIfScannerIsValid;
    obj.pmTriggerSource.Enable = onIfScannerIsValid;
    obj.pmSyncSource.Enable = onIfScannerIsValid;
    obj.etExtStimSelTerms.Enable = onIfScannerIsValid;
    obj.pbCalibrate.Enable = onIfScannerIsValid;
    obj.etStimSequence.Enable = onIfScannerIsValid;
    
    %% Update based on Stim mode
    obj.pmMode.String = {'On Demand', 'Sequence'};
    if strcmpi(obj.stimulusMode, 'onDemand')
        obj.pmMode.pmValue = 'On Demand';
        cellfun(@(el)set(el,'Visible','off'),obj.sequenceElements);
        cellfun(@(el)set(el,'Visible','on'),obj.onDemandElements);
    else
        obj.pmMode.pmValue = 'Sequence';
        cellfun(@(el)set(el,'Visible','off'),obj.onDemandElements);
        cellfun(@(el)set(el,'Visible','on'),obj.sequenceElements);
    end
    
    %% Update based on stimulation system
    if most.idioms.isValidObj(obj.hScan)
        if isVdaq
            DINames = unique([{obj.hScan.hDAQ.hDIOs.channelName}, {obj.hScan.hDAQ.hDIs.channelName}]);
            DINames = most.util.natsort(DINames);
            triggerSourceNames = [{''}, {'frame'}, DINames];
            currentStimTriggerTerm = obj.stimTriggerTerm;
            currentSyncTriggerTerm = obj.syncTriggerTerm;
            obj.extStimSelPanel.Visible = 'off';
        else
            DINames = unique({obj.hScan.hDAQAux.hPFIs.channelName});
            DINames = most.util.natsort(DINames);
            triggerSourceNames = [{'frame'}, DINames]; % NI Photostim cannot have a blank trigger source
            currentStimTriggerTerm = most.idioms.ifthenelse(strcmpi(obj.stimTriggerTerm, 'frame') ...
                , 'frame' ...
                , sprintf('PFI%g', obj.stimTriggerTerm));
            currentSyncTriggerTerm = most.idioms.ifthenelse(strcmpi(obj.syncTriggerTerm, 'frame') ...
                ,'frame' ...
                , sprintf('PFI%g',obj.syncTriggerTerm));
        end
        
        obj.pmTriggerSource.String = triggerSourceNames;
        if ~isempty(obj.stimTriggerTerm)
            obj.pmTriggerSource.pmValue = currentStimTriggerTerm;
        end
        
        obj.pmSyncSource.String = [{''}, {'frame'} DINames];
        if ~isempty(obj.syncTriggerTerm)
            obj.pmSyncSource.pmValue = currentSyncTriggerTerm;
        end
    end
    
    set([obj.pmSyncSource, obj.txSyncSource, obj.pbSync] ...
        , 'Visible', most.gui.OnOff(~isVdaq));
    
    %% Update common properties
    obj.cbStimImmediately.Value = obj.stimImmediately;
    obj.cbMonitorLogging.Value = obj.logging;
    obj.etStatus.String = obj.status;
    obj.etMotionCorrection.String = sprintf('%2.1f , %2.1f',obj.lastMotion(1),obj.lastMotion(2));
    
    % Update On Demand properties only
    obj.cbAllowMultiOutput.Value = obj.allowMultipleOutputs;
    
    offIfIsVdaq = most.gui.OnOff(~isVdaq);
    set([obj.txExtStimSelTrigTerm, obj.pmExtStimSelTrigTerm], 'Visible', offIfIsVdaq);
    
    if most.idioms.isValidObj(obj.hScan)
        % filter out PFI0 since setting the terminal to zero breaks the Photostim control.
        selections = [{''}, DINames];
        isPfiZero = strcmp(selections, 'PFI0');
        obj.pmExtStimSelTrigTerm.String = selections(~isPfiZero);
        if isempty(obj.stimSelectionTriggerTerm)
            obj.pmExtStimSelTrigTerm.pmValue = '';
        else
            if isVdaq
                extStimSelTermString = sprintf('D%g',obj.stimSelectionTriggerTerm);
            else
                extStimSelTermString = sprintf('PFI%g',obj.stimSelectionTriggerTerm);
            end
            
            obj.pmExtStimSelTrigTerm.pmValue = extStimSelTermString;
        end
    end
    
    if isVdaq
        obj.txExtStimSelTerms.RelPosition  = [-15.0000, 43.4000, 90.0000, 23.0000];
        obj.etExtStimSelTerms.RelPosition =  [57.2      37.8     154      20];
        obj.txExtStimSelRg.RelPosition =     [-15       65       93       20];
        obj.etExtStimSelRg.RelPosition  =    [57.6      62.8     154      20];
    else
        obj.txExtStimSelTerms.RelPosition = [69    43   36  23];
        obj.etExtStimSelTerms.RelPosition = [111.2 37.8 100 20];
        obj.txExtStimSelRg.RelPosition =    [67.6  65   39  20];
        obj.etExtStimSelRg.RelPosition =    [111.6 62.8 100 20];
    end
    
    if isVdaq && ~isempty(obj.vDAQStimSelectionTerms)
        extStimSelTermStrings = cell(numel(obj.vDAQStimSelectionTerms),1);
        
        for iStringIndex = 1:numel(obj.vDAQStimSelectionTerms)
            extStimSelTermStrings{iStringIndex} = obj.vDAQStimSelectionTerms(iStringIndex).channelName;
        end
    elseif ~isempty(obj.stimSelectionTerms)
        extStimSelTermStrings = cell(numel(obj.stimSelectionTerms),1);
        
        for iStringIndex = 1:numel(obj.stimSelectionTerms)
            extStimSelTermStrings{iStringIndex} = sprintf('PFI%g',obj.stimSelectionTerms(iStringIndex));
        end
    else
        extStimSelTermStrings = {''};
    end
    obj.etExtStimSelTerms.String = strjoin(extStimSelTermStrings,'  ');
    
    obj.etExtStimSelRg.String = num2str(obj.stimSelectionAssignment);
    
    % Sequence only
    obj.etStimSequence.String = num2str(obj.sequenceSelectedStimuli);
    obj.etNumSequences.String = num2str(obj.numSequences);
    
    if strcmpi(obj.stimulusMode,'Sequence')
        % Stim Immediately just initiates the first stim upon starting the stim component.
        % No point to changing it after starting.
        obj.cbStimImmediately.Enable = offOnlyWhenActive;
    end
    
    %% Monitoring
    if most.idioms.isValidObj(obj.hScan)
        isSLMWithoutGalvos = isa(obj.hScan,'scanimage.components.scan2d.SlmScan') && isempty(obj.hScan.hLinScan);
        isSLMWithGalvos = isa(obj.hScan,'scanimage.components.scan2d.SlmScan') && ~isempty(obj.hScan.hLinScan);

        if isSLMWithoutGalvos
            isMonitoringEnabled = false;
        else
            if isSLMWithGalvos
                xGalvo = obj.hScan.hLinScan.xGalvo;
                yGalvo = obj.hScan.hLinScan.yGalvo;
            else
                xGalvo = obj.hScan.xGalvo;
                yGalvo = obj.hScan.yGalvo;
            end
            isMonitoringEnabled = xGalvo.feedbackCalibrated && yGalvo.feedbackCalibrated;
        end
    else
        isMonitoringEnabled = false;
    end
    set([obj.cbMonitorLogging, obj.cbMonitorShow], 'Enable', most.gui.OnOff(isMonitoringEnabled));
    
    %% Scanner
    allScanners = obj.hModel.hResourceStore.filterByClass({ ...
        'scanimage.components.scan2d.RggScan' ...
        , 'scanimage.components.scan2d.LinScan' ...
        , 'scanimage.components.scan2d.SlmScan' ...
        });
    stimCapableScanners = {};
    for iScanner = 1:numel(allScanners)
        Scanner = allScanners{iScanner};
        if Scanner.hasXGalvo || isa(Scanner,'scanimage.components.scan2d.SlmScan')
            stimCapableScanners{end+1} = Scanner;
        end
    end
    
    obj.pmScanner.String = [{''}, stimCapableScanners];
    if most.idioms.isValidObj(obj.hScan)
        if isempty(obj.hScan.hSlmScan)
            obj.pmScanner.pmValue = obj.hScan.name;
        else
            obj.pmScanner.pmValue = obj.hScan.hSlmScan.name;
        end
    else
        obj.pmScanner.pmValue = '';
    end
    
    obj.raise();
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

classdef Control < scanimage.interfaces.Class
    properties (Hidden)
        hScan;
    end
    
    properties (Hidden, Dependent)
        hFpga;
        hAcqEngine;
        
        useScannerSampleClk;
    end
    
    % Live Values - these properties can be updated during an active acquisition
    properties (Dependent)
        galvoParkVoltsX;
        galvoParkVoltsY;
    end
    
    % Internal Parameters
    properties (SetAccess = private, Dependent, Hidden)
        xGalvoExists;
        simulated;
    end
    
    properties (SetAccess = private, Hidden)
        hAOTaskGalvo;
        hAOTaskBeams;
        hAOTaskZ;
        
        hStream;
        
        acquisitionActive = false;
        
        activeFlag = false;
        
        galvoBufferLength = [];
        beamBufferLength = [];
        zBufferLength = [];
    end
    
    properties (Hidden)
        scannerSampsPerPeriod;
        waveformLenthPeriods;
        waveformResampLength;
    end
    
    %% Lifecycle
    methods
        function obj = Control(hScan)
            if nargin < 1 || isempty(hScan)
                hScan = [];
            end
            
            obj.hScan = hScan;
        end
        
        function delete(obj)
            try
                if obj.acquisitionActive
                    obj.stop();
                end
                
                % disable resonant scanner (may still be on depending on setting)
                if most.idioms.isValidObj(obj.hScan.hResonantScanner)
                    try
                        obj.hScan.hResonantScanner.park();
                    catch ME
                        most.ErrorHandler.logAndReportError(ME);
                    end
                end
                
                obj.deleteTasks();
            catch ME
                obj.deleteTasks();
                rethrow(ME);
            end
        end
    end
    
    %% Public Methods
    methods
        function start(obj)
            assert(~obj.acquisitionActive,'Acquisition is already active');
            % Reconfigure the Tasks for the selected acquisition Model
            obj.createTasks(); % create tasks
            obj.setupSampleClk();
            
            if obj.hScan.isStreamScanning
                hMotors = obj.hScan.hSI.hMotors;
                obj.hStream.relativePosition = hMotors.axesPosition([1 2]);
            end
            
            galvoPoints = obj.updateTaskCfg();            
            % this pause needed for the Resonant Scanner to reach
            % its amplitude and send valid triggers
            obj.activeFlag = true;
            % during resonantScannerWaitSettle a user might have clicked
            % 'abort' - which in turn calls obj.abort and unreserves
            % obj.hAOTaskGalvo; catch this by checking obj.activeflag
            if ~obj.activeFlag
                errorStruct.message = 'Soft error: ResScan was aborted before the resonant scanner could settle.';
                errorStruct.identifier = '';
                errorStruct.stack = struct('file',cell(0,1),'name',cell(0,1),'line',cell(0,1));
                error(errorStruct); % this needs to be an error, so that Scan2D will be aborted correctly
            end
                        
            if most.idioms.isValidObj(obj.hScan.xGalvo)
                obj.hScan.xGalvo.pointPosition_V(galvoPoints(1,1));
            end
            
            if most.idioms.isValidObj(obj.hScan.yGalvo)
                obj.hScan.yGalvo.pointPosition_V(galvoPoints(1,end));
            end
            
            if ~obj.simulated                
                obj.hAOTaskGalvo.start();
                
                if ~isempty(obj.hAOTaskBeams.channels)
                    obj.hAOTaskBeams.start();
                end
                
                if ~isempty(obj.hAOTaskZ.channels) && obj.hScan.hSI.hFastZ.outputActive
                    obj.hAOTaskZ.start();
                end
                
                if obj.hScan.isStreamScanning
                    obj.hStream.start();
                end
                
                obj.hScan.liveScannerFreq = [];
                obj.hScan.lastLiveScannerFreqMeasTime = [];
            end
            
            obj.acquisitionActive = true;
        end
        
        function stop(obj,soft)
            if nargin < 2 || isempty(soft)
                soft = false;
            end
            
            obj.deleteTasks(); % delete tasks
            
            obj.activeFlag = false;
            
            %Park scanner
            % parkGalvo() has to be called after acquisitionActive is set to
            % false, otherwise we run into an infinite loop
            obj.acquisitionActive = false;
            if ~obj.simulated
                obj.parkGalvo();
                if obj.hScan.isStreamScanning && most.idioms.isValidObj(obj.hStream)
                    obj.hStream.abort();
                    hMotor = obj.hScan.hSI.hMotors.hMotorXYZ{2};
                    hMotor.stop();
                    if ~isempty(obj.hStream.relativePosition)
                        hMotor.move(obj.hStream.relativePosition(obj.hStream.deviceAxisNumbers));
                    end
                end
            end
            
            if obj.hScan.scanModeIsResonant
                if (obj.hScan.keepResonantScannerOn || soft)
                    % NO-op
                else
                    try
                        obj.hScan.hResonantScanner.park();
                    catch ME
                        most.ErrorHandler.logAndReportError(ME);
                    end
                end
            end
        end
        
        function parkGalvo(obj)
            assert(~obj.acquisitionActive,'Cannot park galvo while scanner is active');
            
            if most.idioms.isValidObj(obj.hScan.xGalvo)
                try
                    obj.hScan.xGalvo.park();
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
            
            if most.idioms.isValidObj(obj.hScan.yGalvo)
                try
                    obj.hScan.yGalvo.park();
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
        end
        
        function centerGalvo(obj)
            assert(~obj.acquisitionActive,'Cannot center galvo while scanner is active');
            
            if most.idioms.isValidObj(obj.hScan.xGalvo)
                try
                    obj.hScan.xGalvo.center();
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
            
            if most.idioms.isValidObj(obj.hScan.yGalvo)
                try
                    obj.hScan.yGalvo.center();
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
        end
        
        function updateLiveValues(obj,regenAO,waveforms)
            if nargin < 2
                regenAO = true;
            end
            
            if nargin < 3
                waveforms = 'RGBZ';
            end
            
            if obj.acquisitionActive
                try
                    if regenAO
                        obj.hScan.hSI.hWaveformManager.updateWaveforms();
                    end
                    
                    obj.updateTaskCfg(true,waveforms);
                catch ME
                    % ignore DAQmx Error 200015 since it is irrelevant here
                    % Error message: "While writing to the buffer during a
                    % regeneration the actual data generated might have
                    % alternated between old data and new data."
                    if isempty(strfind(ME.message, '200015'))
                        rethrow(ME)
                    end
                end
            else
                % if the parking position for the Galvo was updated, apply
                % the new settings.
                obj.parkGalvo();
            end
        end
    end
    
    %% Private Methods
    methods (Hidden)
        function v = nextResonantFov(obj)
            ss = obj.hScan.scannerset;
            if obj.hScan.hSI.hScan2D==obj.hScan && isa(ss,'scanimage.mroi.scannerset.ResonantGalvoGalvo')
                v = obj.hScan.scannerset.resonantScanFov(obj.hScan.currentRoiGroup);
            else
                v = 0;
            end
        end
    end
    
    methods (Access = private)
        function deleteTasks(obj)
            most.idioms.safeDeleteObj(obj.hAOTaskGalvo);
            most.idioms.safeDeleteObj(obj.hAOTaskBeams);
            most.idioms.safeDeleteObj(obj.hAOTaskZ);
            
            obj.hAOTaskGalvo = [];
            obj.hAOTaskBeams = [];
            obj.hAOTaskZ     = [];
        end
        
        function createTasks(obj)
            obj.deleteTasks();
            
            try
                scannerName = obj.hScan.name;
                
                % set up AO ask to control the galvo positions
                obj.hAOTaskGalvo = dabs.vidrio.ddi.AoTask(obj.hScan.yGalvo.hAOControl.hDAQ.hDevice, [scannerName '-GalvoCtrlGalvoPosition']);
                if obj.xGalvoExists
                    xGalvo = obj.hScan.xGalvo;
                    xGalvo.assertNoError();
                    assert(xGalvo.hAOControl.hDAQ==obj.hScan.hDAQ, ...
                        'RGGScan %s: xGalvo %s is not configured to use vDAQ %s',...
                        obj.hScan.name,xGalvo.name,obj.hScan.hDAQ.name);
                    obj.hAOTaskGalvo.addChannel(xGalvo.hAOControl.channelID,'X Galvo Control');
                end
                
                yGalvo = obj.hScan.yGalvo;
                yGalvo.assertNoError();
                assert(yGalvo.hAOControl.hDAQ==obj.hScan.hDAQ, ...
                    'RGGScan %s: yGalvo %s is not configured to use vDAQ %s',...
                    obj.hScan.name,yGalvo.name,obj.hScan.hDAQ.name);
                
                obj.hAOTaskGalvo.addChannel(yGalvo.hAOControl.channelID,'Y Galvo Control');
                obj.hAOTaskGalvo.sampleMode = 'finite';
                obj.hAOTaskGalvo.allowRetrigger = true;
                
                if obj.hScan.isStreamScanning
                    hMotor = obj.hScan.hSI.hMotors.hMotorXYZ{2};
                    axesIdxs = obj.hScan.hSI.hMotors.motorAxisXYZ([1 2]);
                    obj.hStream = hMotor.createStream(axesIdxs);
                end
                
                % set up AO task to control beams
                obj.hAOTaskBeams = dabs.vidrio.ddi.AoTask(obj.hFpga, [scannerName '-BeamCtrl']);
                for idx = 1:numel(obj.hScan.hBeams)
                    hBeam = obj.hScan.hBeams{idx};
                    hBeam.assertNoError();
                    
                    if isa(hBeam, 'dabs.resources.devices.BeamModulatorFast')
                        assert(hBeam.hAOControl.hDAQ==obj.hScan.hDAQ, ...
                            'RGGScan %s: Beam %s is not configured to use vDAQ %s',...
                            obj.hScan.name,hBeam.name,obj.hScan.hDAQ.name);
                        
                        obj.hAOTaskBeams.addChannel(hBeam.hAOControl,hBeam.name);
                        
                        obj.hAOTaskBeams.sampleMode = 'finite';
                        obj.hAOTaskBeams.allowRetrigger = true;
                    end
                end
                
                % set up AO task to control piezo
                obj.hAOTaskZ = dabs.vidrio.ddi.AoTask(obj.hFpga, [scannerName '-ZCtrl']);
                
                for idx = 1:numel(obj.hScan.hFastZs)
                    hFastZ = obj.hScan.hFastZs{idx};
                    hFastZ.assertNoError();
                    assert(hFastZ.hAOControl.hDAQ==obj.hScan.hDAQ, ...
                        'RGGScan %s: FastZ %s is not configured to use vDAQ %s',...
                        obj.hScan.name,hFastZ.name,obj.hScan.hDAQ.name);
                    
                    obj.hAOTaskZ.addChannel(hFastZ.hAOControl);
                    obj.hAOTaskZ.sampleMode = 'finite';
                    obj.hAOTaskZ.allowRetrigger = true;
                end
                
            catch ME
                obj.deleteTasks();
                rethrow(ME);
            end
        end
        
        function setupSampleClk(obj)
            if obj.useScannerSampleClk
                scannerAo = obj.hScan.hSI.hWaveformManager.scannerAO;
                
                if obj.hScan.scanModeIsLinear
                    obj.hAcqEngine.acqParamSampleClkPulsesPerPeriod = scannerAo.ao_samplesPerTrigger.G;
                    obj.hAcqEngine.acqParamLinearSampleClkPulseDuration = obj.hScan.sampleRateCtlDecim;
                else
                    obj.scannerSampsPerPeriod = floor(obj.hScan.sampleRateCtl/obj.hScan.scannerFrequency);
                    if isfield(scannerAo.ao_volts, 'G')
                        obj.waveformLenthPeriods.G = round(obj.hScan.scannerFrequency * size(scannerAo.ao_volts.G,1) / obj.hScan.sampleRateCtl);
                        obj.waveformResampLength.G = obj.waveformLenthPeriods.G * obj.scannerSampsPerPeriod;
                    end
                    
                    if isfield(scannerAo.ao_volts, 'Z')
                        obj.waveformLenthPeriods.Z = round(obj.hScan.scannerFrequency * size(scannerAo.ao_volts.Z,1) / obj.hScan.sampleRateCtl);
                        obj.waveformResampLength.Z = obj.waveformLenthPeriods.Z * obj.scannerSampsPerPeriod;
                    end
                    
                    obj.hAcqEngine.acqParamSampleClkPulsesPerPeriod = obj.scannerSampsPerPeriod;
                end
            end
        end
        
        function galvoPoints = updateTaskCfg(obj, isLive, waveforms)
            if nargin < 2 || isempty(isLive)
                isLive = false;
            end
            
            scannerAo = obj.hScan.hSI.hWaveformManager.scannerAO;
            ss = obj.hScan.scannerset;
            
            if nargin < 3
                waveforms = 'RGBZ';
            end
            
            beamsActive = ~isempty(obj.hAOTaskBeams.channels);
            zActive = ~isempty(obj.hAOTaskZ.channels) && obj.hScan.hSI.hFastZ.outputActive;
            
            
            if obj.hScan.scanModeIsLinear
                v = 0;
            else
                v = max(scannerAo.pathFOV.R);
            end
            
            if ismember('R', waveforms) && most.idioms.isValidObj(obj.hScan.hResonantScanner)
                hSyncedScanner = obj.hScan.hResonantScanner;
                if isa(hSyncedScanner,'dabs.resources.devices.ResonantScanner')
                    hSyncedScanner.assertNoError();

                    if isa(hSyncedScanner,'dabs.mirrorcle.ResonantAxis') && isempty(ss.scanners{2})
                        XShift_deg = obj.hScan.hSI.hRoiManager.scanAngleShiftFast;
                        voltsShift = hSyncedScanner.deg2volt(XShift_deg);
                        hSyncedScanner.hAOZoomTask.hChanIp.updateOffset(voltsShift);
                    end

                    hSyncedScanner.setAmplitude(v);
                elseif isa(hSyncedScanner,'dabs.resources.devices.PolygonalScanner')
                    nominalLineRate_Hz = hSyncedScanner.nominalFrequency_Hz;
                    hSyncedScanner.setLineRate_Hz(nominalLineRate_Hz);
                end
            end
            
            updateG = ~isLive || ismember('G', waveforms);
            if updateG
                if obj.xGalvoExists
                    galvoPoints = scannerAo.ao_volts.G;
                else
                    galvoPoints = scannerAo.ao_volts.G(:,2);
                end
                galvoSamplesPerFrame = scannerAo.ao_samplesPerTrigger.G;
                galvoBufferLengthNew = size(galvoPoints,1);
                assert(galvoBufferLengthNew > 0, 'AO generation error. Galvo control waveform length is zero.');
                assert(~mod(galvoBufferLengthNew,galvoSamplesPerFrame),'Length of dataPoints has to be divisible by samplesPerFrame');
            end
            
            updateB = (~isLive || ismember('B', waveforms)) && beamsActive;
            if updateB
                hBeams = obj.hScan.hSI.hBeams;
                assert(~hBeams.enablePowerBox || ((hBeams.powerBoxStartFrame == 1) && isinf(hBeams.powerBoxEndFrame)),...
                    'Time varying power box is not supported.');
                isLineScanEnabled = obj.hScan.hSI.hRoiManager.isLineScan;
                if hBeams.hasPowerBoxes && isLineScanEnabled
                    warning(['Line scan mode does not support power boxes. ' ...
                        'Ignoring power box settings.']);
                end
                if hBeams.hasPowerBoxes && ~isLineScanEnabled
                    beamPoints = scannerAo.ao_volts.Bpb;
                else
                    beamPoints = scannerAo.ao_volts.B;
                end
                beamBufferLengthNew = size(beamPoints,1);
            else
                beamBufferLengthNew = 0;
            end
            
            updateZ = (~isLive || ismember('Z', waveforms)) && zActive;
            if updateZ
                zPoints = scannerAo.ao_volts.Z;
                zBufferLengthNew = size(zPoints, 1);
                zSamplesPerTrigger = size(zPoints, 1);
            else
                zBufferLengthNew = 0;
            end
            
            updateS = obj.hScan.isStreamScanning && (~isLive || ismember('S', waveforms));
            
            if updateS
                streamPoints = [scannerAo.ao_volts_raw.S];
                
                frameTime = obj.hScan.hSI.hWaveformManager.scannerAO.frameTime;
                hMotor = obj.hScan.hSI.hMotors.hMotorXYZ{2};
                maxVelocity = hMotor.streamMaxVelocity_umPerS;
                frameStartPositions = streamPoints(1:2:end,:);
                frameEndPositions = streamPoints(2:2:end,:);
                framePositionLength = sqrt(sum((frameEndPositions - frameStartPositions).^2,2));
                velocities = framePositionLength/frameTime;
                velocities = repelem(velocities,2);
                velocities(2:2:end) = maxVelocity;
                
                assert(all(velocities <= maxVelocity), ...
                    ['Current acquisition settings have the stage traveling faster (%g um/s) than the user ' ...
                    'configured maxVelocity (%g um/s) of the stage.\nEither slow down the acquisition by ' ...
                    'adding more lines,\nor increase the max velocity and test to see that it is feasible.'] ...
                    , sqrt(sum(diff(streamPoints,1).^2))/(frameTime), maxVelocity);
            end
            
            if obj.useScannerSampleClk && ~obj.hScan.scanModeIsLinear
                % waveforms need to be resampled to have round number of
                % samples per resonant period
                if updateG
                    N = galvoBufferLengthNew-1;
                    galvoPoints = interp1(0:N,galvoPoints,linspace(0,N,obj.waveformResampLength.G)');
                end
                if updateZ
                    N = zBufferLengthNew-1;
                    zPoints = interp1(0:N,zPoints,linspace(0,N,obj.waveformResampLength.Z)');
                end
            end
            
            if isLive
                assert(~updateG || (obj.galvoBufferLength == galvoBufferLengthNew), 'Buffer length can''t change.');
                assert(~updateB || (obj.beamBufferLength == beamBufferLengthNew), 'Buffer length can''t change.');
                assert(~updateZ || (obj.zBufferLength == zBufferLengthNew), 'Buffer length can''t change.');
            else
                obj.hAOTaskGalvo.abort();
                obj.hAOTaskBeams.abort();
                obj.hAOTaskZ.abort();
                
                obj.galvoBufferLength = galvoBufferLengthNew;
                obj.beamBufferLength = beamBufferLengthNew;
                obj.zBufferLength = zBufferLengthNew;
                
                obj.hScan.hSI.hBeams.streamingBuffer = false;
                
                if obj.useScannerSampleClk
                    obj.hAOTaskGalvo.sampleRate = 2e6; % dummy; wont be actual rate
                    obj.hAOTaskGalvo.startTrigger = obj.hScan.hTrig.sampleClkTermInt;
                    obj.hAOTaskGalvo.samplesPerTrigger = 1;
                    obj.hAOTaskGalvo.allowEarlyTrigger = false;
                else
                    obj.hAOTaskGalvo.sampleRate = obj.hScan.sampleRateCtl;
                    obj.hAOTaskGalvo.startTrigger = obj.hScan.hTrig.sliceClkTermInt;
                    obj.hAOTaskGalvo.samplesPerTrigger = galvoSamplesPerFrame;
                    obj.hAOTaskGalvo.allowEarlyTrigger = true;
                end
                
                if beamsActive
                    obj.hAOTaskBeams.sampleMode = 'finite';
                    if obj.hScan.scanModeIsLinear
                        if obj.useScannerSampleClk
                            obj.hAOTaskBeams.sampleRate = 2e6; % dummy; wont be actual rate
                            obj.hAOTaskBeams.startTrigger = obj.hScan.hTrig.sampleClkTermInt;
                            obj.hAOTaskBeams.samplesPerTrigger = 1;
                            obj.hAOTaskBeams.allowEarlyTrigger = false;
                        else
                            obj.hAOTaskBeams.sampleRate = ss.beams(1).sampleRateHz;
                            obj.hAOTaskBeams.startTrigger = obj.hScan.hTrig.sliceClkTermInt;
                            obj.hAOTaskBeams.samplesPerTrigger = scannerAo.ao_samplesPerTrigger.B;
                            obj.hAOTaskBeams.allowEarlyTrigger = true;
                        end
                    else
                        obj.hAOTaskBeams.sampleRate = ss.beams(1).sampleRateHz;
                        obj.hAOTaskBeams.samplesPerTrigger = scannerAo.ao_samplesPerTrigger.B;
                        obj.hAOTaskBeams.startTrigger = obj.hScan.hTrig.beamClkTermInt;
                        obj.hAOTaskBeams.allowEarlyTrigger = false;
                    end
                end
                
                if zActive
                    if obj.useScannerSampleClk
                        obj.hAOTaskZ.sampleRate = 2e6; % dummy; wont be actual rate
                        obj.hAOTaskZ.startTrigger = obj.hScan.hTrig.sampleClkTermInt;
                        obj.hAOTaskZ.samplesPerTrigger = 1;
                        obj.hAOTaskZ.allowEarlyTrigger = false;
                    else
                        obj.hAOTaskZ.sampleRate = ss.fastz(1).sampleRateHz;
                        obj.hAOTaskZ.startTrigger = obj.hScan.hTrig.volumeClkTermInt;
                        obj.hAOTaskZ.samplesPerTrigger = zSamplesPerTrigger;
                        obj.hAOTaskZ.allowEarlyTrigger = true;
                    end
                end
            end
            
            if ~obj.simulated
                if updateG
                    obj.hAOTaskGalvo.writeOutputBufferAsync(galvoPoints);
                end
                if updateB
                    obj.hAOTaskBeams.writeOutputBufferAsync(beamPoints);
                end
                if updateZ
                    obj.hAOTaskZ.writeOutputBufferAsync(zPoints);
                end
                if updateS
                    obj.hStream.positions = streamPoints;
                    obj.hStream.velocities = velocities;
                    obj.hStream.triggerLevel = 1;
                    obj.hStream.writeBuffer();
                    
                    if isLive
                       obj.hStream.start(); 
                    end
                end
            end
        end
    end
    
    %% Property Set Methods
    methods
        function val = get.hFpga(obj)
            val = obj.hScan.hAcq.hFpga;
        end
        
        function val = get.hAcqEngine(obj)
            val = obj.hScan.hAcq.hAcqEngine;
        end
        
        function val = get.xGalvoExists(obj)
            val = most.idioms.isValidObj(obj.hScan.xGalvo);
        end
        
        function value = get.galvoParkVoltsX(obj)
            if most.idioms.isValidObj(obj.hScan.xGalvo)
                xGalvo = oj.hScan.xGalvo;
                value = xGalvo.position2Volts(xGalvo.parkPosition);
            else
                value = 0;
            end
        end
        
        function value = get.galvoParkVoltsY(obj)
            if most.idioms.isValidObj(obj.hScan.xGalvo)
                xGalvo = oj.hScan.xGalvo;
                value = xGalvo.position2Volts(xGalvo.parkPosition);
            else
                value = 0;
            end
        end
        
        function val = get.simulated(obj)
            val = obj.hScan.simulated;
        end
        
        function value = get.useScannerSampleClk(obj)
            isTaskActive = ~most.idioms.isValidObj(obj.hAOTaskZ) || ~isempty(obj.hAOTaskZ.channels);
            zActive = isTaskActive && obj.hScan.hSI.hFastZ.outputActive;
            value = obj.hScan.scanModeIsLinear || ~zActive;
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

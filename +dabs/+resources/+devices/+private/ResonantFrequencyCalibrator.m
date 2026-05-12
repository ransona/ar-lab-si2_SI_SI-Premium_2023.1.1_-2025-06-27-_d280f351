classdef ResonantFrequencyCalibrator < handle & matlab.mixin.SetGet
    %% Resonant frequency sweep properties
    properties (SetObservable)
        startFrequency_Hz;    % start search frequency (Hz)
        endFrequency_Hz;      % end search frequency (Hz)
        testAmplitude_deg;    % set amplitude of mirror during sweep test

        numProceduralIntervals = 10;
        searchMethod = 'Linear';    % 'Linear', 'Optimized', or 'Chirp'

        frequencyMap;   % maps test frequencies to amplitude response
    end

    properties (Dependent)
        detectedBestFrequency_Hz;
        detectedMaxAmplitude;
    end

    properties (SetObservable,Hidden)
        lastFrequencyMap;

        autoscale = true;
        xLim;
    end

    properties (Constant,Hidden)
        CHIRP_METHODS = {'Linear','Optimized'};  % TODO: add 'Chirp'
        MINIMUM_FREQUENCY_HZ = 1e3;
        MINIMUM_BANDWIDTH_HZ = 100;
    end

    %% GUI Properties
    properties (Hidden)
        hResonantScanner;
        
        hFig;
        hDataAx;
        hAnnotationAx;
        
        hLineAmplitudes;
        hLineLastAmplitudes;
        hLineBestPoint;
        hLineStart;
        hLineEnd;
        hSurfSpan;

        hWaitBar;

        pbSaveCalibration;
        pbResetCalibration;
        
        hListeners = event.listener.empty(0,1);
    end

    %% Lifecycle
    methods
        function obj = ResonantFrequencyCalibrator(hResonantScanner)
            assert(isa(hResonantScanner,'dabs.resources.Resource'),...
                'Invalid argument hResonantScanner: must be a dabs.resources.Resource object');
            assert(isa(hResonantScanner,'dabs.interfaces.ScannerFrequencyCalibration'),...
                '%s is not capable of frequency calibration',hResonantScanner.name);

            obj.hResonantScanner = hResonantScanner;
            obj.startFrequency_Hz = hResonantScanner.nominalFrequency_Hz-1e3;
            obj.endFrequency_Hz = hResonantScanner.nominalFrequency_Hz+1e3;
            obj.testAmplitude_deg = hResonantScanner.angularRange_deg / 4;

            obj.frequencyMap = containers.Map('KeyType','double','ValueType','double');
            obj.lastFrequencyMap = containers.Map('KeyType','double','ValueType','double');

            obj.loadCalibration();
            obj.makeFigure();
        end

        function delete(obj)
            most.idioms.safeDeleteObj(obj.hListeners);
            most.idioms.safeDeleteObj(obj.hWaitBar);
            most.idioms.safeDeleteObj(obj.hFig);
        end

        function loadCalibration(obj)
            obj.hResonantScanner.loadFrequencyCalibration();

            if ~isempty(obj.hResonantScanner.frequencyLUT)
                validateattributes(obj.hResonantScanner.frequencyLUT,{'numeric'},{'2d','ncols',2});
                obj.frequencyMap = containers.Map(obj.hResonantScanner.frequencyLUT(:,1),obj.hResonantScanner.frequencyLUT(:,2));
            end
        end

        function saveCalibration(obj)
            obj.hResonantScanner.frequencyLUT = cell2mat([obj.frequencyMap.keys' obj.frequencyMap.values']);
            obj.hResonantScanner.nominalFrequency_Hz = obj.detectedBestFrequency_Hz;
            obj.hResonantScanner.saveFrequencyCalibration();
            obj.hResonantScanner.reinit();
        end

        function resetCalibration(obj)
            obj.frequencyMap = containers.Map('KeyType','double','ValueType','double');
            obj.lastFrequencyMap = containers.Map('KeyType','double','ValueType','double');
        end
    end

    %% Search Procedures
    methods
        function [maxFrequency_Hz,maxAmplitude] = calibrate(obj,startFrequency_Hz,endFrequency_Hz)
            if nargin < 2 || isempty(startFrequency_Hz)
                startFrequency_Hz = obj.startFrequency_Hz;
            end
            if nargin < 3 || isempty(endFrequency_Hz)
                endFrequency_Hz = obj.endFrequency_Hz;
            end

            assert(startFrequency_Hz > 0, 'Frequencies must be positive (start frequency is %f)', startFrequency_Hz);
            assert(endFrequency_Hz > startFrequency_Hz, 'End frequency must be greater than start frequency');

            switch obj.searchMethod
                case 'Linear'
                    [maxFrequency_Hz,maxAmplitude] = obj.calibrate_linear(startFrequency_Hz,endFrequency_Hz);
                case 'Optimized'
                    [maxFrequency_Hz,maxAmplitude] = obj.calibrate_optimized(startFrequency_Hz,endFrequency_Hz);
                case 'Chirp'
                    [maxFrequency_Hz,maxAmplitude] = obj.calibrate_chirp(startFrequency_Hz,endFrequency_Hz);
                otherwise
                    error('Unknown option %s',obj.searchMethod);
            end

            obj.redraw();
            obj.hResonantScanner.reinit();
        end

        function [maxFrequency_Hz,maxAmplitude] = calibrate_linear(obj,startFrequency_Hz,endFrequency_Hz)
            % initialize search values
            frequencies_Hz = linspace(startFrequency_Hz,endFrequency_Hz,obj.numProceduralIntervals);
            frequencies_Hz = arrayfun(@(f)obj.hResonantScanner.getClosestFrequency(f),frequencies_Hz);
            frequencies_Hz = unique(frequencies_Hz);
            numIntervals = numel(frequencies_Hz);
            maxAmplitude = 0;
            maxFrequency_Hz = nan;

            obj.lastFrequencyMap = containers.Map('KeyType','double','ValueType','double');

            % test each frequency linearly
            for i = 1:numIntervals
                if most.idioms.isValidObj(obj.hWaitBar)
                    msg = sprintf('Testing frequency %d/%d... (%.0f Hz)',i,numIntervals,frequencies_Hz(i));
                    waitbar(i/numIntervals,obj.hWaitBar,msg);

                    if getappdata(obj.hWaitBar,'canceling')
                        most.idioms.safeDeleteObj(obj.hWaitBar);
                        break;
                    end
                end

                amplitude = obj.hResonantScanner.testAmplitudeResponse(frequencies_Hz(i),obj.testAmplitude_deg);
                obj.frequencyMap(frequencies_Hz(i)) = amplitude;
                obj.lastFrequencyMap(frequencies_Hz(i)) = amplitude;

                if amplitude > maxAmplitude
                    maxAmplitude = amplitude;
                    maxFrequency_Hz = frequencies_Hz(i);
                end
            end
        end

        % utilize Brent's 1d minima search method to find the best frequency
        function [maxFrequency_Hz,maxAmplitude] = calibrate_optimized(obj,startFrequency_Hz,endFrequency_Hz)
            % reverse sign of test frequency procedure to make maximas minimas
            function_ = @(x)-obj.hResonantScanner.testAmplitudeResponse(x,obj.testAmplitude_deg);
            bracket = [startFrequency_Hz, endFrequency_Hz];
            intervals = obj.numProceduralIntervals;
            tolerance = 1e-3;  % tolerance in Hz

            obj.lastFrequencyMap = containers.Map('KeyType','double','ValueType','double');
            currentInterval = 0;

            % find first local maxima
            try
                [maxFrequency_Hz,maxAmplitude] = scanimage.util.brentMinimaSearch(function_,bracket,tolerance,intervals,{},@callback);
            catch ME
                if ~strcmp(ME.identifier,'ResonantFrequencyCalibrator:CancelSearch')
                    rethrow(ME);
                end

                if ~isempty(obj.lastFrequencyMap)
                    frequencies_Hz = cell2mat(obj.lastFrequencyMap.keys);
                    amplitudes = cell2mat(obj.lastFrequencyMap.values);
                    [maxAmplitude,index] = max(amplitudes);
                    maxAmplitude = -maxAmplitude;  % lastFrequencyMap values are positive, cancel out inversion below
                    maxFrequency_Hz = frequencies_Hz(index);
                end
            end

            maxAmplitude = -maxAmplitude;  % invert result from Brent search

            function callback(x_Hz,amplitude)
                currentInterval = currentInterval + 1;
                obj.frequencyMap(x_Hz) = -amplitude;
                obj.lastFrequencyMap(x_Hz) = -amplitude;

                if most.idioms.isValidObj(obj.hWaitBar)
                    msg = sprintf('Tested frequency %d/%d (%.0f Hz)',currentInterval,obj.numProceduralIntervals,x_Hz);
                    waitbar(currentInterval/intervals,obj.hWaitBar,msg);

                    if getappdata(obj.hWaitBar,'canceling')
                        most.idioms.safeDeleteObj(obj.hWaitBar);
                        error('ResonantFrequencyCalibrator:CancelSearch','User cancelled');
                    end
                end
            end
        end

        function [maxFrequency_Hz,maxAmplitude] = calibrate_chirp(obj,startFrequency_Hz,endFrequency_Hz)
            % TODO
            error('Procedural chirp search method is not available yet.');
        end
    end

    %% GUI
    methods
        % TODO: allow to slot into new user interface (pass in container)
        function makeFigure(obj)
            figName = sprintf('%s Amplitude/Frequency Response',obj.hResonantScanner.name);
            obj.hFig = most.idioms.figure('Name',figName,'CloseRequestFcn',@(varargin)delete(obj));
            obj.hFig.Position = most.gui.centeredScreenPos([800 600],'pixels');
            obj.hFig.WindowScrollWheelFcn = @obj.scrollWheelFunction;
            hMainFlow = most.gui.uiflowcontainer('Parent',obj.hFig,'FlowDirection','TopDown');
            
            hTop = uipanel('Parent',hMainFlow,'bordertype','none');
                obj.hDataAx = most.idioms.axes('Parent',hTop,'FontSize',12,'FontWeight','Bold','ButtonDownFcn',@obj.panAxes);
                obj.hLineAmplitudes = line('Parent',obj.hDataAx,'XData',[],'YData',[],'Color',most.constants.Colors.black,'LineWidth',2,'Hittest','off','PickableParts','none');
                obj.hLineLastAmplitudes = line('Parent',obj.hDataAx,'XData',[],'YData',[],'Color',most.constants.Colors.black,'Marker','o','LineWidth',1,'LineStyle','none','MarkerSize',7,'Hittest','off','PickableParts','none');
                obj.hLineBestPoint = line('Parent',obj.hDataAx,'XData',[],'YData',[],'Color',most.constants.Colors.red,'Marker','o','LineStyle','none','LineWidth',1,'MarkerSize',10,'Hittest','off','PickableParts','none');
                
                xlabel(obj.hDataAx,'Resonant Scan Frequency Tested [Hz]','FontWeight','Bold');
                ylabel(obj.hDataAx,'Resonant Scan Amplitude Received','FontWeight','Bold');
                grid(obj.hDataAx,'on');
                title(obj.hDataAx,figName);
                
                obj.hAnnotationAx = most.idioms.axes('Parent',hTop,'XColor','none','YColor','none','ylim',[0 1],'color','none','XTick',[],'YTick',[],'Visible','off','ButtonDownFcn',@obj.panAxes);
                obj.hSurfSpan = surface('Parent',obj.hAnnotationAx,'XData',[0 1; 0 1],'YData',[0 1; 0 1]','ZData',zeros(2),'FaceColor',most.constants.Colors.green,'FaceAlpha',.3,'LineStyle','none','ButtonDownFcn',@obj.frequencyRangeClicked);
                obj.hLineStart = line('Parent',obj.hAnnotationAx,'XData',[0 0],'YData',[0 1],'Color',most.constants.Colors.darkGreen,'Marker','none','LineStyle','--','LineWidth',2,'ButtonDownFcn',@obj.frequencyRangeClicked);
                obj.hLineEnd = line('Parent',obj.hAnnotationAx,'XData',[1 1],'YData',[0 1],'Color',most.constants.Colors.darkGreen,'Marker','none','LineStyle','--','LineWidth',2,'ButtonDownFcn',@obj.frequencyRangeClicked);

            hBottom = most.gui.uiflowcontainer('Parent',hMainFlow,'FlowDirection','LeftToRight','HeightLimits',[59 59],'Margin',1);
                hCols = most.gui.uiflowcontainer('Parent',hBottom,'FlowDirection','LeftToRight','WidthLimits',[220 220],'Margin',1);
                tooltip = sprintf('Start measuring amplitude between the start & end frequencies using the\nselected search method, test amplitude, and number of search intervals');
                most.gui.uicontrol('Parent',hCols,'Style','pushbutton','Callback',@obj.startCalibrate_callback,'String','Start Measuring','TooltipString',tooltip);
                tooltip = 'Save the search results to the scanner, and set the detected best frequency as the nominal frequency';
                obj.pbSaveCalibration = most.gui.uicontrol('Parent',hCols,'Style','pushbutton','String','<html>&#x1F5AB;</html>','FontSize',20,'Visible','off','Callback',@obj.saveCalibration_callback,'TooltipString',tooltip,'WidthLimits',[58 58]);

                hRows = most.gui.uiflowcontainer('Parent',hBottom,'FlowDirection','TopDown','Margin',1);
                    hRow = most.gui.uiflowcontainer('Parent',hRows,'FlowDirection','LeftToRight','HeightLimits',[27 27]);
                        tooltip = sprintf([...
                            'Search methods that can be used to measure between frequencies:\n'...
                            '-- [Linear] .......... Test frequencies linearly between the start & end frequency\n'...
                            '-- [Optimized] ... Search algorithmically to attempt to find a local maxima in smaller frequency intervals']);
                        most.gui.uicontrol('Parent',hRow,'Style','popupmenu','String',obj.CHIRP_METHODS,'Bindings',{obj 'searchMethod' 'choice'},'TooltipString',tooltip,'WidthLimits',[90 90]);
                        tooltip = 'Number of test intervals between start and end frequencies';
                        most.gui.uicontrol('Parent',hRow,'Style','edit','Bindings',{obj 'numProceduralIntervals' 'value' '%.0f'},'TooltipString',tooltip,'WidthLimits',[50 50]);
                        tooltip = 'Reset the current measured data and start over';
                        obj.pbResetCalibration = most.gui.uicontrol('Parent',hRow,'Style','pushbutton','String',most.constants.Unicode.refresh,'Callback',@(~,~)obj.resetCalibration,'TooltipString',tooltip,'WidthLimits',[24 24],'Visible','off');
                        
                    hRow = most.gui.uiflowcontainer('Parent',hRows,'FlowDirection','LeftToRight','HeightLimits',[27 27]);
                        tooltip = 'Start frequency (Hz)';
                        most.gui.uicontrol('Parent',hRow,'Style','edit','Bindings',{obj 'startFrequency_Hz' 'value' '%.0f'},'TooltipString',tooltip,'WidthLimits',[70 70],'Callback',@obj.focusPlot);
                        tooltip = 'End frequency (Hz)';
                        most.gui.uicontrol('Parent',hRow,'Style','edit','Bindings',{obj 'endFrequency_Hz' 'value' '%.0f'},'TooltipString',tooltip,'WidthLimits',[70 70],'Callback',@obj.focusPlot);
                        tooltip = sprintf('Test output amplitude (scan degrees)\nThis is the driving waveform amplitude in scan degrees');
                        most.gui.uicontrol('Parent',hRow,'Style','text','String','Amplitude [deg]:','TooltipString',tooltip,'HorizontalAlignment','right');
                        maxAmplitude = obj.hResonantScanner.angularRange_deg;
                        most.gui.slider('Parent',hRow,'Min',0,'Max',maxAmplitude,'Bindings',{obj 'testAmplitude_deg' 1},'WidthLimits',[100 300]);
                        most.gui.uicontrol('Parent',hRow,'Style','edit','Bindings',{obj 'testAmplitude_deg' 'value' '%.2f'},'HorizontalAlignment','left','TooltipString',tooltip,'WidthLimits',[70 70]);
            
            most.idioms.safeDeleteObj(obj.hListeners);
            obj.hListeners        = most.ErrorHandler.addCatchingListener(obj,'frequencyMap','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj,'lastFrequencyMap','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj,'startFrequency_Hz','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj,'endFrequency_Hz','PostSet',@obj.redraw);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj,'xLim','PostSet',@obj.redraw);

            obj.focusPlot();
            obj.redraw();
        end

        function redraw(obj,varargin)
            if isempty(obj.frequencyMap)
                obj.drawExampleData();
            else
                obj.drawActualData();
            end

            set(obj.hLineStart,'XData',[obj.startFrequency_Hz obj.startFrequency_Hz]);
            set(obj.hLineEnd,'XData',[obj.endFrequency_Hz obj.endFrequency_Hz]);
            set(obj.hSurfSpan,'XData',[obj.startFrequency_Hz obj.endFrequency_Hz; obj.startFrequency_Hz obj.endFrequency_Hz]);

            if ~verLessThan('matlab','9.10')
                % make sure the y axis has some padding around the data
                ylim(obj.hDataAx,'padded');
            end
            xlim([obj.hDataAx obj.hAnnotationAx],obj.xLim);
        end

        function drawActualData(obj)
            frequencies_Hz = cell2mat(obj.frequencyMap.keys);
            amplitudes = cell2mat(obj.frequencyMap.values);

            % note: map seems sorted already, but just in case
            [frequencies_Hz,sortIndices] = sort(frequencies_Hz);
            amplitudes = amplitudes(sortIndices);

            lastFrequencies_Hz = cell2mat(obj.lastFrequencyMap.keys);
            lastAmplitudes = cell2mat(obj.lastFrequencyMap.values);

            [maxAmplitude,maxIndex] = max(amplitudes);
            maxFrequency_Hz = frequencies_Hz(maxIndex);

            obj.pbSaveCalibration.Visible = 'on';
            obj.pbResetCalibration.Visible = 'on';
            set(obj.hLineLastAmplitudes,'XData',lastFrequencies_Hz,'YData',lastAmplitudes);
            set(obj.hLineBestPoint,'XData',maxFrequency_Hz,'YData',maxAmplitude);
            set(obj.hLineAmplitudes,...
                'XData',frequencies_Hz,'YData',amplitudes,...
                'LineStyle','-','LineWidth',2,...
                'Color',most.constants.Colors.black);
        end

        function drawExampleData(obj)
            nominal_Hz = obj.hResonantScanner.nominalFrequency_Hz;
            halfband_Hz = 10e3;
            start_Hz = nominal_Hz - halfband_Hz;
            end_Hz = nominal_Hz + halfband_Hz;

            frequencies_Hz = linspace(start_Hz,end_Hz,10e3);
            width = 1/135;
            amplitudes = sinc(width*(frequencies_Hz-nominal_Hz));
            maxScale = 100;
            amplitudes = rescale(amplitudes,0,maxScale);

            obj.pbSaveCalibration.Visible = 'off';
            obj.pbResetCalibration.Visible = 'off';
            set(obj.hLineLastAmplitudes,'XData',[],'YData',[]);
            set(obj.hLineBestPoint,'XData',nominal_Hz,'YData',maxScale);
            set(obj.hLineAmplitudes,...
                'XData',frequencies_Hz,'YData',amplitudes,...
                'LineStyle',':','LineWidth',1,...
                'Color',most.constants.Colors.darkGray);

            function f = sinc(x)
                f = sin(x)./x;
                f(x == 0) = 1;
            end
        end

        function frequencyRangeClicked(obj,src,evt)
            persistent xIndices
            persistent originalHz
            persistent originalWindow
            persistent originalSize
            
            if strcmp(evt.EventName, 'Hit')
                if any(src == obj.hLineStart)
                    xIndices = 1;
                elseif any(src == obj.hSurfSpan)
                    xIndices = [1 2];
                else
                    xIndices = 2;
                end

                originalHz = obj.hAnnotationAx.CurrentPoint(1);
                originalWindow = [obj.startFrequency_Hz obj.endFrequency_Hz];
                originalSize = diff(originalWindow);
                set(obj.hFig,'WindowButtonMotionFcn',@obj.frequencyRangeClicked,'WindowButtonUpFcn',@obj.frequencyRangeClicked);
            elseif strcmp(evt.EventName, 'WindowMouseMotion')
                mouseMoveResult = originalWindow + obj.hAnnotationAx.CurrentPoint(1) - originalHz;
                
                % enforce not below 1000, but maintain the original size
                if numel(xIndices) == 2
                    mouseMoveResult = max(mouseMoveResult,obj.MINIMUM_FREQUENCY_HZ+[0 originalSize]);
                else
                    mouseMoveResult = max(mouseMoveResult,obj.MINIMUM_FREQUENCY_HZ);
                end
                
                frequencies = [obj.startFrequency_Hz obj.endFrequency_Hz];
                frequencies(xIndices) = mouseMoveResult(xIndices);
                set(obj,'startFrequency_Hz',frequencies(1),'endFrequency_Hz',frequencies(2));
            else
                set(obj.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
            end
        end

        function panAxes(obj,src,evt)
            persistent hAx
            persistent originalPoint
            
            if strcmp(evt.EventName,'Hit')
                hAx = src;
                originalPoint = hAx.CurrentPoint(1);
                set(obj.hFig,'WindowButtonMotionFcn',@obj.panAxes,'WindowButtonUpFcn',@obj.panAxes);
            elseif strcmp(evt.EventName, 'WindowMouseMotion')
                delta = originalPoint - hAx.CurrentPoint(1);
                obj.xLim = obj.xLim + delta(1);
                originalPoint = hAx.CurrentPoint(1);
            else
                set(obj.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
            end
        end

        function scrollWheelFunction(obj,~,evt)
            scrollCount = evt.VerticalScrollCount;
            mouseInAxes = any(hittest(obj.hFig) == [obj.hDataAx;obj.hDataAx.Children;obj.hAnnotationAx;obj.hAnnotationAx.Children]);
            if mouseInAxes
                xpt = obj.hAnnotationAx.CurrentPoint(1);
                xpts = obj.xLim - xpt;
                obj.xLim = xpts * 1.2^scrollCount + xpt;
            end
        end

        function startCalibrate_callback(obj,~,~)
            warning = sprintf('WARNING! This will start a frequency calibration between\n\\bf%.0f\\rm and \\bf%.0f\\rm Hz with a test amplitude of \\bf%.2f\\rm degrees.\nIs this ok?',obj.startFrequency_Hz,obj.endFrequency_Hz,obj.testAmplitude_deg);
            opts.Interpreter = 'tex';
            opts.Default = 'No';

            answer = questdlg(warning,'Start Calibration','Yes','No',opts);
            if strcmp(answer,'No')
                return
            end

            try
                most.idioms.safeDeleteObj(obj.hWaitBar);
                obj.hWaitBar = waitbar(0,'Starting calibration...','Name','Calibrating Resonant Frequency',...
                    'CreateCancelBtn',@(~,~)setappdata(obj.hWaitBar,'canceling',1));
                obj.calibrate();
                most.idioms.safeDeleteObj(obj.hWaitBar);
            catch ME
                most.idioms.safeDeleteObj(obj.hWaitBar);
                most.ErrorHandler.logAndReportError(ME);
                warndlg(ME.message,'Error during calibration');
            end
        end

        function saveCalibration_callback(obj,~,~)
            obj.saveCalibration();
            msgbox('Calibration saved to scanner.','Calibration Saved','help');
        end

        function focusPlot(obj,~,~)
            frequencies = [obj.startFrequency_Hz obj.endFrequency_Hz];
            offset = diff(frequencies) * 0.15;
            obj.xLim = frequencies + [-offset offset];
        end
    end

    %% PROP ACCESS
    methods
        function set.xLim(obj,val)
            validateattributes(val,{'numeric'},{'numel',2,'increasing'});
            val(1) = max([val(1) -0.05*val(2)]);
            val(2) = max([val(2) obj.MINIMUM_BANDWIDTH_HZ+val(1)]);
            obj.xLim = val;
        end

        function set.startFrequency_Hz(obj,val)
            validateattributes(val,{'numeric'},{'scalar'});
            if val < obj.MINIMUM_FREQUENCY_HZ
                val = obj.MINIMUM_FREQUENCY_HZ;
            end
            if val >= obj.endFrequency_Hz - obj.MINIMUM_BANDWIDTH_HZ
                val = obj.endFrequency_Hz - obj.MINIMUM_BANDWIDTH_HZ;
            end
            obj.startFrequency_Hz = val;
        end

        function set.endFrequency_Hz(obj,val)
            validateattributes(val,{'numeric'},{'scalar'});
            minimum = obj.MINIMUM_FREQUENCY_HZ + obj.MINIMUM_BANDWIDTH_HZ;
            if val < minimum
                val = minimum;
            end
            if val <= obj.startFrequency_Hz + obj.MINIMUM_BANDWIDTH_HZ
                val = obj.startFrequency_Hz + obj.MINIMUM_BANDWIDTH_HZ;
            end
            obj.endFrequency_Hz = val;
        end

        function val = get.detectedBestFrequency_Hz(obj)
            if isempty(obj.frequencyMap)
                val = nan;
            else
                amplitudes = cell2mat(obj.frequencyMap.values);
                frequencies = cell2mat(obj.frequencyMap.keys);
                [~,idx] = max(amplitudes);
                val = frequencies(idx);
            end
        end

        function val = get.detectedMaxAmplitude(obj)
            if isempty(obj.frequencyMap)
                val = nan;
            else
                amplitudes = cell2mat(obj.frequencyMap.values);
                val = max(amplitudes);
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

classdef LiveHistogram < handle
    properties
        dataRange = [intmin('int16'),intmax('int16')];
        viewRange = [0 1];
        lut = [NaN NaN];
        title = '';
        channel = [];
        z = [];
        roi = [];
        mode;
    end
    
    properties (Hidden, SetAccess = private)
        hFig;
        hHist;
        hAx;
        hTxInfo;
        hSI;
        hLutPatch;
        hSaturationPatch;
        hMeanLine;
        hMaxLine;
        YLim;

        pmChannel;
        pmRoi;
        pmZ;
        
        isCamera;

        hListeners = event.listener.empty();
    end
    
    events
        lutUpdated;
    end
    
    methods
        function obj = LiveHistogram(hSI,channel,roi,z,isCamera)
            if nargin > 0
                obj.hSI = hSI;
            end

            if nargin < 5 || isempty(isCamera)
                isCamera = false;
            end
            obj.isCamera = isCamera;

            
            if isCamera
                obj.mode = 'slice';
                obj.channel = 1;
                obj.roi = 1;
                obj.z = 0;
            else
                if isnan(z)
                    obj.mode = 'volume';
                else
                    obj.mode = 'slice';
                    obj.channel = channel;
                    obj.roi = roi;
                    obj.z = z;
                end
            end


            tagStr = sprintf('Pixel Histogram %0.3g',rand);
            obj.hFig = most.idioms.figure( ...
                'Name','Pixel Histogram' ...
                , 'Tag',tagStr...
                , 'WindowScrollWheelFcn',@obj.scrollWheelFcn ...
                , 'CloseRequestFcn',@obj.closeRequestFcn);
            
            hTopFlow = most.gui.uiflowcontainer('Parent',obj.hFig,'FlowDirection','TopDown');
                hAxFlow = most.gui.uiflowcontainer('Parent',hTopFlow,'FlowDirection','LeftToRight');
                hInfoFlow = most.gui.uiflowcontainer('Parent',hTopFlow,'FlowDirection','LeftToRight');
                    set(hInfoFlow,'HeightLimits',[40 40]);
                
            obj.hAx = most.idioms.axes('Parent',hAxFlow);
            obj.hHist = histogram(obj.hAx,0,'Normalization','countdensity','EdgeColor','none','ButtonDownFcn',@obj.buttonDownFcn);
            
            obj.hAx.ButtonDownFcn = @obj.buttonDownFcn;
            set(get(obj.hAx,'XLabel'),'String','Pixel Value','FontWeight','bold','FontSize',12);
            set(get(obj.hAx,'YLabel'),'String','Number of Pixels','FontWeight','bold','FontSize',12);
            obj.hAx.YScale = 'log';
            obj.hAx.XGrid = 'on';
            obj.hAx.YGrid = 'on';
            obj.hAx.LooseInset = [0 0 0 0] + 0.01;
            
            obj.hLutPatch = patch('Parent',obj.hAx,...
                'XData',[0,0,1,1]','YData',[1,inf,inf,1]','ZData',[1,1,1,1]',...
                'FaceAlpha',0.1,'FaceColor',[0,0,0],'EdgeColor','none',...
                'HitTest','off','PickableParts','none');
            obj.hSaturationPatch = patch('Parent',obj.hAx,...
                'XData',[0,0,1,1]','YData',[1,inf,inf,1]','ZData',[1,1,1,1]',...
                'FaceAlpha',0.1,'FaceColor',[1,0,0],'EdgeColor','none',...
                'HitTest','off','PickableParts','none','Visible','off');
            
            obj.hMeanLine = line('Parent',obj.hAx,'PickableParts','none','Hittest','off','Marker','^','LineWidth',1);
            obj.hMaxLine = line('Parent',obj.hAx,'PickableParts','none','Hittest','off','Marker','v','LineWidth',1);
            
            obj.YLim = [0.8 100];
            
            textFlow = most.gui.uiflowcontainer('Parent',hInfoFlow,'FlowDirection','TopDown');
            most.gui.uicontrol('Parent',textFlow,'Style','text','HorizontalAlignment','left');
            obj.hTxInfo = most.gui.uicontrol('Parent',textFlow,'Style','text','HorizontalAlignment','left');
            
            if strcmpi(obj.mode,'volume')
                title('Volume Snapshot');
                return;
            end

            hChanFlow = most.gui.uiflowcontainer('Parent',hInfoFlow,'FlowDirection','TopDown','WidthLimits',[60 60]);
                set(hChanFlow,'HeightLimits',[45 45]);
                most.gui.uicontrol('Parent',hChanFlow,'Style','text','String','Channel:','HeightLimits',[12 12]);
                obj.pmChannel = most.gui.uicontrol('Parent',hChanFlow,'Style','popupmenu','String',{''},'callback',@(src,evt)obj.setChannel(src,evt));
            
            hRoiFlow = most.gui.uiflowcontainer('Parent',hInfoFlow,'FlowDirection','TopDown','WidthLimits',[120 120]);
                set(hRoiFlow,'HeightLimits',[45 45]);
                most.gui.uicontrol('Parent',hRoiFlow,'Style','text','String','ROI:','HeightLimits',[12 12]);
                obj.pmRoi = most.gui.uicontrol('Parent',hRoiFlow,'Style','popupmenu','String',{''},'callback',@(src,evt)obj.setRoi(src,evt));
            
            hZFlow = most.gui.uiflowcontainer('Parent',hInfoFlow,'FlowDirection','TopDown','WidthLimits',[60 60]);
                set(hZFlow,'HeightLimits',[45 45]);
                most.gui.uicontrol('Parent',hZFlow,'Style','text','String','Z:','HeightLimits',[12 12]);
                obj.pmZ = most.gui.uicontrol('Parent',hZFlow,'Style','popupmenu','String',{''},'callback',@(src,evt)obj.setZ(src,evt));
                    
            obj.updateData(0);
            obj.viewRange = obj.dataRange;   
            obj.lut = obj.lut;

            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI,'acqState','PostSet',@obj.refresh);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI.hChannels,'channelDisplay','PostSet',@obj.refresh);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI.hDisplay,'channelsMergeEnable','PostSet',@obj.redrawPullDownMenus);

            obj.refresh();
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.hFig);
            most.idioms.safeDeleteObj(obj.hListeners);

            obj.hSI.hDisplay.removeLiveHistogram(obj);
        end

        function redrawPullDownMenus(obj, varargin)
            channels = obj.hSI.hChannels.channelDisplay;

            if isempty(channels)
                return;
            end

            rois = obj.hSI.hRoiManager.currentRoiGroup.activeRois;
            zs = unique(obj.hSI.hStackManager.zs);

            anyMatchingChannels = any(channels == obj.channel) || ~obj.channel;
            if ~anyMatchingChannels 
                obj.channel = channels(1);
                obj.pmChannel.hCtl.BackgroundColor = most.constants.Colors.yellow;
            end

            matchingROIs = arrayfun(@(roi)roi.isequalish(obj.roi),rois);
            anyMatchingROIs = any(matchingROIs);
            if ~anyMatchingROIs
                obj.roi = rois(1);
                obj.pmRoi.hCtl.BackgroundColor = most.constants.Colors.yellow;

                roiIndex = 1;
            else
                roiIndex = find(matchingROIs,1);
            end
            
            anyMatchingZs = any(zs == obj.z);
            if ~anyMatchingZs
                obj.z = zs(1);
                obj.pmZ.hCtl.BackgroundColor = most.constants.Colors.yellow;
            end

            pmChannelStrings = arrayfun(@num2str, channels, 'UniformOutput', false);
            if obj.hSI.hDisplay.channelsMergeEnable
                pmChannelStrings = [pmChannelStrings {'Merge'}];
            end
            obj.pmChannel.String = pmChannelStrings;
            obj.pmRoi.String = arrayfun(@(roi)roi.name,rois,'UniformOutput',false);
            obj.pmZ.String = arrayfun(@num2str, zs, 'UniformOutput', false);
                     
            if obj.channel
                obj.pmChannel.pmValue = num2str(obj.channel);
            else
                %Merge channel is channels 0
                obj.pmChannel.pmValue = 'Merge';
            end
            obj.pmRoi.Value = roiIndex;
            obj.pmZ.pmValue = num2str(obj.z);
        end
        
        function refresh(obj,varargin)
            if ~obj.isCamera
                obj.redrawPullDownMenus();
                obj.updateRoiDisplaySurf(obj.channel,obj.roi,obj.z);
                obj.updateLUT();
            end
        end

        function updateRoiDisplaySurf(obj,oldChannel,oldRoi,oldZ)
            try
                % If changing histogram source within a pre-existing
                % acquisition this cleans up the current roi display 
                % objects. Every new acquisition, displays are remade,
                % so this try-catch doesn't apply in that situation.
                if oldChannel
                    if ~isempty(obj.hSI.hDisplay.hAxes{oldChannel})
                        oldROIDisplay = obj.hSI.hDisplay.hAxes{oldChannel}{1};
                    end
                else
                    oldROIDisplay = obj.hSI.hDisplay.hMergeAxes{1};
                end

                if obj.channel
                    newROIDisplay = obj.hSI.hDisplay.hAxes{obj.channel}{1};
                else
                    newROIDisplay = obj.hSI.hDisplay.hMergeAxes{1};
                end

                if oldROIDisplay.roiMap.isKey(oldRoi.uuiduint64)
                    oldZSurfMap = oldROIDisplay.roiMap(oldRoi.uuiduint64);
                    oldSurf = struct();
                    if oldZSurfMap.isKey(oldZ)
                        oldSurf = oldZSurfMap(oldZ);
                        oldSurf.hHist = [];
                    end
                    oldZSurfMap(oldZ) = rmfield(oldSurf,'hHist');
                end
            catch ME
                most.ErrorHandler.logAndReportError(ME);
            end

            obj.hookIntoNewROIDisplaySurface();
        end

        function updateLUT(obj)
            if obj.channel
                obj.lut = obj.hSI.hChannels.channelLUT{obj.channel};
            else
                obj.hLutPatch.Visible = 'off';
            end
        end
        
        function setChannel(obj,src,~)
            oldChannel = obj.channel;

            if strcmpi(obj.pmChannel.pmValue,'Merge')
                obj.channel = 0;
            else
                obj.channel = str2double(obj.pmChannel.pmValue);
            end

            src.BackgroundColor = most.constants.Colors.white;

            try
                obj.updateRoiDisplaySurf(oldChannel,obj.roi,obj.z);
                obj.redrawPullDownMenus();
                obj.updateLUT();
            catch ME
                src.BackgroundColor = most.constants.Colors.lightRed;
                most.ErrorHandler.logAndReportError(ME);
            end
        end

        function setRoi(obj,src,~)
            oldRoi = obj.roi;
            roiIdx = obj.pmRoi.Value;
            roi_ = obj.hSI.hScan2D.currentRoiGroup.activeRois(roiIdx);
            obj.roi = roi_;
            src.BackgroundColor = most.constants.Colors.white;

            try
                obj.updateRoiDisplaySurf(obj.channel,oldRoi,obj.z);
                obj.redrawPullDownMenus();
            catch ME
                src.BackgroundColor = most.constants.Colors.lightRed;
                most.ErrorHandler.logAndReportError(ME);
            end 
        end

        function setZ(obj,src,~)
            oldZ = obj.z;
            obj.z = str2double(obj.pmZ.pmValue);
            src.BackgroundColor = most.constants.Colors.white;

            try
                obj.updateRoiDisplaySurf(obj.channel,obj.roi,oldZ);
                obj.redrawPullDownMenus();
            catch ME
                src.BackgroundColor = most.constants.Colors.lightRed;
                most.ErrorHandler.logAndReportError(ME);
            end
        end

        function hookIntoNewROIDisplaySurface(obj)
            try
                if obj.channel
                    roiDisplays = obj.hSI.hDisplay.hAxes;
                    roiDisplayForChannel = roiDisplays{obj.channel}{1};
                else
                    %Merge Channel is zero
                    roiDisplayForChannel = obj.hSI.hDisplay.hMergeAxes{1};
                end

                zSurfMap = roiDisplayForChannel.roiMap(obj.roi.uuiduint64);

                surfs = zSurfMap(obj.z);
                surfs.hHist = obj;
                zSurfMap(obj.z) = surfs;
                
                imData = im2gray(surfs.hSurf.CData);
                imData = imData(:)./cast(roiDisplayForChannel.dataMultiplier,'like',imData);
                obj.updateData(imData);
            catch
                %If switching between planar and MROI, you will fail to get
                %the roi from the zSurfMap, and this throws an error. We
                %don't care if that's the case.
            end
        end

        function updateData(obj,val)
            persistent timeSinceLastUpdate
            
            if isempty(timeSinceLastUpdate)
               timeSinceLastUpdate = tic(); 
            end
            
            if toc(timeSinceLastUpdate) < 0.2
               return;
            else
                timeSinceLastUpdate = tic();
            end
            
            val = val(:);
            obj.YLim(2) = numel(val);
            
            obj.hHist.Data = val;
            
            % check minimum histogram value and update YLim if necessary
            histVals = obj.hHist.Values;
            minHistVal = min((histVals(histVals>0)));
            minHistVal = minHistVal/1.25;
            minHistVal = min(minHistVal,0.8);
            
            if isempty(histVals)
                obj.hMaxLine.XData = [];
                obj.hMaxLine.YData = [];
            else
                [maxHistVal,idx] = max(histVals);
                obj.hMaxLine.XData = obj.hHist.BinEdges(idx);
                obj.hMaxLine.YData = maxHistVal;                
            end
            
            
            if ~isempty(minHistVal) && minHistVal < obj.YLim(1)
                obj.YLim(1) = minHistVal;
            end
            
            val   = single(val);
            min_  = min(val);
            max_  = max(val);
            mean_ = mean(val);
            std_  = std(val);
            obj.hTxInfo.String = sprintf('Min: %+d \tMax: %+d Mean: %+.2f SD: %+.2f' ...
                                        ,min_, max_, mean_, std_);
            
            obj.hMeanLine.XData = [-std_ 0 std_] + mean_;
            obj.hMeanLine.YData = [1 1 1] * obj.YLim(1);
        end
    end
    
    %% Property getter/setter
    methods
        function set.YLim(obj,val)
            if isequal(obj.YLim,val)
                return
            end

            if val(1) == val(2)
                val(2) = val(2) + 1;
            end
            
            obj.YLim = val;
            obj.hAx.YLim = val;
            obj.hLutPatch.YData = [val(1) val(2) val(2) val(1)]';
            obj.dataRange = obj.dataRange();
        end
        
        function set.dataRange(obj,val)
            validateattributes(val,{'numeric'},{'row','numel',2,'increasing'});
            val = round(double(val));
            obj.dataRange = val;
            
            obj.viewRange = obj.viewRange;
            
            s = obj.dataRange(1);
            e = obj.dataRange(2);
            w = (e-s) * 0.05; % saturation region
            z = 0.5;
            ll = obj.YLim(1);
            dP = obj.YLim(2);
            obj.hSaturationPatch.Vertices = [s,ll,z;...
                                             s,dP,z;...
                                             s+w,dP,z;...
                                             s+w,ll,z;...
                                             ...
                                             e-w,ll,z;...
                                             e-w,dP,z;...
                                             e,dP,z;...
                                             e,ll,z];
            obj.hSaturationPatch.FaceVertexAlphaData = [1;1;0;0;0;0;1;1].*0.3;
            obj.hSaturationPatch.FaceAlpha = 'interp';
            obj.hSaturationPatch.AlphaDataMapping = 'none';
            obj.hSaturationPatch.Faces = [1:4;5:8];
            obj.hSaturationPatch.Visible = 'on';
        end
        
        
        function set.viewRange(obj,val)
            validateattributes(val,{'numeric'},{'row','numel',2,'increasing'});
            val = round(double(val));
            val(1) = max(val(1),double(obj.dataRange(1)));
            val(2) = min(val(2),double(obj.dataRange(2)));
            obj.viewRange = val;
            
            units_ = obj.hAx.Units;
            obj.hAx.Units = 'pixel';
            pixelWidth = obj.hAx.Position(4);
            obj.hAx.Units = units_;

            binEdges = linspace(val(1)-0.5,val(2)+0.5,diff(val)+2);
            obj.hAx.XLim = binEdges([1 end]);
            
            p = ceil(length(binEdges)./pixelWidth); % reduce number of bins for display
            binEdges = binEdges(1:p:end); % the last bin might be cut off
            binEdges(end+1) = binEdges(end) + diff(binEdges(end-1:end)); % add the last bin back in
            obj.hHist.BinEdges = binEdges;
        end
        
        function set.lut(obj,val)
            validateattributes(val,{'numeric'},{'row','numel',2});
            val = sort(round(double(val)));
            
            val(1) = max([val(1),double(obj.dataRange(1))],[],'includenan');
            val(2) = min([val(2),double(obj.dataRange(2))],[],'includenan');
           
            obj.lut = val;
            
            if ~any(isnan(val)) && obj.channel
                obj.hLutPatch.Visible = 'on';
                obj.hLutPatch.XData = [val(1),val(1),val(2),val(2)]';
            else
                obj.hLutPatch.Visible = 'off';
            end
        end
        
        function set.title(obj,val)
            obj.title = val;
            title(obj.hAx,val); %#ok<CPROPLC>
        end
    end
    
    methods (Hidden)
        function scrollWheelFcn(obj,src,evt)
            mPt = obj.hAx.CurrentPoint(1,1);
            oldViewRange = obj.viewRange;
            
            zoomSpeedFactor = 1.2;
            scroll = zoomSpeedFactor ^ double(evt.VerticalScrollCount);
            obj.viewRange = (oldViewRange - mPt) * scroll + mPt;
        end
        
        function buttonDownFcn(obj,src,evt)
            axPt = obj.hAx.CurrentPoint(1,1);
            
            if abs(axPt-obj.lut(1)) < diff(obj.viewRange) * 0.02
                panLutMode = 'changeMin';
            elseif abs(axPt-obj.lut(2)) < diff(obj.viewRange) * 0.02
                panLutMode = 'changeMax';
            elseif axPt >= obj.lut(1) && axPt <= obj.lut(2)
                panLutMode = 'pan';
            else
                panLutMode = [];
            end
            
            if evt.Button == 1;
                if src == obj.hHist;
                    if any(strcmpi(panLutMode,{'changeMin','changeMax'}));
                        obj.lutPan('start',panLutMode);
                    else
                        obj.pan('start');
                    end
                elseif ~isempty(panLutMode)
                    obj.lutPan('start',panLutMode);
                else
                    obj.pan('start');
                end
            end
        end
        
        function pan(obj,mode)
            if nargin<2 || isempty(mode)
                mode = 'start';
            end
            
            persistent dragData
            persistent originalConfig
            
            try
                switch lower(mode)
                    case 'start'
                        dragData = struct();
                        dragData.startPoint = obj.hAx.CurrentPoint(1,1);
                        dragData.startViewRange = obj.viewRange;
                        
                        originalConfig = struct();
                        originalConfig.WindowButtonMotionFcn = obj.hFig.WindowButtonMotionFcn;
                        originalConfig.WindowButtonUpFcn = obj.hFig.WindowButtonUpFcn;
                        
                        obj.hFig.WindowButtonMotionFcn = @(varargin)obj.pan('move');
                        obj.hFig.WindowButtonUpFcn = @(varargin)obj.pan('stop');
                    case 'move'
                        currentPoint = obj.hAx.CurrentPoint(1,1);
                        currentViewRange = obj.viewRange;
                        
                        d = currentPoint(1) - currentViewRange(1) + dragData.startViewRange(1);
                        d = d - dragData.startPoint;
                        
                        newViewRange = dragData.startViewRange-d;
                        
                        if newViewRange(1) >= obj.dataRange(1) && newViewRange(2) <= obj.dataRange(2)
                            obj.viewRange = newViewRange;
                        end                        
                    case 'stop'
                        abort();
                    otherwise
                        assert(false);
                end
            catch ME
                abort();
                rethrow(ME);
            end
            
            %%% local function
            function abort()
                if isstruct(originalConfig) && isfield(originalConfig,'WindowButtonMotionFcn');
                    obj.hFig.WindowButtonMotionFcn = originalConfig.WindowButtonMotionFcn;
                else
                    obj.hFig.WindowButtonMotionFcn = [];
                end
                
                if isstruct(originalConfig) && isfield(originalConfig,'WindowButtonUpFcn');
                    obj.hFig.WindowButtonUpFcn = originalConfig.WindowButtonUpFcn;
                else
                    obj.hFig.WindowButtonUpFcn = [];
                end
                
                startPoint = [];
                originalConfig = struct();
            end
        end
        
        function lutPan(obj,mode,panMode)
            if nargin<2 || isempty(mode)
                mode = 'start';
            end
            
            if nargin<3 || isempty(panMode)
                panMode = 'pan';
            end
            
            persistent dragData
            persistent originalConfig
            
            try
                switch lower(mode)
                    case 'start'
                        dragData = struct();
                        dragData.startPoint = obj.hAx.CurrentPoint(1,1);
                        dragData.startLut = obj.lut;
                        
                        originalConfig = struct();
                        originalConfig.WindowButtonMotionFcn = obj.hFig.WindowButtonMotionFcn;
                        originalConfig.WindowButtonUpFcn = obj.hFig.WindowButtonUpFcn;
                        
                        obj.hFig.WindowButtonMotionFcn = @(varargin)obj.lutPan('move',panMode);
                        obj.hFig.WindowButtonUpFcn = @(varargin)obj.lutPan('stop');
                    case 'move'
                        currentPoint = obj.hAx.CurrentPoint(1,1);
                        
                        d = currentPoint(1) - dragData.startPoint;
                        
                        switch panMode
                            case 'changeMax'
                                newLut = dragData.startLut+[0 d];
                            case 'changeMin'
                                newLut = dragData.startLut+[d 0];
                            case 'pan'
                                newLut = dragData.startLut+d;
                                % constraint newLut
                                if newLut(1) < obj.dataRange(1)
                                    newLut = [obj.dataRange(1), obj.dataRange(1)+diff(newLut)];
                                elseif newLut(2) > obj.dataRange(2)
                                    newLut = [obj.dataRange(2)-diff(newLut), obj.dataRange(2)];
                                end
                            otherwise
                                assert(false);
                        end
                        
                        obj.lut = newLut;
                        
                        if ~isempty(obj.hSI) && isvalid(obj.hSI)
                            hChannels = obj.hSI.hChannels;
                            if ~isempty(obj.channel) && 0 < obj.channel
                                hChannels.channelLUT{obj.channel} = obj.lut;
                            end
                        end
                    case 'stop'
                        abort();
                        notify(obj, 'lutUpdated');
                    otherwise
                        assert(false);
                end
            catch ME
                abort();
                rethrow(ME);
            end
            
            %%% local function
            function abort()
                if isstruct(originalConfig) && isfield(originalConfig,'WindowButtonMotionFcn');
                    obj.hFig.WindowButtonMotionFcn = originalConfig.WindowButtonMotionFcn;
                else
                    obj.hFig.WindowButtonMotionFcn = [];
                end
                
                if isstruct(originalConfig) && isfield(originalConfig,'WindowButtonUpFcn');
                    obj.hFig.WindowButtonUpFcn = originalConfig.WindowButtonUpFcn;
                else
                    obj.hFig.WindowButtonUpFcn = [];
                end
                
                startPoint = [];
                originalConfig = struct();
            end
        end
        
        function closeRequestFcn(obj,src,evt)
            if isvalid(obj)
                obj.delete();
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

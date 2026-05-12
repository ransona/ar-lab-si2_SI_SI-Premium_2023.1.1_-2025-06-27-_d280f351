classdef TileController < handle
    events
        ViewSizeChanged;
        ZProjectionsUpdated;
    end
    
    properties (SetAccess = private)
        Surfaces(1,:) matlab.graphics.primitive.Surface = matlab.graphics.primitive.Surface.empty();
        ProjectionLines(1,:) matlab.graphics.primitive.Line = matlab.graphics.primitive.Line.empty();
        tileIndices(1,:) double = []; % maps control and listener tiles to tile manager indices.
        ParentAxes;
        ProjectionAxes;
        TileManager;
        RoiGroupEditor;
        ModelListeners(1,:) event.listener;
        TileImageListeners(1,:) event.listener = event.listener.empty();
        isVisible = false;

        needsSynchronization = true;
        needsPositionUpdate = true;
        needsImageRefresh = true;
        needsProjectionRefresh = true;
    end
    
    methods
        function obj = TileController(RoiGroupEditor, TileManager, Axes, ProjectionAxes)
            ChannelControls = TileManager.hSI.hChannels;
            MotorControls = TileManager.hSI.hMotors;
            SIController = TileManager.hSI.hController{1};
            TileView = SIController.hTileView;
            obj.ModelListeners = [...
                addPropertyListener(TileManager, 'hScanTiles', @(~,~)obj.scanTilesChangedCallback()) ...
                addPropertyListener(ChannelControls, 'channelLUT', @(~,~)obj.imageColorChangedCallback()) ...
                addPropertyListener(TileView, 'scanChanImageColors', @(~,~)obj.imageColorChangedCallback()) ...
                addPropertyListener(TileView, 'scanChanAlphas', @(~,~)obj.imageColorChangedCallback()) ...
                addPropertyListener(TileView, 'scanChansToShow', @(~,~)obj.imageColorChangedCallback())...
                addPropertyListener(RoiGroupEditor, 'editorZ', @(~,~)obj.scanTilesChangedCallback()) ...
                addPropertyListener(RoiGroupEditor, 'projectionMode', @(~,~)obj.projectionModeChangedCallback()) ...
                addPropertyListener(MotorControls, 'samplePosition', @(~,~)obj.motorPositionChangedCallback()) ...
                ];
            obj.RoiGroupEditor = RoiGroupEditor;
            obj.TileManager = TileManager;
            obj.ParentAxes = Axes;
            obj.ProjectionAxes = ProjectionAxes;

            function listener = addPropertyListener(source, propertyName, callback)
                listener = most.ErrorHandler.addCatchingListener(source, propertyName, 'PostSet', callback);
            end
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.TileImageListeners);
            most.idioms.safeDeleteObj(obj.ModelListeners);
        end
    end
    
    methods
        function show(obj)
            if obj.needsSynchronization
                obj.synchronizeSurfaces();
                obj.needsSynchronization = false;
            end
            
            if obj.needsPositionUpdate
                obj.synchronizeSurfacePosition();
                obj.needsPositionUpdate = false;
            end

            if obj.needsImageRefresh
                obj.synchronizeImageColors();
                obj.needsImageRefresh = false;
            end

            if obj.needsProjectionRefresh
                obj.synchronizeProjectionLines();
                obj.needsProjectionRefresh = false;
            end
            
            set([obj.Surfaces, obj.ProjectionLines], 'Visible', 'on');
            obj.isVisible = true;
            notify(obj, 'ViewSizeChanged');
            notify(obj, 'ZProjectionsUpdated');
        end
        
        function hide(obj)
            set([obj.Surfaces, obj.ProjectionLines], 'Visible', 'off');
            obj.isVisible = false;
            notify(obj, 'ViewSizeChanged');
            notify(obj, 'ZProjectionsUpdated');
        end
        
        function cornerPoints = getCornerPoints(obj)
            if isempty(obj) || isempty(obj.Surfaces)
                cornerPoints = [];
                return;
            end
            
            if isscalar(obj.Surfaces)
                xs = obj.Surfaces.XData;
                ys = obj.Surfaces.YData;
            else
                xs = cell2mat(get(obj.Surfaces, 'XData'));
                xs = xs(:);
                ys = cell2mat(get(obj.Surfaces, 'YData'));
                ys = ys(:);
            end
            
            cornerPoints = [min(xs), min(ys); max(xs), max(ys)];
        end
        
        function zs = getZs(obj)
            if isempty(obj) || isempty(obj.ProjectionLines)
                % check for empty objects because ROI Group Editor may call
                % this function before the object is instantiated.
                zs = [];
                return;
            end

            if isscalar(obj.ProjectionLines)
                zs = unique(obj.ProjectionLines.YData);
            else
                % zs must be rows because of how it's used in
                % RoiGroupEditor.
                zs = unique(cell2mat(get(obj.ProjectionLines, 'YData'))) .';
            end
        end
    end
    
    methods (Access = private)
        function motorPositionChangedCallback(obj)
            if obj.isVisible
                obj.synchronizeSurfacePosition();
                obj.synchronizeProjectionLines();
                obj.needsPositionUpdate = false;
                obj.needsProjectionRefresh = false;
                notify(obj, 'ViewSizeChanged');
            else
                obj.needsPositionUpdate = true;
                obj.needsProjectionRefresh = true;
            end
        end
        
        function scanTilesChangedCallback(obj)
            if obj.isVisible
                obj.synchronizeSurfaces();
                obj.synchronizeSurfacePosition();
                obj.synchronizeImageColors();
                obj.synchronizeProjectionLines();
                obj.needsSynchronization = false;
                obj.needsImageRefresh = false;
                obj.needsProjectionRefresh = false;
                obj.needsPositionUpdate = false;
                notify(obj, 'ViewSizeChanged');
                notify(obj, 'ZProjectionsUpdated');
            else
                obj.needsSynchronization = true;
                obj.needsImageRefresh = true;
                obj.needsProjectionRefresh = true;
                obj.needsPositionUpdate = true;
            end
        end

        function imageColorChangedCallback(obj)
            if obj.isVisible
                obj.synchronizeImageColors();
                obj.needsImageRefresh = false;
            else
                obj.needsImageRefresh = true;
            end
        end

        function projectionModeChangedCallback(obj)
            if obj.isVisible
                obj.synchronizeProjectionLines();
                obj.needsProjectionRefresh = false;
            else
                obj.needsProjectionRefresh = true;
            end
        end
        
        synchronizeSurfacePosition(obj);

        synchronizeProjectionLines(obj);
        
        synchronizeSurfaces(obj);

        synchronizeImageColors(obj);
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

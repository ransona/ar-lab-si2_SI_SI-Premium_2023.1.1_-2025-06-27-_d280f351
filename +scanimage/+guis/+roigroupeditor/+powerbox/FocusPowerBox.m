classdef FocusPowerBox < scanimage.guis.roigroupeditor.powerbox.PowerBoxDisplay
    properties
        hSurf;
        hResizePoint;
        hBrushPreview;
        
        hPowerBox;
        hListeners = event.listener.empty(0,1);
        hRoi;
        
        powerBoxUuid;
        roiUuid;
        hPBDManager;
        
        enableBrush = false;
        background = 0;
        cornerPts = [];
    end
    
    properties (SetObservable)
        brushValue = 0;
        brushSize = 0.05;
    end
    
    properties (Hidden)
        hRoiGroupEditor
        hModel
    end
    
    methods
        function obj = FocusPowerBox(hRoiGroupEditor, hPBDManager, hPowerBox, hRoi)
            obj@scanimage.guis.roigroupeditor.powerbox.PowerBoxDisplay(hRoiGroupEditor, hPowerBox);
            obj.hPBDManager =  hPBDManager;
            obj.hRoi = hRoi;
            obj.powerBoxUuid = obj.hPowerBox.uuiduint64;
            obj.roiUuid = hRoi.uuiduint64;
            
            for iScanfield = 1:length(obj.hRoi.scanfields)
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener( ...
                    obj.hRoi.scanfields(iScanfield), {'centerXY','sizeXY','enable'} ...
                    , 'PostSet', @obj.updateDisplay);
            end
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener( ...
                obj.hRoiGroupEditor, 'editorZ', 'PostSet', @obj.updateDisplay);
            
            obj.makeDisplay();
        end
        
        function delete(obj)
            if most.idioms.isValidObj(obj.hSurf)
                obj.hSurf.delete();
            end
            
            if most.idioms.isValidObj(obj.hResizePoint)
                obj.hResizePoint.delete();
            end
            
            for listIdx = 1:numel(obj.hListeners)
                listener = obj.hListeners(listIdx);
                if most.idioms.isValidObj(listener)
                    most.idioms.safeDeleteObj(obj.hListeners);
                end
            end
            obj.hListeners =  event.listener.empty(0,1);
        end
        
        function makeDisplay(obj)
            [faceAlpha, alphaData, red] = obj.getPBDisplayParams();
            [pbxx, pbyy, lxdata, lydata] = obj.calculatePosition();
            
            obj.hSurf = surface(pbxx, pbyy, 0.5*ones(2),'FaceColor','texturemap','linestyle',':','EdgeColor','w',...
                'parent',obj.hRoiGroupEditor.h2DMainViewAxes,'FaceAlpha',faceAlpha,'AlphaData',alphaData,'CData',red,'ButtonDownFcn',@obj.drag,'UserData',obj.hPowerBox.uuiduint64);
            
            obj.hResizePoint = line('XData',lxdata,'YData',lydata,'ZData',0.5*ones(size(lxdata)),'Parent',obj.hRoiGroupEditor.h2DMainViewAxes,'LineStyle','none',...
                'Marker','+','MarkerFaceColor','none','MarkerEdgeColor',[0.95, 0.05, 0.05],'Markersize',10,'LineWidth',2,'ButtonDownFcn',@obj.resize,'UserData',obj.hPowerBox.uuiduint64);
            
            obj.hBrushPreview = line('XData',[-1; 1; 1; -1; -1],'YData', [-1; -1; 1; 1; -1],'ZData',0.5*ones(5,1),'Parent',obj.hRoiGroupEditor.h2DMainViewAxes,'LineStyle','-',...
                'Marker','none','LineWidth',1.5,'visible','off','UserData',obj.hPowerBox.uuiduint64);
        end
        
        function updateDisplay(obj, varargin)
            if obj.hPowerBox.useSampleAbsolute
                obj.hPBDManager.update();
                return;
            end
            
            [faceAlpha, alphaData, red] = obj.getPBDisplayParams();
            [pbxx, pbyy, lxdata, lydata] = obj.calculatePosition();
            
            set(obj.hSurf,'XData',pbxx);
            set(obj.hSurf,'YData',pbyy);
            set(obj.hSurf,'FaceAlpha',faceAlpha);
            set(obj.hSurf,'AlphaData',alphaData);
            set(obj.hSurf,'CData',red);
            
            set(obj.hResizePoint,'XData',lxdata);
            set(obj.hResizePoint,'YData',lydata);
            
            if ~isnan(obj.brushValue)
                color = [interp1([0 1], [0.3 0.7],obj.brushValue),0,0];
            else
                color = [0.3 0 0];
            end
            set(obj.hBrushPreview,'Color',color);
            obj.hRoiGroupEditor.updateMaxViewFov();
        end
        
        function [pbxx, pbyy, lxdata, lydata] = calculatePosition(obj)
            rect = obj.hPowerBox.rect;
            
            %Draw powerboxes relative to
            %drawn scanfields
            points_normalized = [rect(1), rect(2);...
                rect(1), rect(2) + rect(4);...
                rect(1) + rect(3), rect(2);...
                rect(1) + rect(3), rect(2) + rect(4)];
            points_normalized = points_normalized - 0.5;
            
            sf = obj.hRoi.get(obj.hRoiGroupEditor.editorZ);
            
            ctr = sf.centerXY;
            sz = sf.sizeXY;
            
            pts = [points_normalized(:,1) .* sz(1),...
                points_normalized(:,2) .* sz(2)];
            
            rot = -sf.rotation * pi / 180;
            R = [cos(rot) sin(rot) 0;-sin(rot) cos(rot) 0; 0 0 1];
            pts = scanimage.mroi.util.xformPoints(pts,R);
            pts = pts + repmat(ctr,4,1);
            
            pbxx = [pts(1:2,1) pts(3:4,1)];
            pbyy = [pts(1:2,2) pts(3:4,2)];
            
            lxdata = max(pts(:,1));% + max(pts(:,1)))/2;
            lydata = max(pts(:,2));% + max(pts(:,2)))/2;
            
            obj.cornerPts = [pbxx(:), pbyy(:)];
        end
    end
    
    %% Setters
    methods
        function set.brushValue(obj,val)
            
            validateattributes(val,{'numeric'},{'scalar','nonnegative'});
            if ~isnan(val)
                assert(val <= 1,'Values must be between 0 and 1 inclusive.');
            end
            obj.brushValue = val;
            obj.updateDisplay();
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

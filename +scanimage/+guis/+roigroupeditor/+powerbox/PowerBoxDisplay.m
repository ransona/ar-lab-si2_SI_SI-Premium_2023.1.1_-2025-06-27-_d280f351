classdef PowerBoxDisplay < handle & matlab.mixin.Heterogeneous
    properties (Abstract)
        hSurf            %primitive surface. Surface to represent the powerbox boundaries and power
        hResizePoint     %primitive line.    Marker at corner of hSurf for resizing the powerbox
        hBrushPreview    %primitive line.    Preview size and power for the mask altering brush tool
        
        hPowerBox        %PowerBox.          Powerbox object paired to the display object. Only one power box per display object. Converse is untrue for Focus Powerboxes.
        hListeners       
        powerBoxUuid     %uint64.            Record powerbox Uuid to match to powerboxes. Useful in the case of powerboxes switching between sample and reference.
        
        enableBrush;     %logical.           Whether left clicks in hSurf are for dragging or painting.
        background;      %double.            value for mask when erasing with the brush or resetting the mask.
        cornerPts;       %4x2 double array.  The corner points of the powerbox in optical degrees in reference space.
    end
    
    properties (Abstract, SetObservable)
        brushValue;      %double.            Power fraction to assign to hPowerBox.mask at the appropriate indices
        brushSize;       %double.            Normalized size of the paint brush relative to the size of the powerbox
    end
    
    properties (Abstract, Hidden)
        hModel
        hRoiGroupEditor
    end
    
    methods
        function obj = PowerBoxDisplay(hRoiGroupEditor, hPowerBox,varargin)
            obj.hPowerBox = hPowerBox;
            obj.hRoiGroupEditor = hRoiGroupEditor;
            obj.hModel = hRoiGroupEditor.hModel;
                        
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hPowerBox,{'rect' 'powers' 'mask' 'oddLines' 'evenLines' 'zs' 'useSampleAbsolute' 'sampleAbsoluteLocation'}, 'PostSet', @obj.updateDisplay);
            obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hRoiGroupEditor.hModel.hBeams,{'powers'}, 'PostSet', @obj.updateDisplay);
        end
      
        function setVisibility(obj,tf)
           if tf
               obj.hSurf.Visible = 'on';
               obj.hResizePoint.Visible = 'on';
           else
               obj.hSurf.Visible = 'off';
               obj.hResizePoint.Visible = 'off';
           end
        end
    end
    
    %% Placing the Display
    methods (Abstract)
        makeDisplay(obj);
        updateDisplay(obj);
    end
    
    methods
        function [faceAlpha, alphaData, red] = getPBDisplayParams(obj)
            mask_ = obj.hPowerBox.mask;
            if isempty(mask_)
                faceAlpha = interp1([0 1], [0.3 0.7], obj.hPowerBox.powers(1));
                if isnan(faceAlpha)
                    faceAlpha = interp1([0 1], [0.3 0.7],obj.hModel.hBeams.powerFractions(1));
                    red = shiftdim([1 0.5 0],-1);
                else
                    red = shiftdim([1 0 0],-1);
                end
                    alphaData = faceAlpha;
            else
                faceAlpha = 'textureMap';
                
                alphaData = double(mask_);
                alphaData(isnan(alphaData)) = interp1([0 1], [0.3 0.7],obj.hModel.hBeams.powerFractions(1));
                alphaData = alphaData*0.4 + 0.3;
                
                red = zeros(size(mask_,1),size(mask_,2),3);
                red(:,:,1) = 1;
                %Make NaN indices orange to indicate use of beam controls
                %power.
                nanIdxs = isnan(mask_);
                Idxs = false(size(mask_,1),size(mask_,2),2);
                Idxs(:,:,2) = nanIdxs;
                red(Idxs) = 0.5;
            end
        end        
    end
    
    %% Interacting with the display
    methods
        function drag(obj,stop,hit)
            persistent ppt;
            
            if obj.enableBrush
                switch(obj.hRoiGroupEditor.hFig.SelectionType)
                    case 'normal'
                        erase = false;
                        if nargin > 2
                            ppt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                            
                            if isempty(obj.hPowerBox.mask)
                                obj.hPowerBox.mask = zeros(512,512);
                            end
                            
                            paint(erase);
                            
                            set(obj.hRoiGroupEditor.hFig,'WindowButtonMotionFcn',@(varargin)obj.drag(false),'WindowButtonUpFcn',@(varargin)obj.drag(true));
                        elseif stop
                            pt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                            obj.updateBrushPreview(pt);
                            set(obj.hRoiGroupEditor.hFig,'WindowButtonMotionFcn',@(varargin)obj.hRoiGroupEditor.powerBoxBrushHover(),'WindowButtonUpFcn',[]);
                            obj.hModel.hBeams.updateBeamBufferAsync(true);
                        else %moving
                            pt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                            obj.updateBrushPreview(pt);
                            paint(erase);
                        end
                    case 'alt'
                        erase = true;
                        if nargin > 2
                            ppt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                            
                            if isempty(obj.hPowerBox.mask)
                                obj.hPowerBox.mask = zeros(512,512);
                            end
                            
                            paint(erase);
                            
                            set(obj.hRoiGroupEditor.hFig,'WindowButtonMotionFcn',@(varargin)obj.drag(false),'WindowButtonUpFcn',@(varargin)obj.drag(true));
                        elseif stop
                            pt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                            obj.updateBrushPreview(pt);
                            set(obj.hRoiGroupEditor.hFig,'WindowButtonMotionFcn',@(varargin)obj.hRoiGroupEditor.powerBoxBrushHover(),'WindowButtonUpFcn',[]);
                            obj.hModel.hBeams.updateBeamBufferAsync(true);
                        else %moving   
                            pt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                            obj.updateBrushPreview(pt);
                            paint(erase);
                        end
                    otherwise
                        %no-op
                end
            else %dragging, changing type, or opening the power box pane
                switch(obj.hRoiGroupEditor.hFig.SelectionType)
                    case 'normal'
                        if nargin > 2
                            ppt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                            set(obj.hRoiGroupEditor.hFig,'WindowButtonMotionFcn',@(varargin)obj.drag(false),'WindowButtonUpFcn',@(varargin)obj.drag(true));
                            
                            if ~obj.hPowerBox.locked
                                obj.hRoiGroupEditor.pmPowerBoxLocation.pmValue = '';
                            end
                        elseif stop
                            set(obj.hRoiGroupEditor.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
                            if obj.hPowerBox.useSampleAbsolute
                                obj.hModel.hBeams.calculateSampleAbsolutePowerBoxRect();
                            else
                                obj.hModel.hBeams.updateBeamBufferAsync(true);
                            end
                            
                            %Update cornerPts for painting
                            obj.calculatePosition();
                        else %moving
                            if ~obj.hPowerBox.locked
                                nwpt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                                
                                delt_deg = nwpt - ppt;
                                if obj.hPowerBox.useSampleAbsolute
                                    delt_um = delt_deg .* obj.hModel.objectiveResolution;
                                    obj.hPowerBox.sampleAbsoluteLocation(1:2) = obj.hPowerBox.sampleAbsoluteLocation(1:2) + delt_um;
                                else
                                    obj.cornerPts = obj.cornerPts + delt_deg;
                                    sfCornerPts = obj.hRoi.scanfields.cornerpoints;
                                    
                                    obj.cornerPts(obj.cornerPts(:,1)>max(sfCornerPts(:,1)),1) = max(sfCornerPts(:,1));
                                    obj.cornerPts(obj.cornerPts(:,2)>max(sfCornerPts(:,2)),2) = max(sfCornerPts(:,2));
                                    obj.cornerPts(obj.cornerPts(:,1)<min(sfCornerPts(:,1)),1) = min(sfCornerPts(:,1));
                                    obj.cornerPts(obj.cornerPts(:,2)<min(sfCornerPts(:,2)),2) = min(sfCornerPts(:,2));
                                    
                                    sfSize = max(diff(sfCornerPts));
                                    newSize_norm = max(diff(obj.cornerPts))./sfSize;
                                    tlCorner_norm = (min(obj.cornerPts) - min(obj.hRoi.scanfields.cornerpoints)) ./ sfSize;
                                    
                                    obj.hPowerBox.rect = [tlCorner_norm newSize_norm];
                                end
                                ppt = nwpt;
                            end
                        end
                    case 'alt'
                        useSampleAbsolute_ = ~obj.hPowerBox.useSampleAbsolute;
                        if useSampleAbsolute_ && isempty(obj.hPowerBox.sampleAbsoluteLocation)
                            hMotors = obj.hModel.hMotors;
                            hPtAbs = hMotors.getPosition(hMotors.hCSSampleAbsolute);
                            obj.hPowerBox.sampleAbsoluteLocation = hPtAbs.points;
                        end
                        
                        obj.hPowerBox.useSampleAbsolute = ~obj.hPowerBox.useSampleAbsolute; %Destroys current power box display object and creates a new one.
                    case 'open'
                        obj.hRoiGroupEditor.openPowerBoxSettingsPane(obj.hPowerBox, obj);
                        
                        obj.hRoiGroupEditor.hPowerBoxDisplayManager.setAllVisibility(false);
                        obj.setVisibility(true);
                    otherwise
                        %no-op
                end
            end
            
            %%% Nested Functions %%%
            function pt = getPointerLocation(hAx)
                pt = hAx.CurrentPoint(1, 1:2);
            end
            
            
            
            function paint(erase)
                % Get point, figure out indices of powerbox.mask to
                % mark, and set with brushValue or background value
                % depending on boolean input argument, erase.
                nwpt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                
                sizeXY = max(diff(obj.cornerPts));
                ptOut_norm = (nwpt-min(obj.cornerPts)) ./ sizeXY;
                maskRes = fliplr(size(obj.hPowerBox.mask));
                maskIndices = maskRes .* ptOut_norm;
                columnIdx = maskIndices(1);
                rowIdx = maskIndices(2);
                
                brushSize_pix = obj.brushSize .* maskRes;
                                
                rowIdxs = max([round(rowIdx-brushSize_pix(2)/2),1]):min([round(rowIdx+brushSize_pix(2)/2),maskRes(2)]);
                columnIdxs = max([round(columnIdx-brushSize_pix(1)/2),1]):min([round(columnIdx+brushSize_pix(1)/2),maskRes(1)]);

                if erase
                    obj.hPowerBox.mask(rowIdxs,columnIdxs) = obj.background;
                else
                    obj.hPowerBox.mask(rowIdxs,columnIdxs) = obj.brushValue;
                end
            end
        end
        
        function resize(obj,stop,hit)
            persistent ppt;
            persistent powerBox;
            
            switch(obj.hRoiGroupEditor.hFig.SelectionType)
                case 'normal'
                    if nargin > 2
                        ppt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                        
                        powerBoxes = obj.hModel.hBeams.powerBoxes;
                        pbMask = arrayfun(@(pb)isequal(pb.uuiduint64, hit.Source.UserData),powerBoxes);
                        powerBox = powerBoxes(pbMask);
                        
                        set(obj.hRoiGroupEditor.hFig,'WindowButtonMotionFcn',@(varargin)obj.resize(false),'WindowButtonUpFcn',@(varargin)obj.resize(true));
                    elseif stop
                        set(obj.hRoiGroupEditor.hFig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
                        if powerBox.useSampleAbsolute
                            obj.hModel.hBeams.calculateSampleAbsolutePowerBoxRect();
                        end
                        
                        %Update cornerPts for painting
                        [pbxx, pbyy, ~, ~] = obj.calculatePosition();
                        obj.cornerPts = [pbxx(:), pbyy(:)];
                    else %resizing
                        if ~obj.hPowerBox.locked
                            nwpt = getPointerLocation(obj.hRoiGroupEditor.h2DMainViewAxes);
                            
                            delt_deg = nwpt - ppt;
                            if powerBox.useSampleAbsolute
                                delt_norm = delt_deg ./ max(diff(obj.hModel.hScan2D.nominalFovCornerPoints));
                                powerBox.rect(3:4) = powerBox.rect(3:4) + delt_norm*2;
                            else
                                delt_norm =  delt_deg ./ obj.hRoi.scanfields.sizeXY;
                                powerBox.rect(3:4) = powerBox.rect(3:4) + delt_norm;
                            end
                            ppt = nwpt;
                        end
                    end
                otherwise
            end
            function pt = getPointerLocation(hAx)
                pt = hAx.CurrentPoint(1, 1:2);
            end
        end
        
        function updateBrushPreview(obj,centerPt)
            brushXYSize = max(diff(obj.cornerPts)) .* obj.brushSize;
            
            brushXY = [centerPt(1) - brushXYSize(1)/2, centerPt(2) - brushXYSize(2)/2;...
                       centerPt(1) + brushXYSize(1)/2, centerPt(2) - brushXYSize(2)/2;...
                       centerPt(1) + brushXYSize(1)/2, centerPt(2) + brushXYSize(2)/2;...
                       centerPt(1) - brushXYSize(1)/2, centerPt(2) + brushXYSize(2)/2;...
                       centerPt(1) - brushXYSize(1)/2, centerPt(2) - brushXYSize(2)/2;...
                       ];
            obj.hBrushPreview.XData = brushXY(:,1);
            obj.hBrushPreview.YData = brushXY(:,2);
        end
        
        function centerBrush(obj)
            center = mean(obj.cornerPts);
            obj.updateBrushPreview(center);
        end
        
        function resetMask(obj)
            obj.hPowerBox.mask(:,:) = obj.background;
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

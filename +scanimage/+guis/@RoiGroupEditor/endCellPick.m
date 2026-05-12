function endCellPick(obj,tfCreate)
    most.idioms.safeDeleteObj(obj.cellPickSurfs);
    obj.cellPickSurfs = [];

    if ~tfCreate
        return;
    end

    obj.enableListeners = false;

    sf = [];
    roi = [];

    for i = 1:numel(obj.cellPickZs)
        for j = 1:numel(obj.cellPickCellsAtZ{i})
            cll = obj.cellPickCellsAtZ{i}(j);

            ptMin = min(cll.pts);
            ptMax = max(cll.pts);
            pixDiffs = ptMax - ptMin + 1;

            refPts = [ptMax; ptMin-1] ./ repmat(cll.imSz,2,1);
            refPts = scanimage.mroi.util.xformPoints(refPts,cll.aff);
            refdiffs = refPts(1,:) - refPts(2,:);
            refCtr = mean(refPts);

            roi = scanimage.mroi.Roi;

            %                         [~,~,~,~,rot,~] = scanimage.mroi.util.paramsFromTransform(cll.aff);

            switch obj.editorMode
                case 'imaging'
                    sf = obj.createSf(refCtr,refdiffs+obj.cellPickRoiMargin);
                    roi.discretePlaneMode = obj.cellPickCreateAsDiscrete;

                case 'stimulation'
                    sf = obj.createSf(refCtr,refdiffs);
                    if obj.cellPickPauseDuration > 0
                        pSf = scanimage.mroi.scanfield.fields.StimulusField('scanimage.mroi.stimulusfunctions.pause',{},obj.cellPickPauseDuration/1000,...
                            1,[obj.defaultRoiPositionX obj.defaultRoiPositionY],[obj.defaultRoiWidth obj.defaultRoiHeight]/2,0,obj.defaultStimPower);
                        pRoi = scanimage.mroi.Roi;
                        pRoi.add(obj.cellPickZs(i),pSf);
                        obj.editingGroup.add(pRoi);
                    end

                case 'analysis'
                    % compute size oversized by margin but quantized to make mask still fit cell
                    overPixdiffs = ceil(pixDiffs .* (refdiffs+obj.cellPickRoiMargin*2) ./ refdiffs);
                    overSz = overPixdiffs-pixDiffs;
                    overPixdiffs = pixDiffs + ceil(overSz/2)*2;

                    sf = obj.createSf(refCtr,refdiffs .* overPixdiffs ./ pixDiffs);

                    roi.discretePlaneMode = obj.cellPickCreateAsDiscrete;
                    if obj.cellPickCreateWithMask
                        % pad with zeros to account for margin
                        diffmrg = floor((overPixdiffs-pixDiffs)/2);

                        overPixdiffs = fliplr(overPixdiffs);
                        msk = zeros(overPixdiffs);
                        pts = cll.pts - repmat(ptMin,size(cll.pts,1),1)+1;
                        msk(sub2ind(overPixdiffs,pts(:,2)+diffmrg(1),pts(:,1)+diffmrg(2))) = 1;
                        sf.mask = msk;
                    end
            end

            roi.add(obj.cellPickZs(i),sf);
            obj.editingGroup.add(roi);
        end
    end

    obj.satisfyConstraints(sf);
    obj.enableListeners = true;

    obj.updateScanPathCache();
    obj.changeSelection(sf, roi);
    obj.updateTable();
    obj.updateDisplay();
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

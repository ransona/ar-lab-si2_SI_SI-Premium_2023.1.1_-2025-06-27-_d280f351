function optimizePath(obj)
    if ~obj.editorModeIsStim || obj.editingGroup.getNumNonPause() <= 0
        return;
    end
    
    obj.enableListeners = false;

    try
        % ensure uniform sample rate for all scanners
        sampleRate = obj.scannerSet.scanners{1}.sampleRateHz;
        obj.scannerSet.scanners{2}.sampleRateHz = sampleRate;
        if obj.scannerSet.hasBeams
            obj.scannerSet.beams(1).sampleRateHz = sampleRate;
        end
        if obj.scannerSet.hasFastZ
            obj.scannerSet.fastz(1).sampleRateHz = sampleRate;
        end
        minDur = 10/sampleRate;

        % remove empty rois
        emptyRois = arrayfun(@(r)~numel(r.scanfields),obj.editingGroup.rois);
        emptyRois = [obj.editingGroup.rois(emptyRois).uuiduint64];
        arrayfun(@(id)obj.editingGroup.removeById(id), emptyRois, 'UniformOutput', false);

        if obj.optimizeStimuli
            % find where the stimuli are
            isStim = arrayfun(@(x)~x.scanfields(1).isPause && ~x.scanfields(1).isPoint && ~x.scanfields(1).isPark,obj.editingGroup.rois);
            stimIds = find(isStim);

            for id = stimIds
                sf = obj.editingGroup.rois(id).scanfields(1);
                [stimPts,~] = obj.scannerSet.scanPathStimulusFOV(sf,0,obj.editingGroup.rois(id).zs(1),0,true,false);
                if isfield(stimPts,'Z')
                    P = [stimPts.G stimPts.Z];
                else
                    P = [stimPts.G zeros(size(stimPts.G,1),1)];
                end

                V = (P(2:end,:) - P(1:end-1,:)) * sampleRate;
                A = (V(2:end,:) - V(1:end-1,:)) * sampleRate;

                Vm = max(abs(V),[],1);
                Vscl = min([obj.xyMaxVel obj.xyMaxVel obj.zMaxVel] ./ Vm);

                Am = max(abs(A),[],1);
                Ascl = min([obj.xyMaxAccel obj.xyMaxAccel obj.zMaxAccel] ./ Am)^.5;

                scl = min([Vscl Ascl]);
                t = obj.editingGroup.rois(id).scanfields(1).duration;
                obj.editingGroup.rois(id).scanfields(1).duration = max(minDur, t / scl);
            end
        end

        if obj.optimizeTransitions
            % ensure there is one and only one pause between rois
            i = 1;
            N = numel(obj.editingGroup.rois);
            while i <= N
                previ = mod(i-2,N)+1;
                if obj.editingGroup.rois(i).scanfields.isPause || obj.editingGroup.rois(i).scanfields.isPark
                    if obj.editingGroup.rois(previ).scanfields.isPause
                        %previous was a pause. remove it
                        obj.editingGroup.removeById(previ);
                        if previ < i
                            i = i-1;
                        end
                    end
                else
                    previ = mod(i-2,N)+1;
                    if ~obj.editingGroup.rois(previ).scanfields.isPause
                        obj.quickAddPause(i-1,true);
                        i = i+1;
                    end
                end

                i = i+1;
                N = numel(obj.editingGroup.rois);
            end

            % find where the transitions and parks are
            isTrans = arrayfun(@(x)x.scanfields(1).isPause,obj.editingGroup.rois);
            transIds = find(isTrans);

            isParks = arrayfun(@(x)x.scanfields(1).isPark,obj.editingGroup.rois);
            parkIds = find(isParks);

            % get the points for the stims between transistions
            for id = setdiff(1:numel(obj.editingGroup.rois),transIds)
                roi = obj.editingGroup.rois(id);
                sf = roi.scanfields(1);
                isWayP(id) = sf.isWayPoint;
                if isWayP(id)
                    paths{id} = [sf.centerXY obj.editingGroup.rois(id).zs(1)];
                elseif sf.isPark
                    paths{id} = inf;
                else
                    [stimPts,~] = obj.scannerSet.scanPathStimulusFOV(sf,roi.zs,roi.zs,0,true,false);
                    if isfield(stimPts,'Z')
                        paths{id} = [stimPts.G stimPts.Z];
                    else
                        paths{id} = [stimPts.G zeros(size(stimPts.G,1),1)];
                    end
                end
            end

            % optimize each transition
            % start with simple average velocity solution
            bth = [transIds parkIds];
            for i = 1:numel(bth)
                id = bth(i);

                % figure out start and end position
                previ = mod(id-2,N)+1;
                if paths{previ}(1) == inf
                    strtP = [obj.scannerSet.mirrorsActiveParkPosition() 0];
                    wayPt = 0;
                else
                    strtP = paths{previ}(end,:);

                    if isWayP(previ)
                        % half of the waypoint time belongs to this transision
                        wayPt = obj.editingGroup.rois(previ).scanfields(1).duration / 2;
                    else
                        wayPt = 0;
                    end
                end

                if ismember(id,parkIds)
                    endP = [obj.scannerSet.mirrorsActiveParkPosition() 0];
                else
                    nxti = mod(id,N)+1;
                    endP = paths{nxti}(1,:);
                    if isWayP(nxti)
                        % half of the waypoint time belongs to this transision
                        wayPt = wayPt + obj.editingGroup.rois(nxti).scanfields(1).duration / 2;
                    end
                end

                % optimize by average velocity
                dist = abs(endP - strtP);
                t = dist ./ [obj.xyMaxVel obj.xyMaxVel obj.zMaxVel];
                obj.editingGroup.rois(id).scanfields(1).duration = max(minDur, max(t) - wayPt);
            end

            % generate the AO and check acceleration limits.
            % Iterate this process N times
            N = 4;
            for it = 1:N
                [pth,~,~] = obj.editingGroup.scanStackFOV(obj.scannerSet,0,0,'',0,[],[],[]);
                if ~isfield(pth,'Z')
                    pth.Z = zeros(size(pth.G,1),1);
                end

                j = 1;
                p1 = [pth.G(end,:) pth.Z(end)];
                v1 = (p1 - [pth.G(end-1,:) pth.Z(end-1)]) * sampleRate;
                for i = 1:numel(obj.editingGroup.rois)
                    if ~isempty(obj.editingGroup.rois(i).scanfields)
                        T = obj.scannerSet.scanTime(obj.editingGroup.rois(i).scanfields(1));
                        jdur = obj.scannerSet.nsamples(obj.scannerSet.scanners{1},T);
                        je = j+jdur-1;

                        if ismember(i,bth)
                            if i == numel(obj.editingGroup.rois)
                                p2 = [pth.G(1,:) pth.Z(1)];
                                v2 = ([pth.G(2,:) pth.Z(2)] - p2) * sampleRate;
                            else
                                p2 = [pth.G(je+1,:) pth.Z(je+1)];
                                v2 = ([pth.G(je+2,:) pth.Z(je+2)] - p2) * sampleRate;
                            end

                            t = [scanimage.mroi.util.revMAA(p1(1), v1(1), p2(1), v2(1), obj.xyMaxVel, obj.xyMaxAccel);...
                                scanimage.mroi.util.revMAA(p1(2), v1(2), p2(2), v2(2), obj.xyMaxVel, obj.xyMaxAccel);...
                                scanimage.mroi.util.revMAA(p1(3), v1(3), p2(3), v2(3), obj.zMaxVel, obj.zMaxAccel)];

                            obj.editingGroup.rois(i).scanfields(1).duration = max(minDur, max(t));
                        else
                            p1 = [pth.G(je,:) pth.Z(je)];
                            v1 = (p1 - [pth.G(je-1,:) pth.Z(je-1)]) * sampleRate;
                        end

                        j = je+1;
                    end
                end
            end
        end

        obj.enableListeners = true;
        obj.updateScanPathCache();
        obj.rgChanged();
    catch ME
        obj.enableListeners = true;
        obj.updateScanPathCache();
        obj.rgChanged();
        ME.rethrow();
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

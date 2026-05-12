function setEditorGroupAndMode(obj,group,scannerset,mode)
    import scanimage.mroi.scanfield.fields.StimulusField;

    % this method can be called before the GUI is initialized
    % ensure initialization before continuing
    obj.initGuiOnce();

    if nargin > 3
        obj.editorMode = mode;
    end

    % for slm pattern editing, obj.slmPatternRoiParent must be
    % populated before setting the scannerset to properly represent
    % the slm FOV when offset by the galvos
    if obj.editorModeIsSlm
        if isempty(group) || ~isa(group, 'scanimage.mroi.Roi')
            obj.slmPatternRoiParent = scanimage.mroi.Roi;

            stimFunctionHandle = 'scaniamge.mroi.stimulusfunctions.point';
            stimParameters = {};
            stimDuration = obj.defaultStimDuration / 1000;
            numRepetitions = 1;
            centerXY = [0 0];
            scalingXY = [obj.defaultRoiWidth, obj.defaultRoiHeight] / 2;
            obj.slmPatternSfParent = StimulusField( ...
                stimFunctionHandle, ...
                stimParameters, ...
                stimDuration,...
                numRepetitions, ...
                centerXY, ...
                scalingXY, ...
                obj.defaultRoiRotation, ...
                obj.defaultStimPower);
            obj.slmPatternRoiParent.add(0,obj.slmPatternSfParent);
        else
            obj.slmPatternRoiParent = group;
            obj.slmPatternSfParent = group.scanfields(1);
        end
    end

    if isempty(scannerset)
        obj.scannerSet = scanimage.mroi.scannerset.GalvoGalvo.default;
    else
        obj.scannerSet = scannerset;
    end

    most.idioms.safeDeleteObj(obj.hSlmListeners);

    if obj.editorModeIsSlm
        eventDelay = 0.5;
        obj.hSlmListeners = most.util.DelayedEventListener( ...
            eventDelay, ...
            obj.slmPatternRoiParent, ...
            'changed', ...
            @(varargin)obj.slmPropsPanelUpdate);

        obj.slmPatternType = [];

        obj.slmPropsPanelUpdate();
    else
        obj.editingGroup = group;
    end

    obj.changeSelection();
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

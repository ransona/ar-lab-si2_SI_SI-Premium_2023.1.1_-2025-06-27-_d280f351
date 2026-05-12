function loadGroup(obj,varargin)
    [filename,pathname] = uigetfile('.roi','Choose file to load ROI group from',...
        obj.getClassDataVar('lastFile'));
    if 0 == filename
        return;
    end
    filename = fullfile(pathname,filename);
    obj.setClassDataVar('lastFile',filename);

    try
        obj.hFig.Pointer = 'watch';
        drawnow();

        roigroup = scanimage.mroi.RoiGroup.loadFromFile(filename);
        assert(~isempty(roigroup.rois) && ~isempty(roigroup.rois(1).scanfields), ...
            'Selected ROI group is empty');

        switch class(roigroup.rois(1).scanfields)
            case 'scanimage.mroi.scanfield.fields.RotatedRectangle'
                t = 'imaging';
            case 'scanimage.mroi.scanfield.fields.StimulusField'
                t = 'stimulation';
            case 'scanimage.mroi.scanfield.fields.IntegrationField'
                t = 'analysis';
            otherwise
                error('Unrecognized ROI type.');
        end

        if obj.editorModeIsImaging || obj.editorModeIsStim
            assert(strcmp(t,obj.editorMode), ...
                ['Only %s ROIs can be imported into this ROI group. Selected file contains ' ...
                '%s ROIs.'],obj.editorMode,t);
        else
            if strcmp(t,'imaging')
                roigroup = obj.convertImagingToIntegrationRois(roigroup);
            else
                assert(strcmp(t,obj.editorMode), ['Only imaging or stimulation ROIs can be ' ...
                    'imported into this ROI group. Selected file contains %s ROIs.'],t);
            end
        end

        obj.enableListeners = false;
        obj.editingGroup.copyobj(roigroup);
        obj.enableListeners = true;
        delete(roigroup);
        obj.rgChangedPar();
        obj.setZProjectionLimits();
        obj.hFig.Pointer = 'arrow';
    catch ME
        obj.hFig.Pointer = 'arrow';
        warndlg(sprintf('Failed to import ROIs. %s', ME.message),'ROI Group Import');
        ME.rethrow;
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

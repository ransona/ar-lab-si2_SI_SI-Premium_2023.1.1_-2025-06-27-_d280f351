classdef ScannerLagCompensation < dabs.resources.Device & most.HasMachineDataFile & dabs.resources.widget.HasWidget & dabs.resources.configuration.HasConfigPage
    properties (SetAccess = protected)
        WidgetClass = 'dabs.resources.widget.widgets.ScannerLagCompWidget';
    end

    properties (SetObservable)
        hSI
        hRoiManager scanimage.components.RoiManager
        xActuatorLag_ms = 0;
        yActuatorLag_ms = 0;
        zoom2XLagLut = [1 0; 1000 0];
        zoom2YLagLut = [1 0; 1000 0];
        hListeners (1,:) event.listener
    end

     %% ABSTRACT PROPERTY REALIZATIONS (most.HasMachineDataFile)
    properties (Constant, Hidden)
        %Value-Required properties
        mdfClassName = mfilename('class');
        mdfHeading = 'Scanner Lag Compensation';
        
        %Value-Optional properties
        mdfDependsOnClasses; %#ok<MCCPI>
        mdfDirectProp;       %#ok<MCCPI>
        mdfPropPrefix;       %#ok<MCCPI>
        
        mdfDefault = defaultMdfSection();
    end
    
    properties (SetAccess = protected,Hidden)
        ConfigPageClass = 'dabs.resources.configuration.resourcePages.BlankPage';
    end
    
    methods (Static)
        function names = getDescriptiveNames()
            names = {'Scanner Lag Compensation'};
        end
    end

    %% Lifecycle
    methods
        function obj = ScannerLagCompensation(name)
            obj = obj@dabs.resources.Device(name);
            obj = obj@most.HasMachineDataFile(true);
            
            obj.hListeners(end+1) = addlistener(obj.hResourceStore,'hResources','PostSet',@(varargin)obj.setComponents());

            obj.deinit();
            obj.loadMdf();
            obj.reinit();
        end

        function reinit(obj)
            try
                obj.setComponents;

                obj.errorMsg = '';
            catch ME
                obj.errorMsg = ME.message;
            end
        end

        function setComponents(obj)
            hSI = obj.hResourceStore.filterByName('ScanImage');
            hRoiManager = obj.hResourceStore.filterByName('SI RoiManager');

            if most.idioms.isValidObj(hSI) && ~most.idioms.isValidObj(obj.hSI)
                obj.hSI = hSI;
                obj.hListeners(end+1) = addlistener(obj.hSI,'hScan2D','PreSet',@(varargin)obj.saveCalibration());
                obj.hListeners(end+1) = addlistener(obj.hSI,'hScan2D','PostSet',@(varargin)obj.loadCalibration());
            end
            
            if most.idioms.isValidObj(hRoiManager) && ~most.idioms.isValidObj(obj.hRoiManager)
                obj.hRoiManager = hRoiManager;
                obj.hListeners(end+1) = addlistener(obj.hRoiManager,'scanZoomFactor','PostSet',@(varargin)obj.setActuatorLagFromLut());
            end
        end

        function deinit(obj)

        end

        function loadMdf(obj)
            try
                obj.loadCalibration();
            catch
            end
        end

        function loadCalibration(obj)
            if ~most.idioms.isValidObj(obj.hSI)
                return;
            end

            [PATH, ~, EXT] = fileparts(mfilename("fullpath"));
            fname = sprintf('%s\\private\\%s_%s%s',PATH,obj.name,obj.hSI.hScan2D.name,'.json');

            if isfile(fname)
                s = most.json.loadjson(fname);
                obj.zoom2XLagLut = s.zoom2XLagLut;
                obj.zoom2YLagLut = s.zoom2YLagLut;
            else
                obj.zoom2XLagLut = [1 0; 1000 0];
                obj.zoom2YLagLut = [1 0; 1000 0];
            end

            obj.setActuatorLagFromLut();
        end
        
        function saveMdf(obj)
            try
                obj.saveCalibration();
            catch
            end
        end

        function saveCalibration(obj)
            if ~most.idioms.isValidObj(obj.hSI) || ~most.idioms.isValidObj(obj.hSI.hScan2D)
                return;
            end

            [PATH, ~, ~] = fileparts(mfilename("fullpath"));
            dir = sprintf('%s\\private',PATH);
            if ~isfolder(dir)
                mkdir(PATH,'private');
            end

            s = struct('zoom2XLagLut',obj.zoom2XLagLut,'zoom2YLagLut',obj.zoom2YLagLut);
            most.json.savejson('',s, ...
                sprintf('%s\\%s_%s%s',dir,obj.name,obj.hSI.hScan2D.name,'.json'));
        end

        function delete(obj)
            obj.saveMdf();
            obj.hListeners.delete();
        end
    end

    %% Class Methods
    methods
        function setNewActuatorLag(obj,val,dir)
            zoom = obj.hRoiManager.scanZoomFactor;

            if isempty(obj.hSI)
                return;
            end

            hScan2D = obj.hSI.hScan2D;
            switch dir
                case {'x'}
                    obj.xActuatorLag_ms = val;

                    if most.idioms.isValidObj(hScan2D)
                        hScan2D.xActuatorLag_ms = val;
                        hScan2D.updateLiveValues();
                    end

                    mask = obj.zoom2XLagLut(:,1) == zoom;
                    if any(mask)
                        obj.zoom2XLagLut(mask,:) = [zoom val];
                    else
                        obj.zoom2XLagLut(end+1,:) = [zoom,val];
                    end                
                case {'y'}
                    obj.yActuatorLag_ms = val;

                    if most.idioms.isValidObj(hScan2D)
                        hScan2D.yActuatorLag_ms = val;
                        hScan2D.updateLiveValues();
                    end

                    mask = obj.zoom2YLagLut(:,1) == zoom;
                    if any(mask)
                        obj.zoom2YLagLut(mask,:) = [zoom val];
                    else
                        obj.zoom2YLagLut(end+1,:) = [zoom,val];
                    end
                otherwise
            end

        end

        function setActuatorLagFromLut(obj)
            zoom = obj.hRoiManager.scanZoomFactor;
            obj.xActuatorLag_ms = interp1(obj.zoom2XLagLut(:,1),obj.zoom2XLagLut(:,2),zoom,"linear","extrap");
            obj.yActuatorLag_ms = interp1(obj.zoom2YLagLut(:,1),obj.zoom2YLagLut(:,2),zoom,"linear","extrap");

            hScan2D = obj.hSI.hScan2D;
            if most.idioms.isValidObj(hScan2D)
                hScan2D.xActuatorLag_ms = obj.xActuatorLag_ms;
                hScan2D.yActuatorLag_ms = obj.yActuatorLag_ms;
                hScan2D.updateLiveValues();
            end
        end
    end

        %% Setters and Getters
    methods
        function set.xActuatorLag_ms(obj,val)
            arguments
                obj
                val (1,1) double
            end

            obj.xActuatorLag_ms = val;
        end

        function set.yActuatorLag_ms(obj,val)
            arguments
                obj
                val (1,1) double
            end

            obj.yActuatorLag_ms = val;
        end

        function set.zoom2XLagLut(obj,val)
            if isempty(val)
                val = [1 0];
            end

            val = validateLUT(val);
            obj.zoom2XLagLut = val;

            function val = validateLUT(val)
                validateattributes(val,{'numeric'},{'ncols',2,'finite','nonnan','real'});

                xx = val(:,1);
                yy = val(:,2);

                %sort LUT
                [~,sortIdx] = sort(xx);
                xx = xx(sortIdx);
                yy = yy(sortIdx);
            end
        end

        function set.zoom2YLagLut(obj,val)
            if isempty(val)
                val = [1 0];
            end

            val = validateLUT(val);
            obj.zoom2YLagLut = val;

            function val = validateLUT(val)
                validateattributes(val,{'numeric'},{'ncols',2,'finite','nonnan','real'});

                xx = val(:,1);
                yy = val(:,2);

                %sort LUT
                [~,sortIdx] = sort(xx);
                xx = xx(sortIdx);
                yy = yy(sortIdx);
            end
        end
    end
end

function s = defaultMdfSection()
s = [...
    most.HasMachineDataFile.makeEntry('Nothing to Configure')...
    ];
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

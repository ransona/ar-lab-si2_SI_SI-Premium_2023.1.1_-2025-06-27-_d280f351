classdef recolorGuis < dabs.resources.Device & most.HasMachineDataFile & dabs.resources.configuration.HasConfigPage
    %% ABSTRACT PROPERTY REALIZATIONS (most.HasMachineDataFile) 
    properties (Constant, Hidden)
        %Value-Required properties
        mdfClassName = mfilename('class');
        mdfHeading = '';
        
        %Value-Optional properties
        mdfDependsOnClasses; %#ok<MCCPI>
        mdfDirectProp;       %#ok<MCCPI>
        mdfPropPrefix;       %#ok<MCCPI>
        
        mdfDefault = defaultMdfSection();
    end
    
    properties (SetAccess = protected,Hidden)
        ConfigPageClass = 'dabs.resources.configuration.resourcePages.recolorGuisPage';
    end
    
    methods (Static)
        function names = getDescriptiveNames()
            names = {'Recolor GUIs'};
        end
    end
    
    properties
       colorMap containers.Map;
       color = [171, 200, 245]./255; 
    end
    
    properties (SetAccess = private, GetAccess = private)
        hListeners = event.listener.empty();
        hResourceStoreListener = event.listener.empty();
        hSI = dabs.resources.Resource.empty();
    end
    
    %% Lifecycle
    methods
        function obj = recolorGuis(name)
            obj@dabs.resources.Device(name);
            obj = obj@most.HasMachineDataFile(true);

            % must initialize color map here, otherwise it will be shared by all classes
            % (A property default value that is a handle will cause all instances to share the same object data.
            % To avoid sharing, create the property value in the constructor. For intentional sharing, consider using a Constant property.)
            obj.colorMap = containers.Map.empty(0,1);

            obj.hResourceStoreListener = most.ErrorHandler.addCatchingListener(obj.hResourceStore,'hResources','PostSet',@(varargin)obj.resourcesChanged);
            
            obj.deinit();
            obj.loadMdf();
            obj.reinit();
        end
        
        function delete(obj)
            obj.deinit();
            most.idioms.safeDeleteObj(obj.hResourceStoreListener);
        end
    end
    
    %% Initialization
    methods
        function reinit(obj)
            try
                obj.deinit();
                
                hSI_ = obj.hResourceStore.filterByClass('scanimage.SI');
                
                assert(~isempty(hSI_),'ScanImage is not initialized');
                most.idioms.safeDeleteObj(obj.hResourceStoreListener);
                obj.hSI = hSI_{1};
                
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI,'imagingSystem' ,'PostSet',@(varargin)obj.scannerChanged);
                obj.hListeners(end+1) = most.ErrorHandler.addCatchingListener(obj.hSI,'applicationOpen','PostSet', @(varargin)obj.applicationOpened);
                
                if ~isempty(obj.hSI.hScan2D) && ~isempty(obj.hSI.hScan2D.name)
                    obj.scannerChanged();
                end
                
                obj.errorMsg = '';
                
            catch ME
                obj.deinit();
                obj.errorMsg = sprintf('%s: initialization error: %s',obj.name,ME.message);
                most.ErrorHandler.logError(ME,obj.errorMsg);
            end
        end
        
        function deinit(obj)
            obj.errorMsg = 'Uninitialized';
            
            delete(obj.hListeners);
            obj.hListeners = event.listener.empty();
            
            obj.hSI = dabs.resources.Resource.empty();
        end
        
        function loadMdf(obj)
            obj.colorMap = containers.Map(obj.mdfData.scanners, obj.mdfData.colors);
        end
        
        function saveMdf(obj)
            mdf = most.MachineDataFile.getInstance();
            if mdf.isLoaded
                
                mdf.removeStructFromHeading(obj.custMdfHeading, 'virtualChannelSettings');
               
                saveVar('scanners', obj.colorMap.keys, true);
                saveVar('colors', obj.colorMap.values, true);
            end
            
            function saveVar(nm,val,commit)
                mdf.writeVarToHeading(obj.custMdfHeading,nm,val,'',commit);
            end
        end
    end
    
    %% Internal methods
    methods
        function scannerChanged(obj)
            obj.color = obj.colorMap(obj.hSI.hScan2D.name);
            obj.colorGuis();
        end
        
        function resourcesChanged(obj)
            % if uninitialized, try to attach to ScanImage
            if ~isempty(obj.errorMsg)
                obj.reinit();
            end
        end
        
        function applicationOpened(obj,evt)
            obj.reinit();
        end
        
        function colorGuis(obj)
            if ~isempty(obj.hSI) && obj.hSI.applicationOpen
                scanimage.util.recolorGuis(obj.color);
            end
        end
    end
end

function s = defaultMdfSection()
s = ...
    [most.HasMachineDataFile.makeEntry('scanners'   , '{ImagingScanner}'   ,'Order of imaging scanners associated with the order of colors. Ordinarily, this should not be modified by the user.')...
    most.HasMachineDataFile.makeEntry('colors', {[0.9 , 0.9 , 0.9]},'Cell array or RGB vectors. Cell ordering corresponds to scanner order above.');...
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

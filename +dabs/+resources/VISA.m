classdef VISA < dabs.resources.Resource
    properties (SetAccess = private)
        driverInfo
    end
    
    methods
        function obj = VISA(name)
            obj@dabs.resources.Resource(name);
        end
    end
    
    methods (Static)
        function [v,driverInfo] = scanSystem()
            hResourceStore = dabs.resources.ResourceStore();
            
            instrNames = {};
            try
                [instrNames,driverInfo] = dabs.ivi.visa.findResources();
            catch ME
                if strcmpi(ME.message,'VISA driver is not installed.')
                    % VISA driver is not installed
                else
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
            
            existingVisaResources = hResourceStore.filterByClass('dabs.resources.VISA');
            existingNames = cellfun(@(hR)hR.name,existingVisaResources,'UniformOutput',false);
            [~,toDeleteMask] = setdiff(existingNames,instrNames);
            cellfun(@(hR)hR.delete,existingVisaResources(toDeleteMask));
            
            for idx = 1:numel(instrNames)
                name = instrNames{idx};
                if isempty(hResourceStore.filterByName(name))
                    h = dabs.resources.VISA(name);
                    h.driverInfo = driverInfo;
                end
            end
            
            v = hResourceStore.filterByClass('dabs.resources.VISA');
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

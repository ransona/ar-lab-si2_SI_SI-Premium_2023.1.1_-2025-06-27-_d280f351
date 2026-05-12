classdef NIFlexRIO < dabs.resources.daqs.NIRIO & most.HasMachineDataFile & dabs.resources.configuration.HasConfigPage & dabs.resources.Device
    %% ABSTRACT PROPERTY (most.HasMachineDataFile)
    properties (Constant, Hidden)
        %Value-Required properties
        mdfClassName = mfilename('class');
        mdfHeading = 'Simulated NIRIO';
        
        %Value-Optional properties
        mdfDependsOnClasses; %#ok<MCCPI>
        mdfDirectProp;       %#ok<MCCPI>
        mdfPropPrefix;       %#ok<MCCPI>
        
        mdfDefault = defaultMdfSection();
    end
    
    properties (SetAccess=protected,Hidden)
        ConfigPageClass = 'dabs.resources.configuration.resourcePages.BlankPage';
    end
    
    methods (Static)
        function names = getDescriptiveNames()
            names = {'DAQ\Simulated FlexRIO 7961+5734'};
        end
    end
    
    methods
        function obj = NIFlexRIO(~)
            rioInfo = dabs.ni.configuration.findFlexRios();
            rioNames = fieldnames(rioInfo);
            rioNumbers = regexpi(rioNames,'(?<=^RIO)[0-9]+','match','once');
            rioNumbers = cellfun(@(n)str2double(n),rioNumbers);
            
            if isempty(rioNumbers)
                name = 'RIO0';
            else
                name = sprintf('RIO%d',max(rioNumbers)+1);
            end
            
            obj@dabs.resources.daqs.NIRIO(name);
            obj@dabs.resources.Device(name);
            obj@most.HasMachineDataFile(true);
        end
    end
end

%% Default MDF Values
function s = defaultMdfSection()
    s = [ ...
        most.HasMachineDataFile.makeEntry('Nothing to configure') ...
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

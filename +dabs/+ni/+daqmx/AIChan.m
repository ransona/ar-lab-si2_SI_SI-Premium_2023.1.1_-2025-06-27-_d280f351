classdef AIChan < dabs.ni.daqmx.private.AnalogChan
    %AICHAN A DAQmx Analog Input Channel
    
    properties (Constant)
        type = 'AnalogInput';
    end
    
    properties (Constant, Hidden)
        typeCode = 'AI';
    end
    
    %% CONSTRUCTOR/DESTRUCTOR
    methods
        function obj = AIChan(varargin)
            %Constructor required, as this is a concrete subclass of abstract lineage
            obj = obj@dabs.ni.daqmx.private.AnalogChan(varargin{:});
            
        end
    end
    
    %% METHODS
    
    methods (Hidden)
        
        function postCreationListener(obj)
            %Handle input data type
            errorCond = false;
            for i=1:length(obj)
                rawSampSize = obj(i).getQuiet('rawSampSize');
                switch rawSampSize
                    case 8
                        rawSampClass = 'int8';
                    case 16
                        rawSampClass = 'int16';
                    case 32
                        rawSampClass = 'int32';
                    otherwise
                        errMessage = ['Unsupported sample size (' num2str(rawSampSize) '). Task deleted.'];
                        errorCond = true;
                        break;
                end
                if isempty(obj(i).task.rawDataArrayAI)
                    obj(1).task.rawDataArrayAI = feval(rawSampClass,0); %Creates a scalar array of rawSampClass
                elseif ~strcmpi(class(obj(i).task.rawDataArrayAI), rawSampClass);
                    errMessage = ['All ' obj(i).type ' channels in a given Task must have the same raw data type. Task deleted.'];
                    errorCond = true;
                    break;
                end
            end
            
            if errorCond
                delete(obj(1).task); %All created objects presumed (known) to belong to same class
                error(errMessage);
            end
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

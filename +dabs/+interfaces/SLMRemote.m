classdef SLMRemote < handle    
    properties (SetAccess = protected)
        hClient;
        hDevice;
        queueAvailable;
        description;
        maxRefreshRate;       % [Hz], numeric
        pixelResolutionXY;    % [1x2 numeric] pixel resolution of SLM
        pixelPitchXY;         % [1x2 numeric] distance from pixel center to pixel center in meters
        pixelPitchXY_um;      % [1x2 numeric] distance from pixel center to pixel center in meters
        interPixelGapXY;      % [1x2 numeric] pixel spacing in x and y
        interPixelGapXY_um;   % [1x2 numeric] pixel spacing in x and y
        pixelBitDepth;        % numeric, one of {8,16,32,64} corresponds to uint8, uint16, uint32, uint64 data type
        computeTransposedPhaseMask;
        pixelDataType;
        queueStarted = false;
    end
    
    properties (Dependent)
        
    end
    
    methods
        function obj = SLMRemote(hSLM)
            assert(isa(hSLM,'most.network.matlabRemote.ServerVar'));
            obj.hDevice = hSLM;
            obj.hClient = hSLM.hClient__;
            
            % cache constant properties
            retrieveProperty('queueAvailable');
            retrieveProperty('description');
            retrieveProperty('maxRefreshRate');
            retrieveProperty('pixelResolutionXY');
            retrieveProperty('pixelPitchXY');
            retrieveProperty('pixelPitchXY_um');
            retrieveProperty('interPixelGapXY');
            retrieveProperty('interPixelGapXY_um');
            retrieveProperty('pixelBitDepth');
            retrieveProperty('computeTransposedPhaseMask');
            retrieveProperty('pixelDataType');            
            
            function retrieveProperty(propertyName)
                var = obj.hDevice.(propertyName);
                obj.(propertyName) = var.download();
            end
        end
        
        function delete(obj)
            obj.hClient.feval('delete',obj.hDevice);
            obj.hDevice = [];
        end
    end
    
    %% User methods
    methods        
        function writeBitmap(obj,varargin)
            obj.hDevice.writeBitmap(varargin{:});
        end
        
        function writeQueue(obj,varargin)
            obj.hDevice.writeQueue(varargin{:});
        end
        
        function startQueue(obj)
            obj.hDevice.startQueue();
            obj.queueStarted = true;
        end
        
        function abortQueue(obj)
            obj.hDevice.abortQueue();
            obj.queueStarted = false;
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

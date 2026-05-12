classdef ParallelInterpolant
    %PARALLELINTERPOLANT MATLAB versions R2020b and older do not allow gridded
    %interpolants that are single-to-multiple dimensions. This class is a
    %wrapper around griddedInterpolant that allows for this. Only linear
    %interpolation is supported with this class.
    
    properties
        Interpolant(1,1) griddedInterpolant;
    end
    
    methods
        function obj = ParallelInterpolant(x,v)
            if ~verLessThan('matlab', '9.10')
                warning(['This class is intended as compatibility for MATLAB versions older than '...
                'R2021a. Please use `griddedInterpolant` for all MATLAB versions R2021a and newer.']);
            end

            validateattributes(x, {'numeric'}, {'vector'}, 'ParallelInterpolant constructor', 'x');
            if length(x) == numel(v)
                warning(['x and v share # of samples. Just use regular griddedInterpolants '...
                    'instead of this compatibility class.']);
            end
            
            ndSamples = cell(1, ndims(v));
            ndSamples{1} = x;
            for iD = 2:ndims(v)
                ndSamples{iD} = 1:size(v,iD);
            end
            obj.Interpolant = griddedInterpolant(ndSamples, v);
        end
        
        function varargout = subsref(obj, S)
            CurrentSubRef = S(1);
            if ~isscalar(obj) || ~strcmp(CurrentSubRef.type, '()')
                [varargout{1:nargout}] = builtin('subsref', obj, S);
                return;
            end
            
            assert(isscalar(CurrentSubRef.subs), ['ParallelInterpolant does not support multiple '...
                'dimension subsref.']);
            samples = CurrentSubRef.subs{1};
            validateattributes(samples, {'numeric'}, {'vector'}, ...
                'ParallelInterpolant indexing', 'indices');
            
            values = obj.Interpolant.Values;
            queryPoints = cell(1, ndims(values));
            queryPoints{1} = samples;
            for iD = 2:ndims(values)
                queryPoints{iD} = 1:size(values,iD);
            end
            [varargout{1:nargout}] = obj.Interpolant(queryPoints);
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

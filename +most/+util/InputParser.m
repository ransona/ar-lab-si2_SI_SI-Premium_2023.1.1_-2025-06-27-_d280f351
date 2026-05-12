classdef InputParser < inputParser
% Cause I like to live on the edge.

    properties (Constant)
        fDummyVal = '___ThIs will never be duplicated';
    end

    properties (Hidden)
        fRequiredParams = cell(0,1);
    end
    
    methods
        
        function obj = InputParser
            obj = obj@inputParser;
            obj.KeepUnmatched = true;            
        end
        
    end
    
    methods
        
        function addRequiredParam(obj,pname,validator)
            if nargin < 3
                validator = @(x)true;
            end
            obj.addParamValue(pname,obj.fDummyVal,validator);
            obj.fRequiredParams{end+1,1} = pname;
        end
        
        function parse(obj,varargin)
            parse@inputParser(obj,varargin{:});
            s = obj.Results;
            
            for c = 1:numel(obj.fRequiredParams);
                fld = obj.fRequiredParams{c};
                assert(isfield(s,fld));
                if isequal(s.(fld),obj.fDummyVal);
                    error('Dabs:InputParser','Required property ''%s'' unspecified.',fld);
                end
            end
        end
                
        function createCopy(obj) %#ok<MANU>
            assert(false);
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

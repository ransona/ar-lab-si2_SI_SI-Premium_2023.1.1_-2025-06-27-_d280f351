classdef ParallelMotionEstimatorResult < scanimage.interfaces.IMotionEstimatorResult    
    properties (SetAccess = private)
        futureFinished = false;
        fevalFuture
    end
    
    methods
        function obj = ParallelMotionEstimatorResult(hMotionEstimator,roiData,fevalFuture)
            obj = obj@scanimage.interfaces.IMotionEstimatorResult(hMotionEstimator,roiData);
            obj.fevalFuture = fevalFuture;
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.fevalFuture);
        end
        
        function tf = wait(obj,timeout_s)
            tf = obj.futureFinished || ~isempty(regexpi(obj.fevalFuture.State,'^finished.*','once'));
            if ~tf && timeout_s>0
                % performance fix: only call wait method on fevalFuture if necessary
                tf = obj.fevalFuture.wait('finished',timeout_s);
            end
        end
        
        function dr=fetch(obj)
            if ~obj.futureFinished
                obj.wait(Inf);
                [obj.dr,obj.confidence,obj.correlation] = obj.fevalFuture.fetchOutputs;
            end
            dr = obj.dr;
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

classdef clearAllDetector < handle
    % this class periodically checks if the 'clear all' command was
    % executed. if it detects that clear all was executed, it destructs
    % iteself and calls 'callback'
    
    properties (SetAccess = immutable)
        callback = [];
        expectedValue;
    end
    
    properties (SetAccess = private, GetAccess = private)
        hTimer;
    end
    
    methods
        function obj = clearAllDetector(callback)
            validateattributes(callback,{'function_handle'},{'scalar'});
            obj.callback = callback;
            
            obj.expectedValue = checkStore();
            
            obj.hTimer = timer(...
                 'Name','clearAllDetector timer'...
                ,'Period',1 ...
                ,'TimerFcn',@(varargin)obj.performCheck ...
                ,'ExecutionMode','fixedSpacing' ...
                ,'ErrorFcn',@(varargin)false);
            
            start(obj.hTimer);
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.hTimer);
        end
        
        function performCheck(obj)            
            clearDetected = obj.expectedValue ~= checkStore();
            
            if clearDetected
                callback_ = obj.callback;
                obj.delete();
                
                if ~isempty(callback_)
                    callback_();
                end
            end
        end
    end
end

function val = checkStore()
    persistent store
    
    if isempty(store)
        store = rand();
    end
        
    val = store;
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

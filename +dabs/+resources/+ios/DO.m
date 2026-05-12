classdef DO < dabs.resources.ios.D
    properties (Dependent, SetAccess=private, GetAccess=private)
        hTaskOut;
    end
    
    properties (Dependent, SetAccess=private)
        outputSource;
        maxSampleRate_Hz;
    end
    
    properties (SetAccess=private, GetAccess=private)
        hTaskOut_;
    end
    
    methods
        function obj = DO(name,hDAQ)
            obj@dabs.resources.ios.D(name,hDAQ);
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.hTaskOut_);
        end
    end
    
    methods
        function setValue(obj,val)
            if isa(obj.hDAQ,'dabs.resources.daqs.NIFlexRIOAdapterModule')
                most.ErrorHandler.error('Setting output on FlexRIO Adapter module is unsupported.');
            end
            
            if strcmpi(val,'z')
                obj.tristate();
            else
                validateattributes(val,{'logical','numeric'},{'scalar','binary'});
                val = logical(val);
                obj.hTaskOut.setChannelOutputValues(val);
                obj.lastKnownValue = val;
            end
        end
        
        function tristate(obj)
            if isa(obj.hDAQ,'dabs.resources.daqs.NIFlexRIOAdapterModule')
                return
            end
            
            obj.hTaskOut.tristateOutputs();
        end
    end
    
    methods
        function val = get.outputSource(obj)
            val = [];
            
            if isa(obj.hDAQ,'dabs.resources.daqs.vDAQ') && most.idioms.isValidObj(obj.hDAQ.hFpga)
                val = obj.hDAQ.hFpga.getDioOutput(obj.name);
            end
        end
        
        function val = get.hTaskOut(obj)
            if isempty(obj.hTaskOut_)
                taskName = sprintf('Ouput Task %s %s',obj.hDAQ.name,regexprep(obj.channelName,'/',' '));
                hTaskOut__ = dabs.vidrio.ddi.DoTask(obj.hDAQ,taskName);
                hTaskOut__.addChannel(obj);
                obj.hTaskOut_ = hTaskOut__;
            end
            
            val = obj.hTaskOut_;
        end

        function val = get.maxSampleRate_Hz(obj)
            val = obj.hTaskOut.maxSampleRate;
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

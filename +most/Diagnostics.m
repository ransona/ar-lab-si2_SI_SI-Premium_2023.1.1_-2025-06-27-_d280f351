classdef Diagnostics < handle
    %Diagnostics Control diagnostic output at the command line and in log files.
    %
    %   The Diagnostics class can be used to provide control over the vebosity of
    %   diagnostic output at the command line and in log files for most classes and
    %   derived applications.  Functions and class methods can query the LogLevel to
    %   determine how much information to display, if any.  Applications can also
    %   set and change the LogLevel at any time.
    %
    %   
    %   See also most.util.LogLevel.
    
    properties
        LogLevel = most.util.LogLevel.Info; %Specifies the verbosity of command line and log file output.
    end
    
    methods (Access = private)
        function self = Diagnostics()
            %Diagnostics Default class constructor.
            %
            %   Diagnostics is a singleton class per MATLAB instance and therefore has a
            %   private constructor.
        end
    end
    
    methods
        function set.LogLevel(self, value)
            validateattributes(value, {'numeric', 'logical', 'most.util.LogLevel'}, {'scalar'});
            
            if ~isa(value, 'most.util.LogLevel')
                value = most.util.LogLevel(value);
            end
            
            self.LogLevel = value;
        end
    end
    
    methods (Static = true)
        function out = shareddiagnostics()
            %shareddiagnostics Return Diagnostics class singleton.
            
            persistent sharedInstance;
            if isempty(sharedInstance)
                sharedInstance = most.Diagnostics();
            end
            out = sharedInstance;
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

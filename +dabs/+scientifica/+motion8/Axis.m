classdef Axis
    %AXIS enumeration of controllable Motion8 Access per Device.

    enumeration
        Approach;
        Condenser;
        Objective;
        X;
        Y;
        Z;
    end

    methods (Static)
        function obj = fromMotion8Axis(A)
            switch A
                case Scientifica.Axis.A
                    obj = dabs.scientifica.motion8.Axis.Approach;
                case Scientifica.Axis.C
                    obj = dabs.scientifica.motion8.Axis.Condenser;
                case Scientifica.Axis.None
                    error('"None" Axis is not supported.');
                case Scientifica.Axis.O
                    obj = dabs.scientifica.motion8.Axis.Objective;
                case Scientifica.Axis.X
                    obj = dabs.scientifica.motion8.Axis.X;
                case Scientifica.Axis.Y
                    obj = dabs.scientifica.motion8.Axis.Y;
                case Scientifica.Axis.Z
                    obj = dabs.scientifica.motion8.Axis.Z;
                otherwise
                    error('unknown or unexpected Motion8.Axis enumeration');
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

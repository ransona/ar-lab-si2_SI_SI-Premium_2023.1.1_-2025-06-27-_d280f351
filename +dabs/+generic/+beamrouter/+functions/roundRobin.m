function pockelsPowerFractions = roundRobin(beamPowerFractions,hBeams,hBeamRouter)
% Round Robin cycles through the paired pockels cells 
% by frame for planar or slow Z acquisition or
% by volume for fastZ stack acquisition.
% e.g.
% Frame 1: Pockels cell 1 is modulated at power selected in beam controls GUI, others held at 0%
% Frame 2: Pockels cell 2 is modulated at power selected in beam controls GUI, other held at 0%
% Frame 3: Pockels cell 3 is modulated at power selected in beam controls GUI,
% others held at 0%
%
%
% beamFractions is an Nx2 matrix
%     - Column 1 is beam 1 powerfraction
%     - Column 2 is beam 2 powerfraction
%     - power fractions are values between 0 and 1

if size(beamPowerFractions,1) == 1
    pockelsPowerFractions = beamPowerFractions;
else
    samples = length(beamPowerFractions);
    numBeams = size(beamPowerFractions,2);
    
    pockelsPowerFractions = zeros(samples*numBeams,numBeams);
    for beam = 1:size(beamPowerFractions,2)
        pockelsPowerFractions(:,beam) = [zeros((beam-1)*samples,1);...
            beamPowerFractions(:,beam);...
            zeros((numBeams-beam)*samples,1)];
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

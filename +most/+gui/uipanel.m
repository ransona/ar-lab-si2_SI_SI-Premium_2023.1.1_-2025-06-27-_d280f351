function h = uipanel(varargin)
    ip = most.util.InputParser;
    ip.addOptional('WidthLimits',[]);
    ip.addOptional('HeightLimits',[]);
    ip.addOptional('SizeLimits',[]);
    ip.parse(varargin{:});
    [~,otherPVArgs] = most.util.filterPVArgs(varargin,{'WidthLimits' 'HeightLimits' 'SizeLimits'});
    
    h = uipanel(otherPVArgs{:});
    
    if ~isempty(ip.Results.WidthLimits)
        lms = [ip.Results.WidthLimits ip.Results.WidthLimits(1)];
        set(h, 'WidthLimits', lms(1:2));
    end
    if ~isempty(ip.Results.HeightLimits)
        lms = [ip.Results.HeightLimits ip.Results.HeightLimits(1)];
        set(h, 'HeightLimits', lms(1:2));
    end
    if ~isempty(ip.Results.SizeLimits)
        set(h, 'WidthLimits', ip.Results.SizeLimits(1)*ones(1,2));
        set(h, 'HeightLimits', ip.Results.SizeLimits(2)*ones(1,2));
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

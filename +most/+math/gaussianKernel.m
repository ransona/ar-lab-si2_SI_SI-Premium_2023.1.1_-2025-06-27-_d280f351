function kernel = gaussianKernel(kernelSize,sigma)
if nargin < 1 || isempty(kernelSize)
    kernelSize = [3 3];
end

if nargin < 3 || isempty(sigma)
    sigma = kernelSize / 2;
end

if isscalar(sigma)
    sigma = repmat(sigma,1,numel(kernelSize));
end

validateattributes(sigma,{'numeric'},{'positive','row'});
validateattributes(kernelSize,{'numeric'},{'positive','row','integer'});

dims = numel(kernelSize);

vecs_squared = cell(1,dims);
for idx = 1:dims
    simSize = kernelSize(idx);
    vecs_squared{idx} = linspace(-simSize/2,simSize/2,simSize).^2;
end

grids_squared = cell(1,dims);
[grids_squared{1:end}] = ndgrid(vecs_squared{:});

sigma_squared_times_two = 2 * sigma.^2;

kernel = arrayfun(@(varargin)exp(-sum([varargin{:}] ./ sigma_squared_times_two)),grids_squared{:});
kernel = kernel ./ sum(kernel(:)); % scale to maintain unity

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

function [tf,gpu] = gpuComputingAvailable()
persistent tf_cache gpu_cache

if ~isempty(tf_cache)
    tf = tf_cache;
    gpu = gpu_cache;
    return
end

tf = false;
gpu = [];

toolboxinstalled = most.util.parallelComputingToolboxAvailable();

if toolboxinstalled && gpuDeviceCount > 0
    try
        startTic = tic();
        gpu = gpuDevice();
        tf = true;
        duration = toc(startTic);
        if duration > 5
            url = 'https://www.mathworks.com/matlabcentral/answers/309235-can-i-use-my-nvidia-pascal-architecture-gpu-with-matlab-for-gpu-computing';
            disp(['Note: The initialization of the GPU device seems is unusually slow. Please visit this <a href = "matlab:web(''' url ''',''-browser'')">Mathworks Forum thread</a> for a solution.';]);
        end
    catch ME
        most.idioms.warn('Initializing GPU failed');
        most.ErrorHandler.logAndReportError(ME);
    end
end

tf_cache = tf;
gpu_cache = gpu;

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

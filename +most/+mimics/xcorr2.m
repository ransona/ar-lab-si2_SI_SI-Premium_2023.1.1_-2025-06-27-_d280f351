function result = xcorr2(A, B)
%   IMPORTANT: Currently only real inputs are supported
%
    result = xcorr2_matlab(single(A),single(B));
end

function res = xcorr2_matlab(A,B)
%   NOTE: Removing conj, since its unnecessary for our current use-case
    [M, N] = size(A);
    [P, Q] = size(B);
    %conjB = conj(B);
    resultXElements = M + N - 1;
    resultYElements = M + N - 1;
    res = zeros(resultXElements, resultYElements);
    for l = -(Q - 1):(N - 1)
        for k = -(P - 1):(M - 1)
            val = 0;
            for m = 1:M
                for n = 1:N
                    indexX = m - k;
                    indexY = n - l;
                    if (indexX > 0) && (indexY > 0) && (indexX <= P) && (indexY <= Q)
                        %val = val + A(m,n) * conjB(indexX, indexY);
                        val = val + A(m,n) * B(indexX, indexY);
                    end
                end
            end
            res(P + k,Q + l) = val;
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

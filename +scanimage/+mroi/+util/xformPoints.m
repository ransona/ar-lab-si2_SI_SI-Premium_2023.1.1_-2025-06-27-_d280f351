function pts = xformPoints(pts,T,inverse)
    persistent oldMatlabVersion    

    if nargin<3 || isempty(inverse)
        inverse = false;
    end

    if isempty(oldMatlabVersion)
        % implicit expansion for element wise operations was introduced in Matlab 2016b
        oldMatlabVersion = verLessThan('matlab','9.1');
    end

    identity = eye(size(T),class(pts));
    
    if isequal(T,identity)
        % special case: identity matrix
        return
    end
    
    if inverse
        T = inv(double(T));
    end
    
    T = cast(T,class(pts));
    
    isPerspective = ~isequal(T(end,:),identity(end,:));
    
    T = T';
    T_ScaleAndRotation = T(1:end-1,1:end-1);
    T_Translation      = T(end,1:end-1);
    
    if isPerspective
        T_Perspective = T(:,end);
        w = pts * T_Perspective(1:end-1) + T_Perspective(end);
    end
    
    pts = pts * T_ScaleAndRotation;
    
    if oldMatlabVersion
        pts = bsxfun(@plus,pts,T_Translation);
    else
        pts = pts + T_Translation;
    end
    
    if isPerspective
        if oldMatlabVersion
            pts = bsxfun(@rdivide,pts,w);
        else
            pts = pts ./ w;
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

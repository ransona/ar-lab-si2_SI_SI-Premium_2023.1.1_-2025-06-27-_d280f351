function y = nansum(x,dim)
% FORMAT: Y = NANSUM(X,DIM)
% 
%    Sum of values ignoring NaNs
%
%    This function enhances the functionality of NANSUM as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANSUM(X,DIM) calculates the mean along any dimension of the N-D array
%    X ignoring NaNs.  If DIM is omitted NANSUM averages along the first
%    non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANSTD, NANMEDIAN, NANMIN, and
%    NANMAX which are all part of the NaN-suite.
%
%    See also SUM

% -------------------------------------------------------------------------
%    author:      Jan Gläscher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.2 $ $Date: 2005/06/13 12:14:38 $

if isempty(x)
	y = [];
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1;
	end
end

% Replace NaNs with zeros.
nans = isnan(x);
x(isnan(x)) = 0; 

% Protect against all NaNs in one dimension
count = size(x,dim) - sum(nans,dim);
i = find(count==0);

y = sum(x,dim);
y(i) = NaN;



% $Id: nansum.m,v 1.2 2005/06/13 12:14:38 glaescher Exp glaescher $

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

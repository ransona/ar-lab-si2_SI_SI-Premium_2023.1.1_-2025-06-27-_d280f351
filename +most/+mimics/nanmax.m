function [y,idx] = nanmax(a,dim,b)
% FORMAT: [Y,IDX] = NANMAX(A,DIM,[B])
% 
%    Maximum ignoring NaNs
%
%    This function enhances the functionality of NANMAX as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).
%
%    If fact NANMAX simply rearranges the input arguments to MAX because
%    MAX already ignores NaNs.
%
%    NANMAX(A,DIM) calculates the maximum of A along the dimension DIM of
%    the N-D array X. If DIM is omitted NANMAX calculates the maximum along
%    the first non-singleton dimension of X.
%
%    NANMAX(A,[],B) returns the minimum of the N-D arrays A and B.  A and
%    B must be of the same size.
%
%    Comparing two matrices in a particular dimension is not supported,
%    e.g. NANMAX(A,2,B) is invalid.
%    
%    [Y,IDX] = NANMAX(X,DIM) returns the index to the maximum in IDX.
%    
%    Similar replacements exist for NANMIN, NANMEAN, NANSTD, NANMEDIAN and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MAX

% -------------------------------------------------------------------------
%    author:      Jan Gläscher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:11 $

if nargin < 1
	error('Requires at least one input argument')
end

if nargin == 1
	if nargout > 1
		[y,idx] = max(a);
	else
		y = max(a);
	end
elseif nargin == 2
	if nargout > 1
		[y,idx] = max(a,[],dim);
	else
		y = max(a,[],dim);
	end
elseif nargin == 3
	if ~isempty(dim)
		error('Comparing two matrices along a particular dimension is not supported')
	else
		if nargout > 1
			[y,idx] = max(a,b);
		else
			y = max(a,b);
		end
	end
elseif nargin > 3
	error('Too many input arguments.')
end

% $Id: nanmax.m,v 1.1 2004/07/15 22:42:11 glaescher Exp glaescher $

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

function tf = fuzzyEquals(A, B, varargin)
    % FUZZYEQUALS  floating point fuzzy comparator.
    %   tf = FUZZYEQUALS(A,B) returns == for A and B but with floating
    %   point fuzzy equality with a default tolerance of realmin(class(A))
    %   
    %   tf = FUZZYEQUALS(A,B,'UnitsInLastPlace',T) returns if A == B with
    %   provided ULP (see https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/)
    %   for more detail.

    assert((isa(A, 'double') || isa(A, 'single')) && (isa(B, 'double') || isa(B, 'single')), ...
        'Most:FloatingPoint:InvalidArgumentTypes', ...
        'A and B must be floating point values.');
    if ~isscalar(A) && ~isscalar(B)
        assert(ndims(A) == ndims(B) && all(size(A) == size(B)), ...
            'Most:FloatingPoint:InvalidArgumentShapes', ...
            'A and/or B must be scalar or A and B dimensions must match.');
    end
    p = inputParser;
    p.addParameter('UnitsInLastPlace', 1, ...
        @(x)validateattributes(x, {'numeric'}, {'scalar'}, 'fuzzyEquals', 'ULP'));
    p.parse(varargin{:});

    ulp = p.Results.UnitsInLastPlace;
    differences = abs(A - B);
    tf = (A == B) | differences < realmin(class(A)) | differences <= max(eps(A), eps(B)) * ulp;
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

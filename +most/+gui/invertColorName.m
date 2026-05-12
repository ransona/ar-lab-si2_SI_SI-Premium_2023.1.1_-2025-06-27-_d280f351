function invertedName = invertColorName(colorName)
    %invertColorName Inverts a color by name.
    validateattributes(colorName, {'char'}, {'scalartext'}, ...
        'most.gui.invertColorName', 'colorName');
    switch lower(colorName)
        case 'red'
            invertedName = 'cyan';
        case 'r'
            invertedName = 'c';
        case 'green'
            invertedName = 'magenta';
        case 'g'
            invertedName = 'm';
        case 'blue'
            invertedName = 'yellow';
        case 'b'
            invertedName = 'y';
        case 'yellow'
            invertedName = 'blue';
        case 'y'
            invertedName = 'b';
        case 'magenta'
            invertedName = 'green';
        case 'm'
            invertedName = 'g';
        case 'cyan'
            invertedName = 'red';
        case 'c'
            invertedName = 'r';
        case 'white'
            invertedName = 'black';
        case 'w'
            invertedName = 'k';
        case 'black'
            invertedName = 'white';
        case 'k'
            invertedName = 'w';
        case 'none'
            % the opposite of empty should just be empty. 
            % Set any color for a proper inversion.
            invertedName = 'none'; 
        otherwise
            error('Most:Gui:InvertColorName:InvalidColorName', ...
                'Color name `%s` is an invalid or unsupported color name', colorName);
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

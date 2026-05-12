function out = className(className,type)
%className - returns the name / related paths of a class
%
% SYNTAX
%     s = className(className)
%     s = className(className,type)
%     
% ARGUMENTS
%     className: object or string specifying a class
%     type:      <optional> one of {'classNameShort','classPrivatePath','packagePrivatePath','classPath'}
%                   if omitted function defaults to 'classNameShort' 
%
% RETURNS
%     out - a string containing the appropriate class name / path

if nargin < 2 || isempty(type)
    type = 'classNameShort';
end

if isobject(className)
    className = class(className);
end

switch type
    case 'classNameShort'
        classNameParts = textscan(className,'%s','Delimiter','.');
        out = classNameParts{1}{end};
    case 'classPrivatePath'
        out = fullfile(fileparts(which(className)),'private');
    case 'packagePrivatePath'
        mc = meta.class.fromName(className);
        containingpack = mc.ContainingPackage;
        if isempty(containingpack)
            out = [];
        else
            p = fileparts(fileparts(which(className)));
            out = fullfile(p,'private');
        end
    case 'classPath'
        out = fileparts(which(className));
    otherwise
        error('most.util.className: Not a valid option: %s',type);
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

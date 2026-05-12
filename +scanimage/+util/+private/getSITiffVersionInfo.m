function [verInfo] = getSITiffVersionInfo(fileHeader)
%   Analize a tiff-header frame-string to determine the scanimage version it came from
%   The tags provided by the ScanImage header are insufficient to keep track of released 
%   versions of ScanImage, hence we'll provide a structure called verInfo to help us simplify
%   version detection

    verInfo = struct();
    verInfo.infoFound = false;

    %TODO: Make sure this works for the case where this property doesn't exist?
    try
        verInfo.SI_MAJOR = fileHeader.SI.VERSION_MAJOR;
        verInfo.SI_MINOR = fileHeader.SI.VERSION_MINOR;
        verInfo.TIFF_FORMAT_VERSION = fileHeader.SI.TIFF_FORMAT_VERSION;
        verInfo.infoFound = true;
    catch
        most.idioms.dispError('Cannot find SI and/or Tiff version properties in Tiff header.\n');
        return;
    end

    %% Determine if the scanner is linear or resonant
    try
        verInfo.ImagingSystemType = fileHeader.SI.hScan2D.scannerType;
    catch
        verInfo.ImagingSystemType = fileHeader.SI.imagingSystem;
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

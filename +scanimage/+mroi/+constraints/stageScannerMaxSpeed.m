function stageScannerMaxSpeed(roigroup,~,~)
    persistent stageScanner hSI
    
    if isempty(hSI) || ~most.idioms.isValidObj(hSI)
        rs = dabs.resources.ResourceStore();
        hSI = rs.filterByName('ScanImage');
    end
    
    if isempty(stageScanner) || ~most.idioms.isValidObj(stageScanner)       
        hMotors = hSI.hMotors;
        stageScanner = hMotors.hMotorXYZ{2};
    end
    
    hScan2D = hSI.hScan2D;

    
    for roi=roigroup.rois
        for s=roi.scanfields
            if ~isa(s,'scanimage.mroi.scanfield.ImagingField')
                return
            end
            if isprop(s,'pixelResolution')
                
                height = s.sizeXY(2) * hSI.objectiveResolution;
                lineRate = hScan2D.scannerFrequency * 2.^ hScan2D.bidirectional;
                minNumLines = (1.1 * height) / stageScanner.streamMaxVelocity_umPerS * lineRate;
                
                if s.pixelResolutionXY(2) < minNumLines
                    s.pixelResolutionXY(2) = ceil(minNumLines/2)*2;
                end
            end
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

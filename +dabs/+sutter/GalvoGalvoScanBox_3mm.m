classdef GalvoGalvoScanBox_3mm < dabs.resources.Device & dabs.resources.configuration.HasConfigPage
    properties (SetAccess=protected,Hidden)
        ConfigPageClass = 'dabs.resources.configuration.resourcePages.BlankPage';
    end
    
    methods (Static)
        function names = getDescriptiveNames()
            names = {'Scanner\Sutter Galvo-Galvo Scan Box (3mm mirror aperture)' 'Sutter Instrument\Sutter Galvo-Galvo Scan Box (3mm mirror aperture)'};
        end
    end
    
    %% LIFECYCLE
    methods
        function obj = GalvoGalvoScanBox_3mm(name)
            obj@dabs.resources.Device(name);
            obj.reinit();
            obj.delete();
        end
    end
    
    methods
        function reinit(obj)
            makeGalvoX()
            makeGalvoY();
            
            %%% Nested functions
            function makeGalvoX()
                try
                    galvoName = [obj.name ' X-Galvo'];
                    if isempty(obj.hResourceStore.filterByName(galvoName))
                        hGalvo = dabs.generic.GalvoPureAnalog(galvoName);
                        if hGalvo.mdfHeadingCreated
                            % set defaults
                            hGalvo.voltsPerDistance = 10/30;
                            hGalvo.travelRange = [-30 30];
                            hGalvo.parkPosition = -29;
                            hGalvo.saveMdf();
                        end
                    end
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
            
            function makeGalvoY()
                try
                    galvoName = [obj.name ' Y-Galvo'];
                    if isempty(obj.hResourceStore.filterByName(galvoName))
                        hGalvo = dabs.generic.GalvoPureAnalog(galvoName);
                        if hGalvo.mdfHeadingCreated
                            % set defaults
                            hGalvo.voltsPerDistance = 10/30;
                            hGalvo.travelRange = [-30 30];
                            hGalvo.parkPosition = -29;
                            hGalvo.saveMdf();
                        end
                    end
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
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

classdef ThorPrelude < dabs.resources.configuration.ResourcePage
    properties
        ComDropdown;
    end
    
    %% impl ResourcePage
    methods
        function makePanel(obj, hParent)
            grid = uigridcontainer('v0', Parent = hParent);
            set(grid, GridSize = [1, 2], HorizontalWeight = [1, 3]);
            
            uicontrol( ...
                Parent = grid ...
                , Style = 'text', String = 'COM Port:' ...
                , FontWeight = 'bold', HorizontalAlignment = 'right');
            obj.ComDropdown = uicontrol( ...
                Parent = grid ...
                , Style = 'popupmenu' ...
                , String = " ");
        end
        
        function redraw(obj)
            model = obj.hResource;
            prevcom = model.ComPort;
            allports = serialportlist("all");
            isRealPort = any(allports == prevcom);
            ports = serialportlist("available");
            if isRealPort
                set(obj.ComDropdown ...
                    , String = [" ", prevcom, ports] ...
                    , Value = 2 ...
                    , BackgroundColor = [0.94, 0.94, 0.94]);
            else
                set(obj.ComDropdown ...
                    , String = [" ", ports] ...
                    , Value = 1 ...
                    , BackgroundColor = most.constants.Colors.lightRed);
            end
        end
        
        function apply(obj)
            prelude = obj.hResource;
            dropdown = get(obj.ComDropdown, {'String', 'Value'});
            prelude.ComPort = strtrim(dropdown{1}{dropdown{2}});
            prelude.reinit();
            prelude.saveMdf();
        end
        
        function remove(obj)
            obj.hResource.deleteAndRemoveMdfHeading();
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

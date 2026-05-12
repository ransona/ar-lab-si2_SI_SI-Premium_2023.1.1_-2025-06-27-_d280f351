classdef PhaseformServerListenerPage < dabs.resources.configuration.ResourcePage
    properties
        ServerPortEditBox;
        ServerListeningStatusText;
    end

    methods
        function obj = PhaseformServerListenerPage(Model, GuiParent)
            obj@dabs.resources.configuration.ResourcePage(Model, GuiParent);
        end
    end

    %% dabs.resources.configuration.ResourcePage
    methods
        function makePanel(obj, GuiParent)
            downflow = uiflowcontainer('v0', Parent = GuiParent, FlowDirection = 'TopDown');
            rowHeightRange = [25, 25];
            rowflow = uiflowcontainer('v0' ...
                , Parent = downflow ...
                , Units = 'pixels' ...
                , FlowDirection = 'LeftToRight');
            set(rowflow, HeightLimits = rowHeightRange);
            uicontrol(rowflow ...
                , Units = 'pixels' ...
                , Style = 'text' ...
                , String = 'Server port number:' ...
                , HorizontalAlignment = 'right' ...
                , FontWeight = 'bold');
            obj.ServerPortEditBox = uicontrol(rowflow ...
                , Units = 'pixels' ...
                , Style = 'edit');
            rowflow = uiflowcontainer('v0' ...
                , Parent = downflow ...
                , Units = 'pixels' ...
                , FlowDirection = 'LeftToRight');
            set(rowflow, HeightLimits = rowHeightRange);
            obj.ServerListeningStatusText = uicontrol(rowflow ...
                , Style = 'text' ...
                , String = 'uninitialized' ...
                , BackgroundColor = 'yellow');
        end

        function redraw(obj)
            obj.ServerPortEditBox.String = num2str(obj.hResource.Port);
            if most.idioms.isValidObj(obj.hResource.Server)
                set(obj.ServerListeningStatusText ...
                    , String = 'Server is listening' ...
                    , BackgroundColor = most.constants.Colors.lightGreen);
            else
                set(obj.ServerListeningStatusText ...
                    , String = 'Server configuration is invalid. Check for errors.' ...
                    , BackgroundColor = most.constants.Colors.lightRed);
            end
        end

        function apply(obj)
            obj.hResource.Port = str2num(obj.ServerPortEditBox.String); %#ok<ST2NM>
            obj.hResource.reinit();
            if isempty(obj.hResource.errorMsg)
                obj.hResource.saveMdf();
            end
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

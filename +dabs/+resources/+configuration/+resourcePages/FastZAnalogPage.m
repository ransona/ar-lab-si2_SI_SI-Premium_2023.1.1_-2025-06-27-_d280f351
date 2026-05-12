classdef FastZAnalogPage < dabs.resources.configuration.ResourcePage
    properties
        txhCOM
        pmhCOM
        pmhAOControl
        pmhAIFeedback
        etVoltsPerDistance
        etDistanceVoltsOffset
        etTravelRange1
        etTravelRange2
        etParkPosition
        pmhFrameClockIn
        pmPositionInterpolationAlgorithm
        pbReadTravelRange        
    end
    
    methods
        function obj = FastZAnalogPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            hTabGroup = uitabgroup('Parent',hParent);
            hTab = uitab('Parent',hTabGroup,'Title','Basic');
			    obj.txhCOM = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [21 31 120 20],'Tag','txhCOM','String','Serial port','HorizontalAlignment','right');
                obj.pmhCOM  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 26 120 20],'Tag','pmhCOM');
			
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 55 120 20],'Tag','txhAOControl','String','Control Channel','HorizontalAlignment','right');
                obj.pmhAOControl  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 52 120 20],'Tag','pmhAOControl');

                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 78 120 20],'Tag','txVoltsPerDistance','String','Volts per micron','HorizontalAlignment','right');
                obj.etVoltsPerDistance = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [150 77 120 20],'Tag','etVoltsPerDistance');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 103 120 20],'Tag','txDistanceVoltsOffset','String','Volts Offset','HorizontalAlignment','right');
                obj.etDistanceVoltsOffset = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [150 101 120 20],'Tag','etDistanceVoltsOffset');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 127 120 20],'Tag','txTravelRange1','String','Lower travel range [um]','HorizontalAlignment','right');
                obj.etTravelRange1 = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [150 125 120 20],'Tag','etTravelRange1');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 151 120 20],'Tag','txTravelRange2','String','Upper Travel range [um]','HorizontalAlignment','right');
                obj.etTravelRange2 = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [150 149 120 20],'Tag','etTravelRange2');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 174 120 20],'Tag','txParkPosition','String','Park position [um]','HorizontalAlignment','right');
                toolTipString = sprintf(['Position where the actuator should be when not acquiring.\n\nIt is highly recommended to leave this at zero microns and\n set travel range and voltage offset such that\n' ...
                    '0 um is the middle of the actuator''s range']);
                obj.etParkPosition = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [150 173 120 20],'Tag','etParkPosition','tooltip',toolTipString);
                
                obj.pbReadTravelRange = most.gui.uicontrol('Parent',hTab,'Style','pushbutton','String', 'Read From Device', 'RelPosition', [150 197.333333333333 123 22],'Tag','pbReadTravelRange', 'Callback', @obj.readTravelRange);

                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 229.333333333333 140 20],'Tag','txhAIFeedback','String','Feedback Channel (optional)','HorizontalAlignment','right');
                obj.pmhAIFeedback = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 227.333333333333 120 20],'Tag','pmhAIFeedback');
            
            hTab = uitab('Parent',hTabGroup,'Title','Advanced');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 30.3333333333333 140 20],'Tag','txhFrameClockIn','String','Frame clock input','HorizontalAlignment','right');
                obj.pmhFrameClockIn = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 27.3333333333333 120 20],'Tag','pmhFrameClockIn');

                ttStr = sprintf('Choose an algorithm for shaping the trajectory of the volume flyback of fastZ stacks.');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 60 140 20],'Tag','txPositionInterpolationAlgorithm','String','Flyback Algorthm','HorizontalAlignment','right','tooltip',ttStr);
                obj.pmPositionInterpolationAlgorithm = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [150 57 120 20],'Tag','pmPositionInterpolationAlgorithm');
        end
        
        function redraw(obj)
		    % Basic Tab
            hasCOM = isprop(obj.hResource,'hCOM');
            hCOMs = obj.hResourceStore.filterByClass(?dabs.resources.SerialPort);
            obj.pmhCOM.String = [{''},hCOMs];
            obj.txhCOM.Visible = hasCOM;
            obj.pmhCOM.Visible = hasCOM;
            if hasCOM
                obj.pmhCOM.pmValue = obj.hResource.hCOM;
            end
            
            hAOs = obj.hResourceStore.filterByClass(?dabs.resources.ios.AO);
            obj.pmhAOControl.String = [{''}, hAOs];
            obj.pmhAOControl.pmValue = obj.hResource.hAOControl;
            
            hAIs = obj.hResourceStore.filterByClass(?dabs.resources.ios.AI);
            obj.pmhAIFeedback.String = [{''}, hAIs];
            obj.pmhAIFeedback.pmValue = obj.hResource.hAIFeedback;
            
            obj.etVoltsPerDistance.String = num2str(obj.hResource.voltsPerDistance);
            obj.etDistanceVoltsOffset.String = num2str(obj.hResource.distanceVoltsOffset);
            obj.etTravelRange1.String = num2str(obj.hResource.travelRange(1));
            obj.etTravelRange2.String = num2str(obj.hResource.travelRange(2));
            obj.etParkPosition.String = num2str(obj.hResource.parkPosition);
            
            obj.pbReadTravelRange.Visible = ismethod(obj.hResource,'readDeviceTravelRange');
            
            % Advanced Tab
            hPFIs = obj.hResourceStore.filterByClass(?dabs.resources.ios.PFI);
            obj.pmhFrameClockIn.String = [{''}, hPFIs];
            obj.pmhFrameClockIn.pmValue = obj.hResource.hFrameClockIn;
            obj.pmhFrameClockIn.Enable = ~most.idioms.isValidObj(obj.hResource.hAOControl) || ~isa(obj.hResource.hAOControl.hDAQ,'dabs.resources.daqs.vDAQ');

            algorithms = {'default','maa','spline','pchip','linear','linearwithsettle'};
            obj.pmPositionInterpolationAlgorithm.String = algorithms;
            obj.pmPositionInterpolationAlgorithm.pmValue = obj.hResource.positionInterpolationAlgorithm;
        end
        
        function apply(obj)
            hasCOM = isprop(obj.hResource,'hCOM');
            if hasCOM
                most.idioms.safeSetProp(obj.hResource,'hCOM',obj.pmhCOM.pmValue);
            end
            
            most.idioms.safeSetProp(obj.hResource,'hAOControl',obj.pmhAOControl.pmValue);
            most.idioms.safeSetProp(obj.hResource,'hAIFeedback',obj.pmhAIFeedback.pmValue);
            
            most.idioms.safeSetProp(obj.hResource,'voltsPerDistance',str2double(obj.etVoltsPerDistance.String));
            most.idioms.safeSetProp(obj.hResource,'distanceVoltsOffset',str2double(obj.etDistanceVoltsOffset.String));
            most.idioms.safeSetProp(obj.hResource,'travelRange',[str2double(obj.etTravelRange1.String) str2double(obj.etTravelRange2.String)]);
            most.idioms.safeSetProp(obj.hResource,'parkPosition',str2double(obj.etParkPosition.String));
            
            most.idioms.safeSetProp(obj.hResource,'hFrameClockIn',obj.pmhFrameClockIn.pmValue);
            most.idioms.safeSetProp(obj.hResource,'positionInterpolationAlgorithm',obj.pmPositionInterpolationAlgorithm.pmValue);
            
            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end
        
        function remove(obj)
            obj.hResource.deleteAndRemoveMdfHeading();
        end
        
        
        function readTravelRange(obj, src, evt)
            if isempty(obj.hResource.errorMsg)
                obj.hResource.readDeviceTravelRange();
                obj.redraw();
            else
                hFig_ = warndlg('Not connected to device.');
                most.gui.centerOnScreen(hFig_);
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

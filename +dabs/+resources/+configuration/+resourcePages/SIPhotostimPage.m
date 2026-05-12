classdef SIPhotostimPage < dabs.resources.configuration.ResourcePage
    properties
        pmhScan
        pmLoggingStartTrigger
        pmBeamAiId
        pmStimActiveOutputChannel
        pmBeamActiveOutputChannel
        pmSlmTriggerOutputChannel

        cbPairStimActiveToImagingAuxTrigger
        cbPairBeamActiveToImagingAuxTrigger
    end
    
    methods
        function obj = SIPhotostimPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            hTabGroup = uitabgroup('Parent',hParent);
            hTab = uitab('Parent',hTabGroup,'Title','Basic');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [60 32 120 20],'Tag','txhScan','String','Scan System','HorizontalAlignment','right');
                obj.pmhScan  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [190 32 120 20],'Tag','pmhScan');

            hTab = uitab('Parent',hTabGroup,'Title','Advanced');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 62 160 20],'Tag','txLoggingStartTrigger','String','Logging start trigger (optional)','HorizontalAlignment','right');
                obj.pmLoggingStartTrigger  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [170 62 140 20],'Tag','pmLoggingStartTrigger');

                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [40.6 94 120 20],'Tag','txBeamAiId','String','Beam monitor (optional)','HorizontalAlignment','right');
                obj.pmBeamAiId  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [170 92 140 20],'Tag','pmBeamAiId');

                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [19.2 124.8 140 20],'Tag','txStimActiveOutputChannel','String','Stim active output (optional)','HorizontalAlignment','right');
                obj.pmStimActiveOutputChannel  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [170 122 140 20],'Tag','pmStimActiveOutputChannel');
                ttString = sprintf('Check this to also assign this output to auxiliary input 3\nof all imaging systems to get timestamps of your stimulations \nwhile doing simultaneous imaging and photostimulation.');
                obj.cbPairStimActiveToImagingAuxTrigger = most.gui.uicontrol('Parent',hTab,'Style','checkbox','String','Pair','RelPosition', [320 122 41 20],'Tag','cbStimActiveOutputPair','tooltip',ttString);

                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [10 152 150 20],'Tag','txBeamActiveOutputChannel','String','Beam active output (optional)','HorizontalAlignment','right');
                obj.pmBeamActiveOutputChannel  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [170 152 140 20],'Tag','pmBeamActiveOutputChannel');
                ttString = sprintf('Check this to also assign this output to auxiliary input 4\nof all imaging sytems to get timestamps of your stimulations \nwhile doing simultaneous imaging and photostimulation.');
                obj.cbPairBeamActiveToImagingAuxTrigger = most.gui.uicontrol('Parent',hTab,'Style','checkbox','String','Pair','RelPosition', [319.8 152 40 20],'Tag','cbBeamActiveOutputPair','tooltip',ttString);

                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 182 140 20],'Tag','txmSlmTriggerOutputChannel','String','Slm update trigger (optional)','HorizontalAlignment','right');
                obj.pmSlmTriggerOutputChannel  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [170 182 140 20],'Tag','pmSlmTriggerOutputChannel');
        end
        
        function redraw(obj) 
            hRggScans = obj.hResourceStore.filterByClass('scanimage.components.scan2d.RggScan');
            hLinScans = obj.hResourceStore.filterByClass('scanimage.components.scan2d.LinScan');
            hSlmScans = obj.hResourceStore.filterByClass('scanimage.components.scan2d.SlmScan');
            
            obj.pmhScan.String = [{''}, hRggScans, hLinScans, hSlmScans];
            obj.pmhScan.pmValue = obj.hResource.hScan;
            
            isvDAQ = isa(obj.hResource.hScan,'scanimage.components.scan2d.RggScan');
            if isvDAQ
                obj.pmLoggingStartTrigger.Enable = 'off';
                obj.pmBeamAiId.Enable = 'off';

                if numel(hRggScans) > 1
                    if most.idioms.isValidObj(obj.hResource.beamActiveOutputChannel) && checkPaired(obj.hResource.beamActiveOutputChannel)
                        obj.cbPairBeamActiveToImagingAuxTrigger.hCtl.BackgroundColor = most.constants.Colors.lightGreen;
                    else
                        obj.cbPairBeamActiveToImagingAuxTrigger.hCtl.BackgroundColor = most.constants.Colors.lightGray;
                    end

                    if most.idioms.isValidObj(obj.hResource.stimActiveOutputChannel) && checkPaired(obj.hResource.stimActiveOutputChannel)
                        obj.cbPairStimActiveToImagingAuxTrigger.hCtl.BackgroundColor = most.constants.Colors.lightGreen;
                    else
                        obj.cbPairStimActiveToImagingAuxTrigger.hCtl.BackgroundColor = most.constants.Colors.lightGray;
                    end
                else
                    obj.cbPairStimActiveToImagingAuxTrigger.Visible = 'off';
                    obj.cbPairBeamActiveToImagingAuxTrigger.Visible = 'off';
                end
            else
                obj.pmLoggingStartTrigger.Enable = 'on';
                obj.pmBeamAiId.Enable = 'on';
                obj.cbPairBeamActiveToImagingAuxTrigger.Visible = 'off'; %Feature is unique to vDAQ as a BNC cable isn't required
                obj.cbPairBeamActiveToImagingAuxTrigger.Visible = 'off'; %to share stim output with imaging auxiliary input.
            end
            
            obj.pmLoggingStartTrigger.String = [{''}, obj.hResourceStore.filterByClass('dabs.resources.ios.PFI')];
            obj.pmLoggingStartTrigger.pmValue = obj.hResource.loggingStartTrigger;
            
            obj.pmBeamAiId.String = [{''}, obj.hResourceStore.filterByClass('dabs.resources.ios.AI')];
            obj.pmBeamAiId.pmValue = obj.hResource.BeamAiId;
            
            obj.pmStimActiveOutputChannel.String = [{''}, obj.hResourceStore.filter(@(hR)isa(hR,'dabs.resources.ios.DO')&&hR.supportsHardwareTiming)];
            obj.pmStimActiveOutputChannel.pmValue = obj.hResource.stimActiveOutputChannel;
            obj.cbPairStimActiveToImagingAuxTrigger.Value = obj.hResource.pairStimActiveOutputChannel;
            
            obj.pmBeamActiveOutputChannel.String = [{''}, obj.hResourceStore.filter(@(hR)isa(hR,'dabs.resources.ios.DO')&&hR.supportsHardwareTiming)];
            obj.pmBeamActiveOutputChannel.pmValue = obj.hResource.beamActiveOutputChannel;
            obj.cbPairBeamActiveToImagingAuxTrigger.Value = obj.hResource.pairBeamActiveOutputChannel;
            
            obj.pmSlmTriggerOutputChannel.String = [{''}, obj.hResourceStore.filter(@(hR)isa(hR,'dabs.resources.ios.DO')&&hR.supportsHardwareTiming)];
            obj.pmSlmTriggerOutputChannel.pmValue = obj.hResource.slmTriggerOutputChannel;    

            %%% Nested Function
            function tf = checkPaired(port)
                rggScans = obj.hResourceStore.filterByClass('scanimage.components.scan2d.RggScan');
                pairedRggScans = false(numel(rggScans),1);

                auxTriggerIns = {'auxTrigger1In' 'auxTrigger2In' 'auxTrigger3In' 'auxTrigger4In'};

                for rggIdx = 1:numel(rggScans)
                    rggScan = rggScans{rggIdx};
                    pairedRggScans(rggIdx) = any(cellfun(@(auxTrig)isequal(port,rggScan.(auxTrig)),auxTriggerIns));
                end

                tf = all(pairedRggScans);
            end
        end
        
        function apply(obj)
            most.idioms.safeSetProp(obj.hResource,'hScan',obj.pmhScan.pmValue);
            most.idioms.safeSetProp(obj.hResource,'loggingStartTrigger',obj.pmLoggingStartTrigger.pmValue);
            most.idioms.safeSetProp(obj.hResource,'BeamAiId',obj.pmBeamAiId.pmValue);
            most.idioms.safeSetProp(obj.hResource,'stimActiveOutputChannel',obj.pmStimActiveOutputChannel.pmValue);
            most.idioms.safeSetProp(obj.hResource,'beamActiveOutputChannel',obj.pmBeamActiveOutputChannel.pmValue);
            most.idioms.safeSetProp(obj.hResource,'slmTriggerOutputChannel',obj.pmSlmTriggerOutputChannel.pmValue);
            most.idioms.safeSetProp(obj.hResource,'pairStimActiveOutputChannel',obj.cbPairStimActiveToImagingAuxTrigger.Value);
            most.idioms.safeSetProp(obj.hResource,'pairBeamActiveOutputChannel',obj.cbPairBeamActiveToImagingAuxTrigger.Value);
            
            obj.hResource.checkOrSetRggScansAuxilliaryTriggerPairing(true);

            obj.hResource.saveMdf();
            obj.hResource.validateConfiguration();
        end
        
        function remove(obj)
            % No-Op
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

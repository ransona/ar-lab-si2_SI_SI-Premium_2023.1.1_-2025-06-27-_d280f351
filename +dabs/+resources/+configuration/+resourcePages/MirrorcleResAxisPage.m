classdef MirrorcleResAxisPage < dabs.resources.configuration.ResourcePage
    properties
        pmhAOZoom
        pmhDOSync
        etInputVoltageRange_Vpp
        etAngularRange_deg
        etNominalFreq
        etScanOffset
        etSyncPhase
        etRampTime
        pmhDOFilterXPort
        pmhDOFilterYPort
        etDOFilterXFreq
        etDOFilterYFreq
        cbDOFilterXEn
        cbDOFilterYEn

        % frequency tab
        pmhAIFeedback
        etTimePerInterval
    end
    
    methods
        function obj = MirrorcleResAxisPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            hTabGroup = uitabgroup('Parent',hParent);
            hTab = uitab('Parent',hTabGroup,'Title','Device Configuration');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [19 25 170 20],'Tag','txhAOZoom','String','Zoom Control Channel','HorizontalAlignment','right');
                obj.pmhAOZoom  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [200 23 120 20],'Tag','pmhAOZoom');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 49 170 20],'Tag','txhDISync','String','Sync Channel','HorizontalAlignment','right');
                obj.pmhDOSync = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [200 46 120 20],'Tag','pmhDOSync');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 73 170 20],'Tag','txInputVoltageRange_Vpp','String','Input Voltage Range','HorizontalAlignment','right');
                obj.etInputVoltageRange_Vpp = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [200 70 120 20],'Tag','etInputVoltageRange_Vpp');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [21 98 170 20],'Tag','txAngularRange_deg','String','Angular Range [optical degrees]','HorizontalAlignment','right');
                obj.etAngularRange_deg = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [200 96 120 20],'Tag','etAngularRange_deg');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 123 170 20],'Tag','txNominalFreq','String','Nominal Frequency [Hz]','HorizontalAlignment','right');
                obj.etNominalFreq = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [201 122 120 20],'Tag','etNominalFreq');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 150 170 20],'Tag','txScanOffset','String','Scan Offset [optical degrees]','HorizontalAlignment','right');
                obj.etScanOffset = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [200 148 120 20],'Tag','etScanOffset');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 175 170 20],'Tag','txSyncPhase','String','Sync Phase [degrees]','HorizontalAlignment','right');
                obj.etSyncPhase = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [200 173 120 20],'Tag','etSyncPhase');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 200 170 20],'Tag','txRampTime','String','Ramp Time [s]','HorizontalAlignment','right');
                obj.etRampTime = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [200 198 120 20],'Tag','etRampTime');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [73 222 170 20],'Tag','FilterTableTitle','String','Filter Clock DO Channels','HorizontalAlignment','right',...
                'FontSize', 10, 'FontWeight', 'bold');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [90 242 30 20],'Tag','FilterColumnPort','String','Port','HorizontalAlignment','right');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [175 242 90 20],'Tag','FilterColumnFreq','String','Frequency [Hz]','HorizontalAlignment','right');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [273 242 40 20],'Tag','FilterColumnEnable','String','Enable','HorizontalAlignment','right');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-130 264 170 20],'Tag','txhDOFilterX','String','X','HorizontalAlignment','right');
                obj.pmhDOFilterXPort = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [61 259 120 20],'Tag','pmhDOFilterXPort');
                obj.etDOFilterXFreq = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [190 260 80 20],'Tag','etDOFilterXFreq','HorizontalAlignment','right');
                obj.cbDOFilterXEn = most.gui.uicontrol('Parent',hTab,'Style','checkbox','RelPosition', [290 260 20 20],'Tag','cbDOFilterXEn');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [-130 287 170 20],'Tag','txhhDOFilterY','String','Y','HorizontalAlignment','right');
                obj.pmhDOFilterYPort = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [61 282 120 20],'Tag','pmhDOFilterYPort');
                obj.etDOFilterYFreq = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [190 283 80 20],'Tag','etDOFilterYFreq','HorizontalAlignment','right');
                obj.cbDOFilterYEn = most.gui.uicontrol('Parent',hTab,'Style','checkbox','RelPosition', [290 281 20 20],'Tag','cbDOFilterYEn');

            hTab = uitab('Parent',hTabGroup,'Title','Frequency Sweep');
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [20 44 170 20],'Tag','txhAIFeedback','String','Feedback Channel','HorizontalAlignment','right');
                obj.pmhAIFeedback = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [200 40 120 20],'Tag','pmhAIFeedback');
                
                most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [19 69 170 17],'Tag','txTimePerInterval','String','Time per interval','HorizontalAlignment','right');
                obj.etTimePerInterval = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [200 70 120 20],'Tag','etTimePerInterval');

                most.gui.uicontrol('Parent',hTab,'Tag','pbFrequencyCalibration','String','Frequency Calibration','RelPosition', [132 123 144 33],'Callback',@(varargin)obj.hResource.openFrequencyCalibrationGUI());
        end
        
        function redraw(obj)            
            hAOs = obj.hResourceStore.filter(@(hR)isa(hR,'dabs.resources.ios.AO')&&isa(hR.hDAQ,'dabs.resources.daqs.vDAQ'));
            obj.pmhAOZoom.String = [{''}, hAOs];
            if most.idioms.isValidObj(obj.hResource.hAOZoom)
                obj.pmhAOZoom.pmValue = obj.hResource.hAOZoom.name;
            end
            
            hIOs = obj.hResourceStore.filter(@(hR)isa(hR,'dabs.resources.ios.DO')&&isa(hR.hDAQ,'dabs.resources.daqs.vDAQ'));
            obj.pmhDOSync.String = [{''}, hIOs];
            if most.idioms.isValidObj(obj.hResource.hDOSync)
                obj.pmhDOSync.pmValue = obj.hResource.hDOSync.name;
            end
            
            hIOs = obj.hResourceStore.filter(@(hR)isa(hR,'dabs.resources.ios.DO')&&isa(hR.hDAQ,'dabs.resources.daqs.vDAQ'));
            obj.pmhDOFilterXPort.String = [{''}, hIOs];
            if most.idioms.isValidObj(obj.hResource.hDOFilterX)
                obj.pmhDOFilterXPort.pmValue = obj.hResource.hDOFilterX.name;
            end
            
            obj.pmhDOFilterYPort.String = [{''}, hIOs];
            if most.idioms.isValidObj(obj.hResource.hDOFilterY)
                obj.pmhDOFilterYPort.pmValue = obj.hResource.hDOFilterY.name;
            end

            hAIs = obj.hResourceStore.filter(@(hR)isa(hR,'dabs.resources.ios.AI')&&isa(hR.hDAQ,'dabs.resources.daqs.vDAQ'));
            obj.pmhAIFeedback.String = [{''}, hAIs];
            if most.idioms.isValidObj(obj.hResource.hAIFeedback)
                obj.pmhAIFeedback.pmValue = obj.hResource.hAIFeedback.name;
            end
            
            obj.etInputVoltageRange_Vpp.String = num2str(obj.hResource.inputVoltageRange_Vpp);
            obj.etAngularRange_deg.String = num2str(obj.hResource.angularRange_deg);
            obj.etNominalFreq.String = num2str(obj.hResource.nominalFrequency_Hz);
            obj.etScanOffset.String = num2str(obj.hResource.scanOffset_deg);
            obj.etSyncPhase.String = num2str(obj.hResource.syncPhase_deg);
            obj.etRampTime.String = num2str(obj.hResource.rampTime_s);
            obj.etDOFilterXFreq.String = num2str(obj.hResource.xFilterClockFreq_Hz);
            obj.etDOFilterYFreq.String = num2str(obj.hResource.yFilterClockFreq_Hz);
            
            obj.cbDOFilterXEn.Value = obj.hResource.xFilterClockEnable;
            obj.cbDOFilterYEn.Value = obj.hResource.yFilterClockEnable;

            obj.etTimePerInterval.String = num2str(obj.hResource.timePerTest_s);
        end
        
        function apply(obj)
            most.idioms.safeSetProp(obj.hResource,'hAOZoom',obj.pmhAOZoom.pmValue);
            most.idioms.safeSetProp(obj.hResource,'hDOSync',obj.pmhDOSync.pmValue);
            most.idioms.safeSetProp(obj.hResource,'hDOFilterX',obj.pmhDOFilterXPort.pmValue);
            most.idioms.safeSetProp(obj.hResource,'hDOFilterY',obj.pmhDOFilterYPort.pmValue);
            most.idioms.safeSetProp(obj.hResource,'inputVoltageRange_Vpp', str2double(obj.etInputVoltageRange_Vpp.String));
            most.idioms.safeSetProp(obj.hResource,'angularRange_deg',str2double(obj.etAngularRange_deg.String));
            most.idioms.safeSetProp(obj.hResource,'nominalFrequency_Hz',str2double(obj.etNominalFreq.String));
            most.idioms.safeSetProp(obj.hResource,'scanOffset_deg',str2double(obj.etScanOffset.String));
            most.idioms.safeSetProp(obj.hResource,'syncPhase_deg',str2double(obj.etSyncPhase.String));
            most.idioms.safeSetProp(obj.hResource,'rampTime_s',str2double(obj.etRampTime.String));
            most.idioms.safeSetProp(obj.hResource,'xFilterClockFreq_Hz', str2double(obj.etDOFilterXFreq.String));
            most.idioms.safeSetProp(obj.hResource,'yFilterClockFreq_Hz',str2double(obj.etDOFilterYFreq.String));
            most.idioms.safeSetProp(obj.hResource,'xFilterClockEnable', obj.cbDOFilterXEn.Value);
            most.idioms.safeSetProp(obj.hResource,'yFilterClockEnable', obj.cbDOFilterYEn.Value);
            
            most.idioms.safeSetProp(obj.hResource,'timePerTest_s',str2double(obj.etTimePerInterval.String));
            most.idioms.safeSetProp(obj.hResource,'hAIFeedback',obj.pmhAIFeedback.pmValue);

            obj.hResource.saveMdf();
            obj.hResource.reinit();
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

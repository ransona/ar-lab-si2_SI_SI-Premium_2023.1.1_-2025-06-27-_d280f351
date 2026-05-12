classdef ThorlabsPmtPage < dabs.resources.configuration.ResourcePage
    properties
        pmhVisa
        etWavelength
        cbAutoOn
        cbLoadGain
        etGain
        cbLoadBandwidth
        pmBandwidth
        cbLoadOffset
        etOffset
        txDescription
    end
    
    methods
        function obj = ThorlabsPmtPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            hTabGroup = uitabgroup('Parent',hParent);
            
            hTab = uitab('Parent',hTabGroup,'Title','Basic');
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 30 120 20],'Tag','txhVisa','String','Visa Address','HorizontalAlignment','right');
            obj.pmhVisa  = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','String',{''},'RelPosition', [125 27 230 20],'Tag','pmhVisa');
            
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 51 120 20],'Tag','txWavelength','String','Wavelength [nm]','HorizontalAlignment','right');
            obj.etWavelength = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [125 49 60 20],'Tag','etWavelength');
            
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 71 120 20],'Tag','txAutoOn','String','Auto on','HorizontalAlignment','right');
            obj.cbAutoOn = most.gui.uicontrol('Parent',hTab,'Style','checkbox','RelPosition', [125 70 250 20],'Tag','cbAutoOn');
            
            obj.txDescription = most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [30 182 320 100],'Tag','txDescription','String','','HorizontalAlignment','left');
            
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 195 120 20],'Tag','txLoadGain','String','Gain [V]','HorizontalAlignment','right');
            ttstr = sprintf('Whether or not to apply a saved following gain setting at launch\nSuggestion: With this box left unchecked, Thorlabs PMT defaults to minimal gain.\nOnly check this box if you truly would rather another gain setting applied at ScanImage launch.');
            obj.cbLoadGain = most.gui.uicontrol('Parent',hTab,'Style','checkbox','RelPosition', [205.333333333333 193 20 20],'Tag','cbGain','Tooltip',ttstr,'callback',@(varargin)obj.setETGainEnable());
            ttstr = sprintf('Gain voltage to apply.\n\nH10720 0.5 - 1.1\nH10721 0.5 - 1.1\nH10770PA40 0.5 - 0.9\nH11706P40 0.5 - 0.9\nAPD 0.0 - 2.0\nDIODE 0.0 - 2.0\n');
            obj.etGain = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [130 193 69 20],'Tag','etGain','Tooltip',ttstr,'Enable','off');
            
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [0 221 120 20],'Tag','txLoadBandwidth','String','Bandwidth [MHz]','HorizontalAlignment','right');
            obj.cbLoadBandwidth = most.gui.uicontrol('Parent',hTab,'Style','checkbox','RelPosition', [205.666666666667 216.666666666667 20 20],'Tag','cbBandwidth','Tooltip','Whether or not to apply a saved bandwidth setting at launch','callback',@(varargin)obj.setPMBandwidthEnable());
            obj.pmBandwidth = most.gui.uicontrol('Parent',hTab,'Style','popupmenu','RelPosition', [129.666666666667 216 70 20],'Tag','pmBandwidth','Tooltip','Low pass cutoff frequency in MHz','Enable','off');
            
            most.gui.uicontrol('Parent',hTab,'Style','text','RelPosition', [2.00000000000003 243.666666666667 120 20],'Tag','txOffset','String','Offset [V]','HorizontalAlignment','right');
            obj.cbLoadOffset = most.gui.uicontrol('Parent',hTab,'Style','checkbox','RelPosition', [206 241.666666666667 20 20],'Tag','cbOffset','Tooltip','Whether or not to apply a saved offset setting at launch','callback',@(varargin)obj.setETOffsetEnable());
            obj.etOffset = most.gui.uicontrol('Parent',hTab,'Style','edit','RelPosition', [130 241 70 20],'Tag','etOffset','Tooltip','Signal offset voltage','Enable','off');
            
            hTab = uitab('Parent',hTabGroup,'Title','Advanced');
            most.gui.uicontrol('Parent',hTab,'RelPosition', [20 52 150 30],'Tag','pbChangeSerial','String','Change PMT serial number','Callback',@(varargin)obj.changeSerial());
            most.gui.uicontrol('Parent',hTab,'RelPosition', [20 92 150 30],'Tag','pbChangePmtType','String','Change PMT type','Callback',@(varargin)obj.changePmtType());
        end
        
        function redraw(obj)            
            hVisas = obj.hResourceStore.filter(@(v)dabs.thorlabs.PMT.isValidThorPMT(v));
            obj.pmhVisa.String = [{''}, hVisas];
            obj.pmhVisa.pmValue = obj.hResource.hVisa;
            
            obj.etWavelength.String = num2str(obj.hResource.wavelength_nm);
            obj.cbAutoOn.Value = obj.hResource.autoOn;
            
            obj.cbLoadGain.Value = obj.hResource.loadGainAtLaunch;
            obj.setETGainEnable();
            obj.etGain.String = num2str(obj.hResource.gain_V);
        
            obj.cbLoadBandwidth.Value = obj.hResource.loadBandwidthAtLaunch;
            obj.setPMBandwidthEnable();
            obj.pmBandwidth.String = {'80','2.5','0.25'};
            obj.pmBandwidth.pmValue = num2str(obj.hResource.bandwidth_Hz/1e6);
            
            obj.cbLoadOffset.Value = obj.hResource.loadGainOffsetAtLaunch;
            obj.setETOffsetEnable();
            obj.etOffset.String = num2str(obj.hResource.gainOffset_V);
            
            if isempty(obj.hResource.errorMsg)
                obj.txDescription.String = sprintf('VISA Driver: %s\nDevice manufacturer: %s\nDevice model: %s\nDevice serial: %s\nDevice firmware: %s\nPMT Type: %s' ...
                    ,obj.hResource.driverInfo,obj.hResource.manufacturer,obj.hResource.model,obj.hResource.serialNumber,obj.hResource.firmware,obj.hResource.pmtType);
            else
                obj.txDescription.String = '';
            end
        end
        
        function changeSerial(obj)
            try
                assert(most.idioms.isValidObj(obj.hResource.hVisa),'Invalid Visa Address');
                newSerial = queryUserForSerial();
                if isempty(newSerial)
                    return % User abort
                end
                
                obj.hResource.setSerial(newSerial);
                
                h = helpdlg(sprintf('Serial changed successfully.\nUnplug PMT and plug back in, then click ''OK'''),'SUCCESS');
                waitfor(h);
                
                findVisaObject(newSerial)
                
                obj.redraw();
            catch ME
                most.ErrorHandler.logAndReportError(ME);
                errordlg(ME.message);
            end
            
            %%% Nested functions
            function newSerial = queryUserForSerial()
                currentserial = obj.hResource.hVisa.name;
                currentserial = regexpi(currentserial,'[A-F0-9]{8}','match','once');
                
                prompt = sprintf('Please enter a new Hexadecimal serial number\n(e.g. ''AA00AA00'')');
                dlgtitle = 'Enter Serial';
                dims = 1;
                definput = {currentserial};
                
                newSerial = inputdlg(prompt,dlgtitle,dims,definput);
                
                if isempty(newSerial)
                    newSerial = '';
                else
                    newSerial = newSerial{1};
                end
            end
            
            function findVisaObject(serial)                
                pause(1);
                dabs.resources.VISA.scanSystem();
                
                hVisas = obj.hResourceStore.filterByClass('dabs.resources.VISA');
                visaNames = cellfun(@(hR)hR.name,hVisas,'UniformOutput',false);
                matches = regexpi(visaNames,['^USB[0-9]::0x[A-F0-9]{4}::0x[A-F0-9]{4}::' serial],'match','once');
                mask = cellfun(@(m)~isempty(m),matches);
                
                if any(mask)
                    obj.hResource.hVisa = hVisas{mask};
                    obj.hResource.saveMdf();
                    obj.hResource.reinit();
                end
            end
        end
        
        function changePmtType(obj)            
            try
                assert(most.idioms.isValidObj(obj.hResource.hVisa),'Invalid Visa Address');
                newPmtType = queryUserForPmtType();
                if iscell(newPmtType) && isempty(newPmtType)
                    return % User abort
                end
                
                obj.hResource.setPmtType(newPmtType);
                
                helpdlg(sprintf('PMT type changed successfully.'),'SUCCESS');
                obj.hResource.reinit();
                
                obj.redraw();
            catch ME
                most.ErrorHandler.logAndReportError(ME);
                errordlg(ME.message);
            end
            
            % Nested function
            function pmtType = queryUserForPmtType()
                validPmts = obj.hResource.PMT_CONSTANTS.keys;
                currentPmtType = obj.hResource.pmtType;
                
                prompt = sprintf('Please enter a new PMT type.\nValid options are:\n{%s}',strjoin(validPmts,', '));
                dlgtitle = 'Enter PMT Type';
                dims = 1;
                definput = {currentPmtType};
                
                pmtType = inputdlg(prompt,dlgtitle,dims,definput);
                
                if ~isempty(pmtType)
                    pmtType = pmtType{1};
                end
            end
        end
        
        function apply(obj)
            most.idioms.safeSetProp(obj.hResource,'hVisa',obj.pmhVisa.pmValue);
            most.idioms.safeSetProp(obj.hResource,'wavelength_nm',str2double(obj.etWavelength.String));
            most.idioms.safeSetProp(obj.hResource,'autoOn',obj.cbAutoOn.Value);
            
            most.idioms.safeSetProp(obj.hResource,'loadGainAtLaunch',logical(obj.cbLoadGain.Value));
            if obj.cbLoadGain.Value
                obj.hResource.initialGain_V = str2double(obj.etGain.String);
            end
            
            most.idioms.safeSetProp(obj.hResource,'loadBandwidthAtLaunch',logical(obj.cbLoadBandwidth.Value));
            if obj.cbLoadBandwidth.Value
               obj.hResource.initialBandwidth_Hz = str2double(obj.pmBandwidth.pmValue)*1e6;
            end
            
            most.idioms.safeSetProp(obj.hResource,'loadGainOffsetAtLaunch',logical(obj.cbLoadOffset.Value));
            if obj.cbLoadOffset.Value
               obj.hResource.initialGainOffset_V = str2double(obj.etOffset.String);
            end
            
            obj.hResource.saveMdf();
            obj.hResource.reinit();
            pause(1); %allow second before redrawing for PMT controller to reflect properties written at reinit.
        end
        
        function remove(obj)
            obj.hResource.deleteAndRemoveMdfHeading();
        end
    end
    
    %% Callbacks
    methods
        function setETGainEnable(obj, varargin)
            if obj.cbLoadGain.Value
                obj.etGain.Enable = 'on';
            else
                obj.etGain.Enable = 'off';
            end
        end
        
        function setPMBandwidthEnable(obj, varargin)
            if obj.cbLoadBandwidth.Value
                obj.pmBandwidth.Enable = 'on';
            else
                obj.pmBandwidth.Enable = 'off';
            end
        end
        
        function setETOffsetEnable(obj, varargin)
            if obj.cbLoadOffset.Value
                obj.etOffset.Enable = 'on';
            else
                obj.etOffset.Enable = 'off';
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

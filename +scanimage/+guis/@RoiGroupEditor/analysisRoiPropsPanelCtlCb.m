function analysisRoiPropsPanelCtlCb(obj,src,~)
    obj.enableListeners = false;
    switch src.Tag
        case 'etName'
            obj.selectedObj.name = src.String;

        case 'cbEnable'
            obj.selectedObj.enable = src.Value;

        case 'cbDisplay'
            obj.selectedObj.display = src.Value;

        case 'cbDiscrete'
            obj.selectedObj.discretePlaneMode = src.Value;

        case 'pmChannel'
            if numel(obj.selectedObj.scanfields)
                arrayfun(@(x)setp(x,'channel',obj.hAnalysisRoiPropsPanelCtls.pmChannel.hCtl.Value),obj.selectedObj.scanfields);
            end

        case 'etThreshold'
            if numel(obj.selectedObj.scanfields)
                arrayfun(@(x)setp(x,'threshold',str2double(obj.hAnalysisRoiPropsPanelCtls.etThreshold.hCtl.String)),obj.selectedObj.scanfields);
            end

        case 'pmProcessor'
            if numel(obj.selectedObj.scanfields)
                arrayfun(@(x)setp(x,'processor',obj.rProcMap(obj.hAnalysisRoiPropsPanelCtls.pmProcessor.hCtl.Value)),obj.selectedObj.scanfields);
            end
    end
    obj.enableListeners = true;
    obj.updateTable();
    obj.setZProjectionLimits();
    obj.updateDisplay();

    function setp(obj,prp,val)
        obj.(prp) = val;
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

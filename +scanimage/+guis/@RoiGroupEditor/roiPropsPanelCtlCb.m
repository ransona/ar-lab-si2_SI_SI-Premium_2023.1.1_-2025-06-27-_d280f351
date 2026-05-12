function roiPropsPanelCtlCb(obj,src,~)
    obj.enableListeners = false;

    ME = [];
    try
        switch(src.Tag)
            case 'etName'
                obj.selectedObj.name = src.String;

            case 'cbEnable'
                obj.selectedObj.enable = src.Value;

            case 'cbDisplay'
                obj.selectedObj.display = src.Value;

            case 'cbDiscrete'
                obj.selectedObj.discretePlaneMode = src.Value;

            case 'etPowers'
                obj.selectedObj.powers = str2num(src.String);

            case 'etPZ'
                obj.selectedObj.pzAdjust = str2num(src.String);

            case 'etLzs'
                obj.selectedObj.Lzs = str2num(src.String);
        end
    catch ME
        % handled below
    end

    obj.enableListeners = true;
    obj.updateTable();
    obj.setZProjectionLimits();
    obj.updateDisplay();
    obj.roiPropsPanelUpdate();

    if ~isempty(ME)
        ME.rethrow();
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

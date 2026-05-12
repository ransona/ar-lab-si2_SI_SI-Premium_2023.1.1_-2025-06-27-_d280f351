function classStruct = findAllConfigClasses()
    classNames = getConfigPageClasses();
    classStruct = formatClasses(classNames);
end

%%% Local functions
function classStruct = formatClasses(classNames)
    classStruct = struct('category',{},'descriptiveName',{},'className',{});
    
    for idx = 1:numel(classNames)
        try
            className = classNames{idx};
            func = str2func([className '.getDescriptiveNames']);
            descriptiveNames = func();
            
            if isempty(descriptiveNames)
                continue;
            end
            
            % find categories
            tokens=regexp(descriptiveNames(:)','^((?>[^\\]+(?=\\))?)\\?(.*)$','tokens','once');
            tokens = vertcat(tokens{:});
            categories = tokens(:,1);
            descriptiveNames = tokens(:,2);
            
            newStruct = struct(...
                 'category', categories ...
                ,'descriptiveName', descriptiveNames...
                ,'className',      className);
            
            classStruct = vertcat(classStruct,newStruct);
        catch ME
            most.ErrorHandler.logAndReportError(ME);
        end
    end
    
    [~,sortIdx] = sort({classStruct.descriptiveName});
    classStruct = classStruct(sortIdx);
end

function classNames = getConfigPageClasses()    
    hWaitbar = waitbar(0.25,'Finding classes...');
    rehash();
    try
        classNames = dabs.resources.Device.findAllDevices();
        hasConfigPageMask = cellfun(@(cN)most.idioms.isa(cN,'dabs.resources.configuration.HasConfigPage'),classNames);
        classNames = classNames(hasConfigPageMask);
        
    catch ME_
        delete(hWaitbar);
        rethrow(ME_);
    end
    delete(hWaitbar);
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

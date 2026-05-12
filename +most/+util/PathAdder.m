classdef PathAdder < handle
    properties (SetAccess = private)
        folders = struct('folder',{},'wasOnPath',{});
    end
    
    methods
        function obj = PathAdder(folders)
            if nargin < 1 || isempty(folders)
                folders = {};
            end
            
            switch class(folders)
                case 'cell'
                    cellfun(@(p)obj.addPath(p),folders);
                case 'string'
                    cellfun(@(p)obj.addPath(p),folders);
                case 'char'
                    obj.addPath(folders);
                otherwise
                    error('Invalid input for folders');
            end
        end
        
        function addPath(obj,folder)
            match = regexpi(folder,'^[A-Z]:\\','once','match');
            assert(~isempty(match),'Path must be fully qualified');
            assert(exist(folder,'dir')==7,'Folder ''%s'' not found on disk.',folder);
            
            wasOnPath = most.idioms.isOnPath(folder);

            s = warning('off','MATLAB:mpath:privateDirectoriesNotAllowedOnPath');
            addpath(folder);
            warning(s);
            
            obj.folders(end+1) = struct('folder',folder ...
                                      ,'wasOnPath',wasOnPath);
        end
        
        function removePaths(obj,force)
            if nargin<2 || isempty(force)
                force = false;
            end
            
            validateattributes(force,{'numeric','logical'},{'binary','scalar'});
            
            for idx = 1:numel(obj.folders)
                folder = obj.folders(idx);
                
                if ~folder.wasOnPath || force
                    try
                        s = warning('off','MATLAB:rmpath:DirNotFound');
                        rmpath(folder.folder);
                        warning(s);
                    catch ME
                        most.ErrorHandler.logAndReportError(ME);
                    end
                end
            end
        end
        
        function delete(obj)
            obj.removePaths();
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

classdef ScanImageDataView < matlab.mixin.Heterogeneous & handle
    
    properties (SetObservable)
        fileName;
        data;
    end
    
    %% LIFEYCLE
    methods (Static)
        function launch(fn,varargin)
            if nargin && strcmp(fn, 'debug')
                debug = true;
                fn = '';
            elseif (nargin > 1) && ismember('debug', varargin)
                debug = true;
            else
                debug = false;
            end
            
            cn = 'scanimage.guis.ScanImageDataView';
            most.HasClassDataFile.ensureClassDataFileStatic(cn,struct('lastFile','linescanData.meta.txt'));
            
            if nargin < 1 || isempty(fn)
                filename = most.HasClassDataFile.getClassDataVarStatic(cn,'lastFile',[],false);

                [filename,pathname] = uigetfile({'*.tif;*.meta.txt' 'ScanImage Data File (*.tif, *.meta.txt)';},'Open ScanImage Data',filename);
                if filename==0;return;end

                fn = fullfile(pathname,filename);
            end
            
            most.HasClassDataFile.setClassDataVarStatic(cn,'lastFile',fn,[],false);
            
            assert(exist(fn,'file')==2,'File %s was not found on disk.',fn);
            
            try
                [~,~,ext] = fileparts(fn);
                
                if strcmp(ext,'.tif')
                    hSIDV = scanimage.guis.scanimagedataview.FrameScanDataView(fn);
                else
                    hSIDV = scanimage.guis.scanimagedataview.LineScanDataView(fn,debug);
                end
                
                if most.idioms.isValidObj(hSIDV)
                    if evalin('base','exist(''hSIDV'',''var'')')
                        hSIDVa = evalin('base','hSIDV');
                        hSIDVa(end+1) = hSIDV;
                        assignin('base','hSIDV',hSIDVa);
                    else
                        assignin('base','hSIDV',hSIDV);
                    end
                end
            catch ME
                if debug
                    ME.rethrow();
                else
                    warndlg(sprintf('Failed to load SI Data View. Error message:\n%s', ME.message),'SI Data View');
                end
            end
            
        end
    end
    
    methods
        function delete(obj)
            if evalin('base','exist(''hSIDV'',''var'')')
                hSIDVa = evalin('base','hSIDV');
                
                if numel(hSIDVa) > 1
                    hSIDVa(hSIDVa == obj) = [];
                    assignin('base','hSIDV',hSIDVa);
                elseif hSIDVa == obj
                    evalin('base','clear hSIDV');
                end
            end
        end
    end
    
    methods(Sealed)
        function tf = eq(varargin)
            tf = eq@handle(varargin{:});
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

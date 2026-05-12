classdef SlmLutGlobal < scanimage.mroi.scanners.slmLut.SlmLut
    properties
        lut = []
    end
    
    properties (Access = private)
        hGI;
    end
    
    methods
        function obj = SlmLutGlobal(lut)
            if nargin > 0
                obj.lut = lut;
            end
        end
    end
    
    methods
        function pixelVals = apply(obj,phis)
            if isempty(obj.lut)
                pixelVals = phis;
                return
            end
            
            phis = single(phis);
            phis = gather(phis);
            phi_size = size(phis);
            
            phis = phis(:);
            lutmax = 2*pi;
            phis = phis - lutmax*floor(phis./lutmax); % mod is slower than this
            pixelVals = obj.hGI(phis);
            pixelVals = reshape(pixelVals,phi_size);
        end
        
        function plot(obj)            
            hFig = most.idioms.figure();
            hAx = most.idioms.axes('Parent',hFig,'Box','on');
            plot(hAx,obj.lut(:,1),obj.lut(:,2));
            hAx.XTick = min(obj.lut(:,1)):(.25*pi):max(obj.lut(:,1));
            
            l = arrayfun(@(v){sprintf('%g\\pi',v)}, round(hAx.XTick/pi,2));
            l(obj.lut(:,1) == 0) = {'0'};
            hAx.XTickLabel = strrep(l,'1\pi','\pi');
            
            hAx.XLim = [min(obj.lut(:,1)) max(obj.lut(:,1))];
            hAx.YLim = [0 max(obj.lut(:,2))*1.2];
            title(hAx,sprintf('SLM Lut at %.1fnm',obj.wavelength_um*1e3));
            xlabel(hAx,'Phase');
            ylabel(hAx,'Pixel Value');
            grid(hAx,'on');
        end
    end
    
    methods (Access = protected)
        function s = saveInternal(obj)
            s = struct();
            s.lut = gather(obj.lut);
        end
        
        function loadInternal(obj,s)
            fields = fieldnames(s);
            for idx = 1:numel(fields)
                field = fields{idx};
                try
                    obj.(field) = s.(field);
                catch ME
                    most.ErrorHandler.logAndReportError(ME);
                end
            end
        end
        
        function updateInterpolant(obj)
            if isempty(obj.lut)
                obj.hGI = [];
            else
                % about twice as fast as interp1
                obj.hGI = griddedInterpolant(obj.lut(:,1),obj.lut(:,2),'linear','nearest');
            end
        end
    end
    
    methods
        function set.lut(obj,val)
            validateattributes(val,{'numeric'},{'ncols',2,'nonnan','finite'});
            assert(issorted(val(:,1)));
            validateattributes(val(:,1),{'numeric'},{'nonnegative','<=',2*pi*1.01});    
            obj.lut = single(val);
            obj.updateInterpolant();
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

classdef nonBlockingDialog < handle
    properties (Hidden)
        hFig;
        containers = struct();
        hPbs = gobjects(1,0);
    end
    
    methods
        function obj = nonBlockingDialog(message1,message2,buttons,message1Color,varargin)
            obj.hFig = most.idioms.figure( ...
                'CloseRequestFcn',@(varargin)obj.delete() ...
                ,'Visible','off' ...
                ,varargin{:});
            movegui(obj.hFig,'center');
            
            obj.containers.main = most.idioms.uiflowcontainer('Parent',obj.hFig,'FlowDirection','TopDown');
            if ~isempty(message1)
                obj.containers.message1 = most.idioms.uiflowcontainer('Parent',obj.containers.main,'FlowDirection','LeftToRight');
                msg1 = uicontrol('Parent',obj.containers.message1,'Style','text','String',message1,...
                    'ForegroundColor',message1Color,'FontSize',14);
            end
            
            if ~isempty(message2)
                obj.containers.message2 = most.idioms.uiflowcontainer('Parent',obj.containers.main,'FlowDirection','LeftToRight');
                msg2 = uicontrol('Parent',obj.containers.message2,'Style','text','String',message2,'FontSize',11);
            end
            
            obj.containers.buttons = most.idioms.uiflowcontainer('Parent',obj.containers.main,'FlowDirection','LeftToRight');
            obj.containers.buttons.HeightLimits = [40 40];
            
            for idx = 1:length(buttons)
                button = buttons{idx};
                assert(iscell(button) && ischar(button{1}),'Input parameter ''buttons'' needs to be of format {{''string1'',@callback1},{''stringN'',@callbackN}}')
                str = button{1};
                
                if length(button) >= 2 && ~isempty(button{2})
                    assert(isa(button{2},'function_handle'),'Input parameter ''buttons'' needs to be of format {{''string1'',@callback1},{''stringN'',@callbackN}}');
                    cb = button{2};
                else
                    cb = [];
                end
                
                obj.hPbs(end+1) = uicontrol('Parent',obj.containers.buttons,'String',str,'Callback',@(varargin)obj.dispatchCallback(cb));
            end
            
            obj.hFig.Visible = 'on';
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.hFig);
        end
    end
    
    methods (Hidden)     
        function dispatchCallback(obj,cb)
            delete(obj);
            if ~isempty(cb)
                cb();
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

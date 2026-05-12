classdef SICoordinateSystemsPage < dabs.resources.configuration.ResourcePage
    properties
        hTable
        pmSelectedCS
    end
    
    methods
        function obj = SICoordinateSystemsPage(hResource,hParent)
            obj@dabs.resources.configuration.ResourcePage(hResource,hParent);
        end
        
        function makePanel(obj,hParent)
            
            uicontrolhTable= most.gui.uicontrol('Parent',hParent,'Style','uitable','RowName',{},'RelPosition', [8 155 357 138],'Tag','tableChannels'); %For ui control layout
            obj.hTable = uicontrolhTable.hCtl;
            obj.hTable.CellSelectionCallback = @obj.cellSelectionCallback;
            obj.hTable.CellEditCallback = @obj.cellEditCallback;
            obj.hTable.ColumnName = {'Available Coordinate System Files', ''};
            obj.hTable.ColumnWidth = {336, 20};
            obj.hTable.ColumnEditable = [true false];

            most.gui.uicontrol('Parent',hParent,'Style','text','String','Coordinate System:','RelPosition', [-124 341 356 120],'Tag','txSelectedCS');
            obj.pmSelectedCS = most.gui.uicontrol('Parent',hParent,'Style','popupmenu','String',{''},'RelPosition', [116 338 246 120],'Tag','pmSelectedCS');
        end
        
        function redraw(obj)
            pth = sprintf('%s\\CoordinateSystems',obj.hResource.hSI.classDataDir);
            names = ls(pth);
            names = cellstr(names);
            names(1:2) = [];
            
            [ballotX{1:numel(names),1}] = deal(most.constants.Unicode.ballot_x); % make cell vector of ballot X
            data = horzcat(names, ballotX);
            data(end+1,:) = {'    +' ''};
            obj.hTable.Data = data;
            
            obj.pmSelectedCS.String = [{''}; names];
            [~,NAME,EXT] = fileparts(obj.hResource.classDataFileName);
            obj.pmSelectedCS.pmValue = [NAME EXT];
        end
        
        function cellSelectionCallback(obj,~,evt)
            try
                if ~isempty(evt.Indices)
                    c = evt.Indices(2);
                    lastColumn = size(obj.hTable.Data,2);
                    
                    path = sprintf('%s\\CoordinateSystems\\',obj.hResource.hSI.classDataDir);

                    switch c
                        case 1
                            if evt.Indices(1) == size(obj.hTable.Data,1)
                                str = sprintf('Enter a filename for a new Coordinate System file.\n\nE.g. 40x Objective\n');
                                newName = most.gui.inputdlgCentered(str, 'New Coordinate System file', 1, {'##x Objective'});
                                if ~isempty(newName)
                                    newFileName = [path newName{1} '.mat'];
                                    currentfile = obj.hResource.classDataFileName;
                                    copyfile(currentfile, newFileName);
                                end
                                obj.redraw();
                            end
                        case lastColumn
                            stem = evt.Source.Data{evt.Indices(1)};
                            fileToDelete = [path stem];
                            
                            if strcmpi(fileToDelete,obj.hResource.classDataFileName)
                                msg = sprintf('Cannot delete the currently loaded classData File.\n\nApply with a different coordinate system file first to delete.');
                                msgbox(msg, 'Invalid Deletion', 'error');
                                return;
                            end
                            
                            msg = sprintf('Do you want to delete the below coordinate system file?\n%s',fileToDelete);
                            most.gui.nonBlockingDialog('Warning', msg, {{'Yes' @deleteFile} {'No' @false}},'r',...
                                 'Position',[0 0 700 150],'Name','Delete CoordinateSystem file');
                        otherwise
                            %No-op
                    end
                end
                

            catch ME
                most.ErrorHandler.logAndReportError(ME);
                warndlg(ME.message);
            end
            
            function deleteFile()
                delete(fileToDelete)
                obj.redraw();
            end
        end
        
        function cellEditCallback(obj,src,evt)
            path = sprintf('%s\\CoordinateSystems\\',obj.hResource.hSI.classDataDir);
            oldFileName = [path evt.PreviousData];            
            newFileName = [path evt.NewData];
            if ~strcmpi(newFileName(end-3:end), '.mat')
               newFileName = [newFileName '.mat'];
            end
            
            if isequal(oldFileName,obj.hResource.classDataFileName)
                msg = sprintf('Cannot edit the currently loaded classData File name.\n\nApply with a different coordinate system file first to edit.');
                msgbox(msg, 'Invalid Edit', 'error');
                src.Data(evt.Indices(1),evt.Indices(2)) = {evt.PreviousData};            
                return;
            end
            
            if isfile(oldFileName)
                movefile(oldFileName, newFileName);
            end
            
           obj.redraw();
        end
        
        function apply(obj)
            %save changes to current coordinate System
            obj.hResource.save();
            
            %Change to the selected coordinate system
            path = sprintf('%s\\CoordinateSystems\\',obj.hResource.hSI.classDataDir);
            fileName = [path obj.pmSelectedCS.pmValue];
            obj.hResource.setClassDataFile(fileName);
            
            obj.hResource.saveMdf();
            obj.hResource.reinit();
        end
        
        function remove(obj)
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

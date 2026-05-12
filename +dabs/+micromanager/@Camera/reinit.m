function reinit(obj)
    import dabs.resources.devices.camera.Datatype;
    import dabs.micromanager.MicroManager;

    obj.deinit();

    try
        assert(0 < exist(obj.mmInstallDir,'dir'),...
            'MicroManager installation directory not found on disk: ''%s''', obj.mmInstallDir);
        assert(0 < exist(obj.mmConfigFile,'file'),...
            'MicroManager config file not found: ''%s''', obj.mmConfigFile);

        assert(MicroManager.isOnWindowsPath(obj.mmInstallDir),...
            'MicroManager is not found on the Windows search path.');

        obj.hMM = MicroManager(obj.mmConfigFile, obj.mmInstallDir);

        assert(most.idioms.isValidObj(obj.hMM),'Failed to connect to MicroManager');

        % according to the micromanager documentation, image data
        % always has to be interpreted as unsigned integers
        % https://micro-manager.org/wiki/Matlab_Configuration
        bytesPerPixel = obj.hMM.mmc.getBytesPerPixel();
        switch bytesPerPixel
            case 1
                obj.datatype = Datatype.U8;
            case 2
                obj.datatype = Datatype.U16;
                % CURRENTLY UNSUPPORTED
                %                     case 4
                %                         obj.datatype = 'uint32';
                %                     case 8
                %                         obj.datatype = 'uint64';
            otherwise
                error('Unknown pixel datatype');
        end

        % there's currently no universal way in CMMCore to actually
        % change the pixel size, only to retrieve it.
        obj.availableDatatypes = {char(obj.datatype)};


        obj.errorMsg = '';

        % add micromanager camera properties as dynamic properties to this object
        props = obj.hMM.mmc.getDevicePropertyNames(obj.cameraLabel).iterator();
        while props.hasNext()
            pname = char(props.next());
            if obj.hMM.mmc.isPropertyReadOnly(obj.cameraLabel, pname)
                %ignore readonly properties
                continue;
            end
            validPropertyName = most.idioms.str2validName(pname);
            DynamicProp = addprop(obj, validPropertyName);
            DynamicProp.SetMethod = @(~, val)obj.setMmcProp(pname,val);
            DynamicProp.GetMethod = @(~)obj.getMmcProp(pname);
            DynamicProp.SetObservable = true;
            obj.Dynamic.(validPropertyName) = DynamicProp;
        end
    catch ME
        obj.deinit();
        obj.errorMsg = sprintf('%s: initialization error: %s',obj.name,ME.message);
        most.ErrorHandler.logError(ME,obj.errorMsg);
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

function initFromKeywordResults(obj, Results)
    assert(~isempty(Results.Parent) ...
        || (~isempty(Results.Slider) && ~isempty(Results.Edit))...
        , 'EditSlider requires either a GUI Parent or a slider edit pair.');

    obj.ValueChangedFunction = Results.ValueChangedFunction;
    obj.IsRounded = Results.IsRounded;
    assert(Results.Min < Results.Max);
    rangeMin = Results.Min;
    rangeMax = Results.Max;
    if obj.IsRounded
        rangeMin = floor(rangeMin);
        rangeMax = ceil(rangeMax);
    end

    sliderCallback = @obj.updateEditAndNotify;
    editCallback = @(Edit,~)obj.updateSliderAndNotify(Edit.String);
    defaultValue = rangeMin + (diff([rangeMin, rangeMax]) / 2);
    if obj.IsRounded
        defaultValue = round(defaultValue);
    end
    defaultString = num2str(defaultValue);
    if most.idioms.isValidObj(Results.Parent)
        GuiParent = Results.Parent;
        obj.Slider = most.gui.slider('Parent', GuiParent...
            , 'units', 'points'...
            , 'callback', sliderCallback...
            , 'min', rangeMin, 'max', rangeMax);
        obj.Slider.value = defaultValue;
        obj.Edit = uicontrol(GuiParent...
            , 'Style', 'edit'...
            , 'Callback', editCallback...
            , 'String', defaultString);
    else
        assert(most.idioms.isValidObj(Results.Slider));
        obj.Slider = Results.Slider;
        obj.Slider.callback = sliderCallback;
        obj.Slider.min = rangeMin;
        obj.Slider.max = rangeMax;
        obj.Slider.value = defaultValue;
        assert(most.idioms.isValidObj(Results.Edit) && "edit" == string(Results.Edit.Style));
        obj.Edit = Results.Edit;
        obj.Edit.Callback = editCallback;
        obj.Edit.String = defaultString;
    end

    % bind lifetime to parent of gui objects
    addDeletionListener = @(Source, callback)addlistener(Source, 'ObjectBeingDestroyed', callback);
    obj.LifetimeListener = addDeletionListener(obj.Slider.hPnl.Parent, @(~,~)delete(obj));
    if obj.Edit.Parent ~= obj.Slider.hPnl.Parent
        obj.LifetimeListener(end+1) = addDeletionListener(obj.Edit.Parent, @(~,~)delete(obj));
    end

    % bind to property changes
    addValueCorrectionListener = @(propertyName)most.ErrorHandler.addCatchingListener( ...
        obj, propertyName, 'PostSet', @(~,~)obj.rectifyValue());
    obj.SelfListener = [...
        addValueCorrectionListener('Min')...
        addValueCorrectionListener('Max')...
        addValueCorrectionListener('IsRounded')...
        ];
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

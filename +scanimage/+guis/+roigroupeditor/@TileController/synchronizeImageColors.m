function synchronizeImageColors(obj)
    most.idioms.safeDeleteObj(obj.TileImageListeners);
    ChannelControl = obj.TileManager.hSI.hChannels;
    SIController = obj.TileManager.hSI.hController{1};
    TileView = SIController.hTileView;
    for iTile = 1:length(obj.Surfaces)
        Surface = obj.Surfaces(iTile);
        Tile = obj.TileManager.hScanTiles(obj.tileIndices(iTile));
        synchronizeTile2Surface(Surface, Tile, TileView, ChannelControl);
        obj.TileImageListeners(iTile) = most.ErrorHandler.addCatchingListener( ...
            Tile, 'imageData', ...
            'PostSet', @(~,~)synchronizeTile2Surface(Surface, Tile, TileView, ChannelControl));
    end
end

function synchronizeTile2Surface(Surface, Tile, TileView, ChannelControl)
    if iscell(Tile.imageData)
        imageData = formatImageFromTile(Tile, TileView, ChannelControl);
        lineStyle = '-';
        lineWidth = 1;
    else
        imageData = zeros(2, 2, 3, 'uint8');
        lineStyle = '--';
        lineWidth = 0.5;
    end
    set(Surface, ...
        'CData', imageData, ...
        'AlphaData', double(max(imageData, [], 3) > 0), ...
        'LineStyle', lineStyle, ...
        'LineWidth', lineWidth);
end

function imageData = formatImageFromTile(Tile, TileView, ChannelControl)
    imageData = zeros([fliplr(Tile.resolutionXY), 3], 'uint8');
    contrastLimits = ChannelControl.channelLUT;
    for iChannel = 1:length(Tile.imageData)
        channelData = (Tile.imageData{iChannel} ./ Tile.displayAvgFactor) .';
        if isempty(channelData) || ~TileView.scanChansToShow(iChannel)
            continue;
        end
        contrast = single(contrastLimits{Tile.channels(iChannel)});
        scaledData = uint8(scaleChannelData(single(channelData), contrast, single(intmax('uint8'))));
        colorData = colorChannelData(scaledData, TileView.scanChanImageColors{iChannel});
        rescaledData = TileView.scanChanAlphas(iChannel) * colorData;
        imageData = imageData + rescaledData;
    end
end

function channelData = scaleChannelData(channelData, contrastLimit, maxPixelValue)
    channelData = (channelData - contrastLimit(1)) .* (maxPixelValue / diff(contrastLimit));
end

function channelData = colorChannelData(channelData, color)
    colorDimensions = color2RgbDimension(color);
    colorData = zeros([size(channelData), 3], class(channelData));
    channelData = repmat(channelData, 1, 1, length(colorDimensions));
    colorData(:,:,colorDimensions) = channelData;
    channelData = colorData;
end

function dimensionIndices = color2RgbDimension(color)
    switch color
        case 'grey'
            dimensionIndices = 1:3;
        case 'red'
            dimensionIndices = 1;
        case 'green'
            dimensionIndices = 2;
        case 'blue'
            dimensionIndices = 3;
        otherwise
            error('ScanImage:RoiGroupEditor:TileControls:UnsupportedColor', ...
                'Unexpected tile color %s encountered', color);
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

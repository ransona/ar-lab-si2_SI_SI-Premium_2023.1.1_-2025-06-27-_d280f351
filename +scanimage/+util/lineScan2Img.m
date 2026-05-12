[header, pmtData, scannerPosData, roiGroup] = scanimage.util.readLineScanDataFiles('file_00001');

ss = scanimage.mroi.scannerset.GalvoGalvo.default;
Fsc = header.SI.hScan2D.sampleRateCtl;

ss.scanners{1}.sampleRateHz = Fsc;
ss.scanners{2}.sampleRateHz = Fsc;
ss.beams.sampleRateHz = Fsc;
ss.fastz.sampleRateHz = Fsc;

[scanPath,~,~] = roiGroup.scanStackFOV(ss,0,0,'',0,'',[],false);

N = numel(scanPath.G(:,1));
Nt = header.samplesPerFrame;
scanPath.G = [interp1(linspace(0,1,N),scanPath.G(:,1),linspace(0,1,Nt)')...
                      interp1(linspace(0,1,N),scanPath.G(:,2),linspace(0,1,Nt)')];
scanPath.Z = interp1(linspace(0,1,N),scanPath.Z,linspace(0,1,Nt)');
scanPathN = Nt;
% hhhhhhhhhhhahsjhaskjlhdashdashdhasl;dhaslhdl;ashdl;ahsdjhaslkdjlkasdjl;kasjdlkajslkdjal;ksjdlkasjdlkjaslkdjasd
imgData = pmtData(:,2,1);
blankImg = nan(512,512);

xPosNominal = scannerPosData.G(:,1);
xPosResamp = scanPath.G(:,1);
yPosNominal = scannerPosData.G(:,2);
yPosResamp = scanPath.G(:,2);

angle2PixX = arrayfun(@(x) interp1([-20 20],[1 512],x), xPosResamp);
angle2PixY = arrayfun(@(x) interp1([-20 20],[1 512],x), yPosResamp);

% angle2PixX = arrayfun(@(x) interp1([min(xPosResamp) max(xPosResamp)],[1 512],x), xPosResamp);
% angle2PixY = arrayfun(@(x) interp1([min(yPosResamp) max(yPosResamp)],[1 512],x), yPosResamp);

inds = sub2ind([512 512], (round(angle2PixY)), (round(angle2PixX)));

blankImg(inds) = imgData(1:end);

figure();
imshow(blankImg, []);

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

function [dividerCombos012,dividerCombos34, ACounter, BCounter] = AD951XCalculator(desiredOutputFrequency_MHz,inputFrequency_MHz)
    %% Knowns
    VCODividers = 2:6;
    dividerRatios = 1:32;

    %% Find a suitable VCO Frequency
    thirdDivider = reshape(dividerRatios,1,1,length(dividerRatios));
    resultantDividers = VCODividers .* dividerRatios' .* thirdDivider;
    possibleVCOFrequencies_MHz = unique(desiredOutputFrequency_MHz .* resultantDividers);
    possibleVCOFrequencies_MHz = possibleVCOFrequencies_MHz(possibleVCOFrequencies_MHz > 2550);
    assert(~isempty(possibleVCOFrequencies_MHz),'There are no VCO Frequencies that will work');

    if any(possibleVCOFrequencies_MHz == 2560)
        VCOFrequency_MHz = 2560;
    else
        VCOFrequency_MHz = min(possibleVCOFrequencies_MHz,[],'all');
    end

    fprintf('Use VCO Frequency %g MHz\n',VCOFrequency_MHz);

    %% Find the A and B counters that give the VCO frequency
    remainder = mod(VCOFrequency_MHz,inputFrequency_MHz);
    assert(most.floatingpoint.fuzzyEquals(remainder,floor(remainder)),'The specified VCOFrequency cannot be recreated with the DM 32/33 Mode');
    BCounter = floor(VCOFrequency_MHz/(inputFrequency_MHz*32));
    ACounter = floor(remainder*inputFrequency_MHz);

    fprintf('Use ACounter = %g and BCounter = %g to get this VCO Frequency\n\n',ACounter,BCounter);

    %% Find the divider values that give the desired output frequency using just the VCO divider and a single additional divider (outputs 0,1,2,3,4, and 5 on AD9516-0)
    desiredDivider = VCOFrequency_MHz/desiredOutputFrequency_MHz;
    resultantDividers = VCODividers .* dividerRatios';

    [validResultantRows, validResultantColumns] = find(resultantDividers == desiredDivider);
    if~isempty(validResultantRows)
        VCODivider = VCODividers(validResultantColumns)';
        regularDivider = dividerRatios(validResultantRows);
        dividerCombos012 = [VCODivider regularDivider];
        disp('below are dividers that can work for outputs using divider 0, 1, or 2');
        table(VCODivider, regularDivider)
    else
        fprintf('There is no combination of dividers values that work for dividers 0,1, and 2 with VCOFrequency of %g\n',VCOFrequency_MHz);
        dividerCombos012 = nan;
    end

    %% Find the divider values that give the desired frequency using the VCO divider and two additional dividers (outputs 6,7,8, and 9 on AD9516-0)
    thirdDivider = reshape(dividerRatios,1,1,length(dividerRatios));
    resultantDividers = VCODividers .* dividerRatios' .* thirdDivider;
    [validResultantRows, validResultantColumns, validTHIRDDIMENSION] = ind2sub(size(resultantDividers),find(resultantDividers == desiredDivider));
    if~isempty(validResultantRows)
        VCODivider = VCODividers(validResultantColumns)';
        regularDivider1 = dividerRatios(validResultantRows);
        regularDivider2 = dividerRatios(validTHIRDDIMENSION);

        regularDivider1 = regularDivider1';
        regularDivider2 = regularDivider2';
        dividerCombos34 = [VCODivider,regularDivider1 ,regularDivider2];
        table(VCODivider, regularDivider1, regularDivider2)
    else
        fprintf('There is no combination of dividers values and VCO frequency that work for dividers 3 and 4\n');
        dividerCombos34 = nan;
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

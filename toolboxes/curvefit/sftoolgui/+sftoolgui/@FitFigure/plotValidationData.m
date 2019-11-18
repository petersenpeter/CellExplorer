function plotValidationData(hFitFigure)
%plotValidationData Plot FitFigure validation data lines
%
% plotValidationData(hFitFigure) plots hFitFigure validation data lines.

%   Copyright 2008-2011 The MathWorks, Inc.

hFitdev = hFitFigure.HFitdev;

previewValues =  sftoolgui.util.previewValues(hFitdev.ValidationData);

clearValidationDataLine(hFitFigure.HSurfacePanel);    
clearValidationDataLine(hFitFigure.HContourPanel);

% Plot the validation data if all specified data have the same number of
% elements.
if areNumSpecifiedElementsEqual(hFitdev.ValidationData)
    plotValidationLine(hFitFigure.HSurfacePanel, previewValues, hFitdev.ValidationData.Name);
    plotValidationLine(hFitFigure.HContourPanel, previewValues, hFitdev.ValidationData.Name);
    plotValidationData(hFitFigure.HResidualsPanel);
end

% Update legends
updateLegends(hFitFigure);
end


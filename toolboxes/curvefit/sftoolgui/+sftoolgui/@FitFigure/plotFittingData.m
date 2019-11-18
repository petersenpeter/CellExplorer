function plotFittingData(hFitFigure)
% plotFittingData Plot FitFigure fitting data lines
%
% plotFittingData(hFitFigure) plots hFitFigure fitting data lines.

%   Copyright 2008-2013 The MathWorks, Inc.

hFitdev = hFitFigure.HFitdev;

clearFittingDataLine(hFitFigure.HSurfacePanel);
clearFittingDataLine(hFitFigure.HContourPanel);

% Plot the fitting data if all specified data have the same number of
% elements.
if areNumSpecifiedElementsEqual(hFitdev.FittingData)
    plotDataLineWithExclusions(hFitFigure.HSurfacePanel);
    plotDataLineWithExclusions(hFitFigure.HContourPanel);
    plotDataLineWithExclusions(hFitFigure.HResidualsPanel);
end

% Update legends
updateLegends(hFitFigure);
end

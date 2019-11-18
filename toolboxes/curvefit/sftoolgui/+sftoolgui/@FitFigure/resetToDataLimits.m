function resetToDataLimits(hFitFigure)
% resetToDataLimits determines and sets AxesViewModel limit properties
%
% resetToDataLimits(hFitFigure) determines limits based on data and
% residuals and sets the AxesViewModel limit properties.

%   Copyright 2011-2015 The MathWorks, Inc.

hFitdev = hFitFigure.HFitdev;

% Get preview values for fitting data
fittingValues = sftoolgui.util.previewValues(hFitdev.FittingData);
% Get preview values for validation data
validationValues = sftoolgui.util.previewValues(hFitdev.ValidationData);

% Get the limits
xlim = iGetLimits(fittingValues{1}, validationValues{1});
ylim = iGetLimits(fittingValues{2}, validationValues{2});
zlim = iGetLimits(fittingValues{3}, validationValues{3});

% Get residual limits.
residualLim = getResidualLimits(hFitdev);

% Set limits.
if isCurveDataSpecified( hFitdev.FittingData )
    setLimits(hFitFigure.AxesViewModel, {xlim}, ylim, residualLim);
else
    setLimits(hFitFigure.AxesViewModel, {xlim, ylim}, zlim, residualLim);
end
end

function limits = iGetLimits(fittingValue, validationValue)
% iGetLimits gets limits using the "preview" rather than real data.
% "Preview" data contains zeros for undefined data values.

% Get limits on concatenated fitting and validation values.
limits = sftoolgui.util.getAxisLimitsFromData( [fittingValue; validationValue], 0.05 );
end


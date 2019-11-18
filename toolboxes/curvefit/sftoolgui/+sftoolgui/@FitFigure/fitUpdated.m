function fitUpdated( this )
% fitUpdated   FitFigure callback to Fitdev's FitUpdated event

%   Copyright 2008-2012 The MathWorks, Inc.

updateResultsArea(this);
if isFitted(this.HFitdev)
    this.AxesViewModel.ResidualLimits = getResidualLimits(this.HFitdev);
    plotFitAndResids(this);
else
    return;
end
end



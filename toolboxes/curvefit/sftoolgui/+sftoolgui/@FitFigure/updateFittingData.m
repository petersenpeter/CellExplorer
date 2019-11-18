function updateFittingData( this )
%updateFittingData updates plots and results when fitting data changes.
%
% updateFittingData also turns exclude mode off if data is not valid.

%   Copyright 2008-2011 The MathWorks, Inc.

updateInformationPanel(this);
resetToDataLimits(this);
plotFittingData(this);
% If fitting data is not valid, make sure exclusion mode is
% "off".
if ~isFittingDataValid(this.HFitdev)
    sftoolgui.sfExcludeMode(this, 'off');
end
end

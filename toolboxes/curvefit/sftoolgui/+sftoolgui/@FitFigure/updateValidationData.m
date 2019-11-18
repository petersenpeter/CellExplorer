function updateValidationData( this )
%updateValidationData updates plots and messages when validation data changes. 

%   Copyright 2008-2011 The MathWorks, Inc.

hFitdev = this.HFitdev;
updateValidationMessage(this.HFittingPanel, ...
    getMessageString(hFitdev.ValidationData), ...
    getMessageLevel(hFitdev.ValidationData));
resetToDataLimits(this);
plotValidationData(this);
updateResultsArea(this);
end

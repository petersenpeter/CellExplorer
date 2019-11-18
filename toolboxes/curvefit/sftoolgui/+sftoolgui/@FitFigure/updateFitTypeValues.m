function updateFitTypeValues ( this )
%updateFitTypeValues clears plots and updates results, information and
%legends.

%   Copyright 2008-2011 The MathWorks, Inc.

updateResults(this.HResultsPanel, ' ');
clearSurface(this.HSurfacePanel);
clearSurface(this.HContourPanel);
clearSurface(this.HResidualsPanel);
updateInformationPanel(this);
updateLegends(this);
end

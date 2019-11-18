function updateLegends(this)
%updateLegends Update all FitFigure plot panels' legends
%
%   updateLegends is called to update all FitFigure plot panels' legends

%   Copyright 2008-2009 The MathWorks, Inc.

updateLegend(this.HResidualsPanel, this.LegendOn);
updateLegend(this.HSurfacePanel, this.LegendOn);
updateLegend(this.HContourPanel, this.LegendOn);
end
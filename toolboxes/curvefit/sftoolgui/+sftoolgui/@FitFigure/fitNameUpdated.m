function this = fitNameUpdated( this )
%fitNameUpdated FitFigure callback to Fitdev's FitNameUpdated event

%   Copyright 2008-2009 The MathWorks, Inc.

set(this.Handle, 'Name', this.HFitdev.FitName);
updateDisplayNames(this.HResidualsPanel);
updateDisplayNames(this.HSurfacePanel);
updateDisplayNames(this.HContourPanel);
end
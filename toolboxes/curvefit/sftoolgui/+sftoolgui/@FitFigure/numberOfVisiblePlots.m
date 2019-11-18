function nVisiblePlots = numberOfVisiblePlots(this)
%numberOfVisiblePlots FitFigure utility
% 
%   numberOfVisiblePlots returns the number of plots whose Visible property
%   is on.

%   Copyright 2008-2009 The MathWorks, Inc.

nVisiblePlots = 0;
for i=1:length(this.PlotPanels)
    if strcmp(this.PlotPanels{i}.Visible, 'on')
        nVisiblePlots = nVisiblePlots + 1;
    end
end
end
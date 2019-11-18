function resize(this)
%resize Positions FitFigure subpanels
%
%   resize(FitFig) updates the position of the items within the
%   FitFigure.

%   Copyright 2008-2012 The MathWorks, Inc.

fig = this.Handle;

% Get the figure position
fpos = get(fig, 'Position');
figWidth = fpos(3);
figHeight = fpos(4);

% Position of the area that the plots will take up.  This is reduced if the
% fitting and/or results panel are visible
plotX = 1;
plotY = 1;
plotHeight = figHeight;
plotWidth = figWidth;
 
fittingVisible = strcmpi(this.HFittingPanel.Visible, 'on');
if fittingVisible
    % Fitting panel takes up a constant height that is determined by itself
    fittingPanelHeight = this.HFittingPanel.getPreferredHeight();
    fittingPanelHeight = max(1, fittingPanelHeight);
    fpPos = [1, ...
        figHeight - fittingPanelHeight + 1, ...
        max(1, figWidth), ...
        fittingPanelHeight];
    this.HFittingPanel.Position = fpPos;

    plotHeight = plotHeight - fittingPanelHeight;
end

resultsVisible = strcmpi(this.HResultsPanel.Visible, 'on');
if resultsVisible
    % Results panel takes up 2/7 of the figure width
    resultsWidth = floor(figWidth/3.5);
    this.HResultsPanel.Position = [1, 1, max(1, resultsWidth), max(1, plotHeight)];
    
    plotWidth = plotWidth - resultsWidth;
    plotX = resultsWidth + 1;
end

plotHeight = max(1, plotHeight);
plotWidth = max(1, plotWidth);

% Both the "No Data" and the "Plot" panel should take up the entire
% remaining space.
this.HNoDataPanel.Position = [plotX plotY plotWidth plotHeight];
this.HPlotPanel.Position = [plotX plotY plotWidth plotHeight];

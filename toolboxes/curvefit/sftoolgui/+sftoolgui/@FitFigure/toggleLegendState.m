function toggleLegendState(fitFigure, ~, ~)
%toggleLegendState Toggle legend state
%
%   toggleLegendState(fitFigure, SOURCE, EVENT) is the callback to the
%   Legend menu item and a toolbar button click.

%   Copyright 2008-2009 The MathWorks, Inc.

toggleProperty(fitFigure, 'LegendOn');
end
function toggleGridState(fitFigure, ~, ~)
%toggleGridState Toggle grid state
%
%   toggleGridState(fitFigure, SOURCE, EVENT) is the callback to Grid menu
%   item and toolbar button click.

%   Copyright 2008-2009 The MathWorks, Inc.

toggleProperty(fitFigure, 'GridState');
end
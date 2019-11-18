function updateGrids(fitFigure)
%updateGrids Update all FitFigure plot panels' grids  
%
%   updateGrids is called to update all FitFigure plot panels' grids

%   Copyright 2008-2009 The MathWorks, Inc.

updateGrid(fitFigure.HResidualsPanel);
updateGrid(fitFigure.HSurfacePanel);
updateGrid(fitFigure.HContourPanel);
end
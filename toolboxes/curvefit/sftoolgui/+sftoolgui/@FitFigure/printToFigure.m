function printToFigure( this, target )
% printToFigure   Print a Fit Figure to a MATLAB figure
%
%   printToFigure( aFitFigure, target ) "prints" the contents of a FitFigure to
%   the target (PrintToFigureTarget).
%
%   See also: curvefit.gui.PrintToFigureTarget

%   Copyright 2012 The MathWorks, Inc.

if isAnyDataSpecified( this.HFitdev )
    iPrintPlotPanels( this, target );
else
    printToFigure( this.HNoDataPanel, target );
end
end

function iPrintPlotPanels(this,target)
visiblePanels = iGetVisiblePanels(this);

switch length( visiblePanels )
    case 1
        iPrintOnePanel( target, visiblePanels );
    case 2
        iPrintTwoPanels( target, visiblePanels );
    case 3
        iPrintThreePanels( target, visiblePanels );
    otherwise
        warning( message( 'curvefit:sftoolgui:FitFigure:InvalidState' ) );
end
end

function visiblePanels = iGetVisiblePanels(this)
visiblePanels = {};

if strcmp( this.HSurfacePanel.Visible, 'on' );
    visiblePanels{1} = this.HSurfacePanel;
end
if strcmp( this.HResidualsPanel.Visible, 'on' );
    visiblePanels{end+1} = this.HResidualsPanel;
end
if strcmp( this.HContourPanel.Visible, 'on' );
    visiblePanels{end+1} = this.HContourPanel;
end
end

function iPrintOnePanel(target,visiblePanels)
printToFigure( visiblePanels{1}, target );
end

function iPrintTwoPanels(target,visiblePanels)
upperTarget = target.createSubTarget( [0, 0.5, 1, 0.5] );
printToFigure( visiblePanels{1}, upperTarget );

lowerTarget = target.createSubTarget( [0, 0, 1, 0.5] );
printToFigure( visiblePanels{2}, lowerTarget );
end

function iPrintThreePanels(target,visiblePanels)
upperTarget = target.createSubTarget( [0.5, 0.5, 0.5, 0.5] );
printToFigure( visiblePanels{1}, upperTarget );

lowerTarget = target.createSubTarget( [0.5, 0.0, 0.5, 0.5] );
printToFigure( visiblePanels{2}, lowerTarget );

leftTarget = target.createSubTarget( [0.0, 0.0, 0.5, 1.0] );
printToFigure( visiblePanels{3}, leftTarget );
end

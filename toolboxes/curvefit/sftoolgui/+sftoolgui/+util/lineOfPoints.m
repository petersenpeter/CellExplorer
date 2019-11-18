function aLine = lineOfPoints( parent, tag, markerStyle )
% lineOfPoints   A line of (unconnected) points.
%   A line of unconnected points is a line with LineStyle = 'none'.
%
%   sftoolgui.util.lineOfPoints( parent, tag, markerStyle ) is a line that
%   displays points.
%
%       parent      - the axes to draw the line in
%       tag         - a tag for the line
%       markerStyle - see MarkerStylist
%
%   See Also: sftoolgui.util.MarkerStylist.style

%   Copyright 2011-2013 The MathWorks, Inc.

% Create a line with LineStyle = 'none'.
aLine = line( ...
    'Parent', parent, ...
    'Tag', tag, ...
    'LineStyle', 'none', ...
    'XData', [], 'YData', [], 'ZData', [] );
curvefit.gui.setPickableParts(aLine, 'off');

% Set the marker style.
sftoolgui.util.MarkerStylist.style( aLine, markerStyle );

% Make the line "auto-legendable".
curvefit.gui.makeAutoLegendable( aLine );
end

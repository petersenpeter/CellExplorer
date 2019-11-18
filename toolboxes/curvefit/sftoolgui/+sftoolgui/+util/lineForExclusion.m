function theLine = lineForExclusion( parent, tag )
% lineForExclusion   A line that can be used to select points for inclusion or
% exclusion.
%
%   theLine = lineForExclusion( parent, tag ) 
%
%       parent -- the axes that is to draw the line in
%       tag -- a tag for the line

%   Copyright 2008-2013 The MathWorks, Inc.

theLine = line(...
    'Parent', parent, ...
    'XData', [], 'YData', [], 'ZData', [], ...
    'LineStyle', 'none', 'Marker', '+', 'MarkerSize', 1, 'Color', 'b', ...
    'Tag', tag );
curvefit.gui.setPickableParts(theLine, 'off');

% Don't (ever) show this artificial line in the legend
curvefit.gui.setLegendable( theLine, false );

end

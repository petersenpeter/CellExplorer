function zoomModeCallback(fitFigure, src, ~, inout)
%zoomModeCallback Zoom mode callback
%
%   zoomModeCallback(fitFigure, SRC, EVENT) is the callback to the zoom
%   menu item and toolbar button click.

%   Copyright 2011 The MathWorks, Inc.


if ishghandle(src, 'uimenu')
    if strcmpi(get(src, 'Checked'), 'on')
        newState = 'off';
    else
        newState = inout;
    end
elseif ishghandle(src, 'uitoggletool')
    newState = get(src, 'State');
    if ~strcmp(newState, 'off')
        newState = inout;
    end
else
    error(message('curvefit:sftoolgui:FitFigure:UnexpectedSourceType'));
end
sftoolgui.sfzoom3d(fitFigure, newState);

end

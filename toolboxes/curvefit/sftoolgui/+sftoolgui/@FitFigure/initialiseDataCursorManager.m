function initialiseDataCursorManager( this )
% initialiseDataCursorManager   Datatips mode requires a custom context
% menu so that the user cannot change the selection mode.  It is also here
% that we ensure that the selection mode does not snap to vertex

%   Copyright 2013 The MathWorks, Inc.

aFigure = this.Handle;
h = datacursormode(aFigure);

% Ensure that Data Cursor Mode uses our custom UIContextMenu
set(h, 'UIContextMenu', sftoolgui.util.dataCursorContextMenu(h));

% Ensure that the default data cursor mode is based on Mouse Position and
% will interpolate the point between vertices
set(h, 'SnapToDataVertex', 'off');
end
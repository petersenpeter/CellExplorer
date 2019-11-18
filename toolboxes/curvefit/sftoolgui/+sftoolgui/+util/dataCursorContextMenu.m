function contextMenu = dataCursorContextMenu(dataCursorManager)
% dataCursorContextMenu   Creates a context menu for the datatip mode
%
% The standard context menu for the datatip mode contains entries to set
% the selection style. This is not desired in CFTOOL. Thus, this is a
% replication of the standard context menu without the selection style
% entries.

%   Copyright 2013 The MathWorks, Inc.

% Main menu
properties.Parent = dataCursorManager.Figure;
properties.Serializable = 'on';
menuStructure.main = uicontextmenu(properties);
contextMenu = menuStructure.main;

% ViewStyle
properties = [];
properties.Parent = menuStructure.main;
properties.Label = getString(message('MATLAB:uistring:datacursor:MenuDisplayStyle'));
properties.Separator = 'off';
properties.Tag = 'DataCursorDisplayStyle';
menuStructure.dispStyle = uimenu(properties,'Checked','off');

properties = [];
properties.Parent = menuStructure.dispStyle;
properties.Label = getString(message('MATLAB:uistring:datacursor:MenuWindowInsideFigure'));
properties.Separator = 'off';
properties.Tag = 'DataCursorWindow';
properties.Callback = curvefit.gui.event.callback(@iDisplayStyleWindow);
menuStructure.displayStylePanel = uimenu(properties);

properties = [];
properties.Parent = menuStructure.dispStyle;
properties.Label = getString(message('MATLAB:uistring:datacursor:MenuDatatip'));
properties.Separator = 'off';
properties.Tag = 'DataCursorDatatip';
properties.Callback =  curvefit.gui.event.callback(@iDataTipStyle);
menuStructure.displayStyleDatatip = uimenu(properties);

% Datatip creation/deletion
properties = [];
properties.Parent = contextMenu;
properties.Label = getString(message('MATLAB:uistring:datacursor:MenuCreateNewDatatipShift'));
properties.Separator = 'on';
properties.Tag = 'DataCursorNewDatatip';
properties.Callback = curvefit.gui.event.callback(@iNewDataTip);
menuStructure.createDatatip = uimenu(properties);

properties.Parent = contextMenu;
properties.Label = getString(message('MATLAB:uistring:datacursor:MenuDeleteCurrentDatati'));
properties.Separator = 'off';
properties.Tag = 'DataCursorDeleteDatatip';
properties.Callback = curvefit.gui.event.callback(@iDeleteDataTip);
menuStructure.deleteDatatip = uimenu(properties);

properties.Parent = contextMenu;
properties.Label = getString(message('MATLAB:uistring:datacursor:MenuDeleteAllDatatips'));
properties.Separator = 'off';
properties.Tag = 'DataCursorDeleteAll';
properties.Callback = curvefit.gui.event.callback(@iDeleteAllDatatips);
menuStructure.deleteAllDatatips = uimenu(properties);

set(menuStructure.main, 'Callback', @(src, evt)iUpdateUIContextMenu(src, evt, menuStructure))
end

function iUpdateUIContextMenu(src, ~, menuStructure)
% iUpdateUIContextMenu   Callback to set up the context menu correctly when
% the menu is opened
dataCursorManager = iGetDataCursorManager(src);
displayStyle = dataCursorManager.DisplayStyle;

% Update all child menu "checked" property
if strcmpi(displayStyle,'window')
    menuStructure.displayStylePanel.Checked = 'on';
    menuStructure.displayStyleDatatip.Checked = 'off';
    menuStructure.createDatatip.Enable = 'off';
    menuStructure.deleteDatatip.Enable = 'off';
    menuStructure.deleteAllDatatips. Enable = 'off';
else
    menuStructure.displayStylePanel.Checked = 'off';
    menuStructure.displayStyleDatatip.Checked = 'on';
    menuStructure.createDatatip.Enable = 'on';
    menuStructure.deleteDatatip.Enable = 'on';
    menuStructure.deleteAllDatatips.Enable = 'on';
end
end

function iDataTipStyle(src, ~)
% iDataTipStyle   Callback to change to 'datatip' style
dataCursorManager = iGetDataCursorManager(src);
dataCursorManager.DisplayStyle = 'datatip';
dataCursorManager.Enable = 'on';
end

function iDisplayStyleWindow(src, ~)
% iDispStyleWindow   Callback to change to 'window' style
dataCursorManager = iGetDataCursorManager(src);
dataCursorManager.DisplayStyle = 'window';
end

function iDeleteDataTip(src, ~)
% iDeleteDataTip   Callback to delete the current datatip
dataCursorManager = iGetDataCursorManager(src);
currentDatatip = dataCursorManager.CurrentCursor;
if ~isempty(currentDatatip)
    removeDataCursor(dataCursorManager, currentDatatip);
end
end

function iDeleteAllDatatips(src, ~)
% iDeleteAllDatatips   Callback to delete all datatips
dataCursorManager = iGetDataCursorManager(src);
removeAllDataCursors(dataCursorManager);
end

function iNewDataTip(src, ~)
% iNewDataTip   Callback to create a new datatip
dataCursorManager = iGetDataCursorManager(src);
aFigure = dataCursorManager.Figure;
aMode = getuimode(aFigure,'Exploration.Datacursor');
aMode.ModeStateData.newCursor = true;
end

function dataCursorManager = iGetDataCursorManager(src, ~)
% iGetDataCursorManager   Helper function which grabs the handle to the
% datacursormanager. Sometimes the src is the context menu, sometimes the
% src is a DataCursorManager
dataCursorManager = datacursormode(ancestor(src, 'figure'));    
end

function createToolbar(fitFigure)
%createToolbar Create FitFigure toolbar
%
%   createToolbar - helper file to create a toolbar for FitFigures

%   Copyright 2009-2014 The MathWorks, Inc.

% Create the toolbar
hToolbar = uitoolbar('Parent', fitFigure.Handle);

% Create plot panel buttons
iCreatePlotPanelButtons(fitFigure, hToolbar);

% Create zoom in button
iCreateZoomInButton(fitFigure, hToolbar);

% Create zoom out button
iCreateZoomOutButton(fitFigure, hToolbar);

% Create pan button
iCreatePanButton(fitFigure, hToolbar);

% Create data cursor button
iCreateDataCursorButton(fitFigure, hToolbar);

% Create exclude button
iCreateExcludeButton(fitFigure, hToolbar);

% Create legend button
iCreateLegendButton(fitFigure, hToolbar);

% Create grid button
iCreateGridButton(fitFigure, hToolbar)

% Create axis limits dialog button
iCreateAxisLimitsDialogButton(fitFigure, hToolbar)

end

% Data Cursor toolbar button
function iCreateDataCursorButton(fitFigure, hToolbar)
dataCursorButton = uitoolfactory(hToolbar, 'Exploration.DataCursor');
set(dataCursorButton, 'TooltipString', getString(message('curvefit:sftoolgui:tooltip_DataCursor')));
iSetDataListener(fitFigure, dataCursorButton);
iEnableButton(fitFigure, dataCursorButton);

% add a listener which sets pickable parts to the appropriate value.
h = datacursormode(fitFigure.Handle);
h.addlistener('Enable', 'PostSet', @(src, evt)iDataCursorCallback(fitFigure.Handle, h));

end

function iDataCursorCallback(hFig, h)
% iDataCursorCallback   We have turned off pickable parts by default for
% all HG elements of the GUI.  We must therefore turn on pickable parts
% when the data cursor is enabled.  The parts of the graph that we want to
% pick are all lines and surfaces for the FitFigure
lines = findall(hFig, 'Type', 'line');
surfaces = findall(hFig, 'Type', 'surface');
pickableElements = [lines; surfaces];

% Is the data cursor being turned on or off
state = h.Enable;
curvefit.gui.setPickableParts(pickableElements, state);
end

% Zoom in toolbar button
function iCreateZoomInButton(fitFigure, hToolbar)
% Tag needs to match sfzoom3d designation
zoomInButton = uitoggletool(hToolbar, ...
    'TooltipString', getString(message('curvefit:sftoolgui:tooltip_ZoomIn')), ...
    'ClickedCallback', curvefit.gui.event.callback(@fitFigure.zoomModeCallback, 'in'), ...
    'Tag', 'exploration.zoom3din');
% Add a separator
set(zoomInButton, 'Separator', 'on');
iSetMatlabIcon(zoomInButton, 'tool_zoom_in.png');
iSetDataListener(fitFigure, zoomInButton);
iEnableButton(fitFigure, zoomInButton);
end

% Zoom out toolbar button
function iCreateZoomOutButton(fitFigure, hToolbar)
% Tag needs to match sfzoom3d designation
zoomOutButton = uitoggletool(hToolbar, ...
    'TooltipString', getString(message('curvefit:sftoolgui:tooltip_ZoomOut')), ...
    'ClickedCallback', curvefit.gui.event.callback(@fitFigure.zoomModeCallback, 'out'), ...
    'Tag', 'exploration.zoom3dout');
iSetMatlabIcon(zoomOutButton, 'tool_zoom_out.png');
iSetDataListener(fitFigure, zoomOutButton);
iEnableButton(fitFigure, zoomOutButton);
end

% Pan toolbar button
function iCreatePanButton(fitFigure, hToolbar)
% Tag needs to match sfpan3d designation
panButton = uitoggletool(hToolbar, ...
    'TooltipString', getString(message('curvefit:sftoolgui:tooltip_Pan')), ...
    'ClickedCallback', curvefit.gui.event.callback(@fitFigure.panModeCallback), ...
    'Tag', 'exploration.pan3d');
iSetMatlabIcon(panButton, 'tool_hand.png');
iSetDataListener(fitFigure, panButton);
iEnableButton(fitFigure, panButton);
end

% Exclude toolbar button
function iCreateExcludeButton(fitFigure, hToolbar)
excludeButton = uitoggletool(hToolbar, ...
    'TooltipString', getString(message('curvefit:sftoolgui:tooltip_ExcludeOutliers')), ...
    'ClickedCallback', curvefit.gui.event.callback(@fitFigure.excludeModeCallback), ...
    'Tag', 'sftoolExcludeOutliersToolbarButton');
sftoolgui.setIcon(excludeButton, sftoolgui.iconPath('excludeSMALL.png'));
% Create listeners
listeners = { curvefit.createListener(fitFigure.HFitdev, 'FittingDataUpdated', ...
    @(s, e)iUpdateExcludeToolbar(fitFigure, excludeButton)), ...
    curvefit.createListener(fitFigure.HFitdev, 'ValidationDataUpdated', ...
    @(s, e)iUpdateExcludeToolbar(fitFigure, excludeButton)) };
% Store the listeners in the button's UserData
set(excludeButton, 'UserData', listeners);

% Make sure button state is properly initialized
iUpdateExcludeToolbar(fitFigure, excludeButton);
end

function iUpdateExcludeToolbar(fitFigure, excludeButton)
% iUpdateExcludeToolbar enables/disables the exclude button depending of
% the validity of the Fitting data. It differs from other tool and view
% buttons that merely check for any data specified.

enable = sftoolgui.util.booleanToOnOff(isFittingDataValid(fitFigure.HFitdev));
set(excludeButton, 'Enable', enable);

end

% Plot panels toolbar buttons
function iCreatePlotPanelButtons(fitFigure, hToolbar)
% Set up array to store plot buttons
plotButtons = cell(length(fitFigure.PlotPanels), 1);
% Create a button for each plot panel
for i=1:length(fitFigure.PlotPanels)
    plotPanel = fitFigure.PlotPanels{i};
    plotButtons{i} = uitoggletool(hToolbar, ...
        'State', plotPanel.Visible, ...
        'TooltipString', plotPanel.Description,  ...
        'ClickedCallback', ...
        curvefit.gui.event.callback(@iTogglePlotPanelVisibility, fitFigure, plotPanel), ...
        'Tag', ['sftool' plotPanel.Tag 'ToolbarButton']);
    sftoolgui.setIcon(plotButtons{i}, sftoolgui.iconPath(plotPanel.Icon));
end

% Create listeners for PlotVisibilityStateChanged and *DataUpdated events
listeners = {curvefit.createListener(fitFigure, 'PlotVisibilityStateChanged', ...
    @(s, e) updatePlotControls(fitFigure, plotButtons, 'State')), ...
    curvefit.createListener(fitFigure.HFitdev, 'FittingDataUpdated', ...
    @(s, e) updatePlotControls(fitFigure, plotButtons, 'State')), ...
    curvefit.createListener(fitFigure.HFitdev, 'ValidationDataUpdated', ...
    @(s, e) updatePlotControls(fitFigure, plotButtons, 'State')) };

% Store listeners in the first button's user data
set(plotButtons{1}, 'UserData', listeners);

% Make sure button states are properly initialized
updatePlotControls(fitFigure, plotButtons, 'State');
end

function iTogglePlotPanelVisibility(src, ~, fitFigure, plotPanel)
%iTogglePlotPanelVisibility(src, event, fitFigure, plotPanel)
% togglePotPanelVisibility is called when a plot panel toolbar button is
% clicked.
newState = get(src, 'State');
plotPanel.Visible = newState;
if strcmpi(newState, 'on')
    if isa(plotPanel, 'sftoolgui.SurfacePanel')
        plotSurface(plotPanel);
    elseif isa(plotPanel, 'sftoolgui.ResidualsPanel')
        plotResiduals(plotPanel);
    elseif isa(plotPanel, 'sftoolgui.ContourPanel')
        plotSurface(plotPanel)
    end
end
notify(fitFigure, 'PlotVisibilityStateChanged');
notify(fitFigure, 'SessionChanged');
end

% Legend toolbar button
function iCreateLegendButton(fitFigure, hToolbar)
% Create our own legend button rather than using:
% "legend = uitoolfactory(hToolbar, 'Annotation.InsertLegend')"
% because we want the button to match the menu item which reflects (and
% sets) the "LegendOn" property.

legendButton = uitoggletool(hToolbar, ...
    'TooltipString', getString(message('curvefit:sftoolgui:tooltip_Legend')),  ...
    'ClickedCallback', curvefit.gui.event.callback(@fitFigure.toggleLegendState), ...
    'Tag', 'sftoolLegendToolbarButton', ...
    'Separator', 'on');
sftoolgui.setIcon(legendButton, sftoolgui.iconPath('tool_legend.png', 'matlab'));

% Create listeners for LegendStateChanged and *DataUpdated events
listeners = {curvefit.createListener(fitFigure, 'LegendStateChanged', ...
    @(s, e) iUpdateLegendToolbar(fitFigure, legendButton) ), ...
    curvefit.createListener(fitFigure.HFitdev, 'FittingDataUpdated', ...
    @(s, e) iUpdateLegendToolbar(fitFigure, legendButton) ), ...
    curvefit.createListener(fitFigure.HFitdev, 'ValidationDataUpdated', ...
    @(s, e) iUpdateLegendToolbar(fitFigure, legendButton) )};

% Store the listeners in button's UserData
set(legendButton, 'UserData', listeners)

% Make sure button states are properly initialized
iUpdateLegendToolbar(fitFigure, legendButton);
end

function iUpdateLegendToolbar(fitFigure, legendButton)
% iUpdateLegendToolbar sets the legend button's 'State' and 'Enable'
% properties.

% The legend button's Enable property should be 'on' if any data is
% specified.
enable = sftoolgui.util.booleanToOnOff(isAnyDataSpecified(fitFigure.HFitdev));

% The legend button's 'State' property ('on' = pressed down; 'off' = not
% pressed down) should be 'on' if any data is specified AND the FitFigure
% legendOn property is true. Otherwise it should be 'off'.
state = sftoolgui.util.booleanToOnOff(isAnyDataSpecified(fitFigure.HFitdev) && ...
    fitFigure.LegendOn);

set(legendButton, 'State', state, 'Enable', enable);
end

% Grid toolbar button
function iCreateGridButton(fitFigure, hToolbar)
% Toolbar button: grid
gridButton = uitoggletool(hToolbar, ...
    'State', fitFigure.GridState,...
    'TooltipString', getString(message('curvefit:sftoolgui:tooltip_Grid')),...
    'ClickedCallback', curvefit.gui.event.callback(@fitFigure.toggleGridState),...
    'Tag','sftoolGridToolbarButton');
sftoolgui.setIcon(gridButton, sftoolgui.iconPath('gridSMALL.png'));

% Create listeners for the GridStateChanged and *DataUpdated events
listeners = {curvefit.createListener(fitFigure, 'GridStateChanged', ...
    @(s, e) iUpdateGridToolbar(fitFigure, gridButton) ), ...
    curvefit.createListener(fitFigure.HFitdev, 'FittingDataUpdated', ...
    @(s, e)iUpdateGridToolbar(fitFigure, gridButton)), ...
    curvefit.createListener(fitFigure.HFitdev, 'ValidationDataUpdated', ...
    @(s, e)iUpdateGridToolbar(fitFigure, gridButton))};

% Store the listeners in the button's user data
set(gridButton, 'UserData', listeners);

% Make sure button states are properly initialized
iUpdateGridToolbar(fitFigure, gridButton)
end

function iUpdateGridToolbar(fitFigure, gridButton)
% iUpdateGridToolbar sets the Grid Button's 'Enable' and 'State'
% properties.

% The button should be enabled if any data is specified
enable = isAnyDataSpecified( fitFigure.HFitdev );

% The button should be pressed ('State' = 'on') if any data is specified
% AND the FitFigure's 'GridState' property is 'on'.
gridState = strcmpi( fitFigure.GridState, 'on' );
state = isAnyDataSpecified( fitFigure.HFitdev ) && gridState;

set(gridButton, ...
    'Enable', sftoolgui.util.booleanToOnOff( enable ), ...
    'State', sftoolgui.util.booleanToOnOff( state ) );
end

% Axis Limits Dialog toolbar button
function iCreateAxisLimitsDialogButton(fitFigure, hToolbar)
% Toolbar button: Axis limits dialog
% Note: unlike many of the other toolbar buttons, the axis limits button is
% NOT enabled/disabled depending on "no data selected". It should always be
% enabled. This is because the "axis limits" dialog is non-modal, so a user could
% open up the "axis limits" dialog and then remove all the data, which
% would disable the "axis limits" toolbar button, whilst the "axis limits" 
% dialog is still open. Also the axis limit dialog updates its ranges based 
% on the zoom, making it modal would remove this useful functionality.
axisButton = uipushtool(hToolbar, ...
    'TooltipString', getString(message('curvefit:sftoolgui:tooltip_AdjustAxesLimits')), ...
    'Separator','on',...
    'ClickedCallback', curvefit.gui.event.callback(@fitFigure.showAxisLimitsDialog), ...
    'Tag', 'sftoolAxisLimitsDialogToolbarButton');
sftoolgui.setIcon(axisButton, sftoolgui.iconPath('axisLimitDlg.png'));
end

function iSetDataListener(fitFigure, button)
% iSetDataListener creates listeners to '*DataUpdated' events and stores
% them in the button's UserData
listeners = { curvefit.createListener(fitFigure.HFitdev, 'FittingDataUpdated', ...
    @(s, e)iEnableButton(fitFigure, button)), ...
    curvefit.createListener(fitFigure.HFitdev, 'ValidationDataUpdated', ...
    @(s, e)iEnableButton(fitFigure, button)) };
set(button, 'UserData', listeners);
end

function iEnableButton(fitFigure, button)
% iEnableButton enables/disables a button depending on whether or not data
% has been specified

enable = sftoolgui.util.booleanToOnOff(isAnyDataSpecified(fitFigure.HFitdev));
set(button, 'Enable', enable);

end

function iSetMatlabIcon(button, filename)
% iSetMatlabIcon sets a button's CData with values found in a MATLAB icons
% file
ICONROOT = fullfile(toolboxdir('matlab'),'icons',filesep);
[cdata, ~, alpha] = imread([ICONROOT, filename],'Background','none');
% Converting 16-bit integer colors to MATLAB colorspec
cdata = double(cdata) / 65535.0;
% Set all transparent pixels to be transparent (nan)
cdata(alpha==0) = NaN;
set(button, 'CData', cdata);
end
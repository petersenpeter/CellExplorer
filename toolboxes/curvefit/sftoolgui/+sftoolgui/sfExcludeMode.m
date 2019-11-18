function sfExcludeMode(hFitFigure, state)
% SFEXCLUDEMODE - mode for Surface Fitting Tool exclusions

%   Copyright 2008-2014 The MathWorks, Inc.

hFig = hFitFigure.Handle;

% set up the mode
if ~hasuimode(hFig,'sftoolgui.sfExcludeMode')
    hMode = uimode(hFig,'sftoolgui.sfExcludeMode');
    set(hMode,'ModeStartFcn',{@localStartFcn, hMode, hFitFigure});
    set(hMode,'ModeStopFcn',{@localStopFcn, hMode});
    set(hMode,'WindowButtonDownFcn', curvefit.gui.event.callback( ...
        @localWindowButtonDownFcn, hFitFigure, hMode));
    set(hMode,'WindowButtonUpFcn',curvefit.gui.event.callback( ...
        @localWindowButtonUpFcn, hFitFigure, hMode));
    set(hMode,'WindowButtonMotionFcn',curvefit.gui.event.callback( ...
        @localMotionFcn, hMode, hFitFigure));
else
    hMode = getuimode(hFig,'sftoolgui.sfExcludeMode');
end

if strcmpi(state, 'on')
    activateuimode(hFig,'sftoolgui.sfExcludeMode');
else
    if isactiveuimode(hFig,'sftoolgui.sfExcludeMode')
        activateuimode(hFig,'');
    end
    localStopFcn(hMode);
end
end
%---------------------------------------------------------------------%
function localStartFcn(hMode, hFitFigure)
% Initialize the mode

hFig = hMode.FigureHandle;

% Find the menu
srcMenu = findall(hFig,'Tag','sftoolExcludeOutlierMenu');

% Add a check
set(srcMenu, 'Checked', 'on');

% Find the toolbar button
srcToolbarButton = findall(hFig,'Tag','sftoolExcludeOutliersToolbarButton');

% Indicate the button is selected
set(srcToolbarButton, 'State', 'on');

% change the pointer
set(hFig,'Pointer','crosshair');

% Create the contextmenu
hMode.UIContextMenu = uicontextmenu('Parent',hFig);
uimenu(hMode.UIContextMenu, 'Label', getString(message('curvefit:sftoolgui:ClearAllExclusions')), ...
    'Callback', curvefit.gui.event.callback(@clearAllExclusions, hFitFigure));
end
%---------------------------------------------------------------------%
function localStopFcn(hMode)
% Terminate the mode

% This is be called both when either users turn off Exclude outlier or
% select another mode.

hFig = hMode.FigureHandle;

% Find the menu
srcMenu = findall(hFig,'Tag','sftoolExcludeOutlierMenu');

% Remove the check
set(srcMenu, 'Checked', 'off');

% Find the toolbar button
srcToolbarButton = findall(hFig,'Tag','sftoolExcludeOutliersToolbarButton');

% Indicate the button is not selected
set(srcToolbarButton, 'State', 'off');

% (No need to explicitly change the pointer as in localStartFcn)

% Delete the context menu
hui = hMode.UIContextMenu;
if (~isempty(hui) && ishghandle(hui))
    delete(hui);
    hMode.UIContextMenu = '';
end
end
%---------------------------------------------------------------------%
function localWindowButtonDownFcn(hFig, evd, hFitFigure, hMode)
% localWindowButtonDownFcn(src, eventdata, hFitFigure, hMode)
% "Alt" SelectionType mean Ctrl-click left button or click right button
% If either of these cases, just return so that the context menu will
% show up.

hMode.ModeStateData.currentAxes = [];
hMode.ModeStateData.currentPanel = [];
hMode.ModeStateData.sftoolguiPointZero = [];

sel_type = get(hFig, 'SelectionType');
if strcmp(sel_type, 'alt')
    return;
end

if ~localInBounds(hFitFigure.HSurfacePanel) ...
        && ~localInBounds(hFitFigure.HContourPanel) ...
        && ~localInBounds(hFitFigure.HResidualsPanel)
    return;
else
    h = evd.HitObject;
    if isempty(h) || ~ishghandle(h)
        return
    end
end

ax = ancestor(h, 'axes');

% may be clicking in a legend for example
if isTargetAxes(ax, hFitFigure)
    hMode.ModeStateData.currentAxes = ax;
    hMode.ModeStateData.currentPanel = findCurrentPanel(hFitFigure, ax);
    % Save mouse position and start a rubber band operation
    hMode.ModeStateData.sftoolguiPointZero = get(ax, 'CurrentPoint');
    s3d = brushing.select3d(ax);
    hMode.ModeStateData.s3d = s3d;
end
end
%---------------------------------------------------------------------%
function validTarget = isTargetAxes(ax, fitFigure)

validTarget = false;
if ~isempty(ax) && (ax == fitFigure.HSurfacePanel.HAxes || ...
        ax == fitFigure.HContourPanel.HAxes || ...
        ax == fitFigure.HResidualsPanel.HAxes)
    validTarget = true;
end
end
%---------------------------------------------------------------------%
function localWindowButtonUpFcn(hFig, ~, hFitFigure, hMode)
% localWindowButtonUpFcn(src, eventdata, hFitFigure, hMode)
% "Alt" SelectionType mean Ctrl-click left button or click right button
% If either of these cases, just return so that the context menu will
% show up.
sel_type = get(hFig,'SelectionType');
if strcmp(sel_type,'alt')
    resetModeStateData(hMode);
    return;
end

ax = hMode.ModeStateData.currentAxes;
panel = hMode.ModeStateData.currentPanel;

% if button down occurred in the legend for instance, panel will be
% empty
if isempty(panel) || isempty(ax)
    resetModeStateData(hMode);
    return;
end

if (ax == hFitFigure.HSurfacePanel.HAxes)
    source = hFitFigure.HSurfacePanel.HFittingDataLine;
elseif (ax == hFitFigure.HResidualsPanel.HAxes)
    source = hFitFigure.HResidualsPanel.HResidualsLineForExclude;
elseif (ax == hFitFigure.HContourPanel.HAxes)
    source = [hFitFigure.HContourPanel.HFittingDataLine ...
        hFitFigure.HContourPanel.HFittingExclusionLine ...
        hFitFigure.HContourPanel.HFittingExclusionRuleLine];
else
    resetModeStateData(hMode);
    return;
end

pt0 = hMode.ModeStateData.sftoolguiPointZero;
% Get mouse position at button up
pt1 = get(ax, 'CurrentPoint');

% If there is only one point
if isequal(pt0, pt1) 
    % ... then use vertexpicker
    [~, ~, I] = vertexpicker( source, pt0 );
else
    % ... otherwise use region picker
    I = sftoolgui.util.regionPicker( hFig, hMode, source );
end
resetModeStateData(hMode);
toggleExclusion(hFitFigure.HFitdev, I);
end
%---------------------------------------------------------------------%
function resetModeStateData(hMode)
if isfield(hMode.ModeStateData, 's3d') && ...
        ~isempty(hMode.ModeStateData.s3d)
    s3d = hMode.ModeStateData.s3d;
    s3d.reset;
end
hMode.ModeStateData.s3d = [];
end
%---------------------------------------------------------------------%
function localMotionFcn(~, evt, hMode, hFitFigure)
% localMotionFcn(src, eventdata, hMode, hFitFigure)

hFig = hFitFigure.Handle;
% Get current point in figure units
curr_units = evt.Point;

set(hFig,'CurrentPoint',curr_units);

if isfield(hMode.ModeStateData, 's3d') && ~isempty(hMode.ModeStateData.s3d)
    setptr(hFig, 'crosshair');
    s3d = hMode.ModeStateData.s3d;
    s3d.draw(evt);
elseif isExcludeTarget(hFitFigure,evt)
    setptr(hFig, 'crosshair');
else
    setptr(hFig,'arrow');
    resetModeStateData(hMode);
end
end
%---------------------------------------------------------------------%
function bExcludeTarget = isExcludeTarget(hFitFigure,evt)
bExcludeTarget = false;
if (localInBounds(hFitFigure.HSurfacePanel) || ...
        localInBounds(hFitFigure.HResidualsPanel) ||...
        localInBounds(hFitFigure.HContourPanel))
    
    % Return all axes under the current mouse point
    allHit = ancestor(evt.HitObject, 'axes');
    allAxes = findobj(allHit,'flat','Type','Axes','HandleVisibility','on');
    % Make sure we are not over some non - sftool axes, such as the
    % legend.
    for i=1:length(allAxes),
        if ~isTargetAxes(allAxes(i), hFitFigure)
            return;
        end
    end
    
    bExcludeTarget = true;
end
end
%-----------------------------------------------%
function targetInBounds = localInBounds(panel)
if strcmpi(panel.Visible, 'off')
    targetInBounds = false;
    return;
end

hAxes = panel.HAxes;
%Check if the user clicked within the bounds of the axes. If not, do
%nothing.
targetInBounds = true;
% We used to set tol to a small value (which was actually not small
% enough in some cases). Keeping the tol variable here for now in case
% we decide to allow a tolerance. (If we do, we need to assign it based
% on actual values of limits).
tol = 0;
cp = get(hAxes,'CurrentPoint');
XLims = get(hAxes,'XLim');
if ((cp(1,1) - min(XLims)) < -tol || (cp(1,1) - max(XLims)) > tol) && ...
        ((cp(2,1) - min(XLims)) < -tol || (cp(2,1) - max(XLims)) > tol)
    targetInBounds = false;
end
YLims = get(hAxes,'YLim');
if ((cp(1,2) - min(YLims)) < -tol || (cp(1,2) - max(YLims)) > tol) && ...
        ((cp(2,2) - min(YLims)) < -tol || (cp(2,2) - max(YLims)) > tol)
    targetInBounds = false;
end
ZLims = get(hAxes,'ZLim');
if ((cp(1,3) - min(ZLims)) < -tol || (cp(1,3) - max(ZLims)) > tol) && ...
        ((cp(2,3) - min(ZLims)) < -tol || (cp(2,3) - max(ZLims)) > tol)
    targetInBounds = false;
end
end
%---------------------------------------------------------------------%
function clearAllExclusions(~, ~, hFitFigure)
% clearAllExclusions(src, eventdata, hFitFigure)
clearExclusions(hFitFigure.HFitdev);
end
%---------------------------------------------------------------------%
function panel = findCurrentPanel(hFitFigure, ax)
if (ax == hFitFigure.HSurfacePanel.HAxes)
    panel =  hFitFigure.HSurfacePanel;
elseif (ax == hFitFigure.HResidualsPanel.HAxes)
    panel = hFitFigure.HResidualsPanel;
elseif (ax == hFitFigure.HContourPanel.HAxes)
    panel = hFitFigure.HContourPanel;
else
    panel = [];
end
end

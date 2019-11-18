function sfpan3d(fitFigure,state)
% SFPAN3D Mode for panning with axes limits.

%   Copyright 2011-2013 The MathWorks, Inc.

hFig = fitFigure.Handle;
if ~hasuimode(hFig,'exploration.pan3d')
    dMode = uimode(hFig,'exploration.pan3d');
    set(dMode,'ModeStartFcn',{@localStartFcn,dMode});
    set(dMode,'ModeStopFcn',{@localStopFcn,dMode});
    set(dMode,'WindowButtonDownFcn', curvefit.gui.event.callback( ...
        @localWindowButtonDownFcn,dMode));
    set(dMode,'WindowButtonMotionFcn', curvefit.gui.event.callback( ...
        @localWindowButtonMotionFcn,dMode));
    set(dMode,'WindowButtonUpFcn',[]);
    
     % Add the 'Reset to Original Limits' context menu.
    dMode.UIContextMenu = uicontextmenu('Parent',hFig);
    uimenu('Parent',dMode.UIContextMenu,'Label',getString(message('curvefit:sftoolgui:ResetToOriginalLimits')),...
        'Tag', 'sftoolPanZoomResetView', ...
        'Callback', curvefit.gui.event.callback(@localAxesReset, dMode));
    set(dMode,'UIContextMenu',dMode.UIContextMenu);
end

if strcmpi(state,'off')
    if isactiveuimode(hFig,'exploration.pan3d')
        activateuimode(hFig,'');
    end
else
    activateuimode(hFig,'exploration.pan3d');
    dMode.ModeStateData.FitFigure = fitFigure;
    dMode.ModeStateData.Axes = [];
end

% Store the FitFigure object in the ModeStateData so that the axes limit
% listeners which redraw the FunctionSurface can be suspended
% during a pan gesture.
dMode.ModeStateData.FitFigure = fitFigure;

% Initialize the mousedown state
dMode.ModeStateData.CurrentAxes = [];
dMode.ModeStateData.mousedown = false;

%---------------------------------------------------------------------%
function localStartFcn(dMode)
% Initialize the mode
hFig = dMode.FigureHandle;

hToggle = findall(hFig,'Tag','exploration.pan3d');
hMenu = findall(hFig,'Tag','exploration.pan3dMenu');
if ~isempty(hToggle)
    set(hToggle,'State','on');
end
if ~isempty(hMenu)
    set(hMenu,'Checked','on');
end

%---------------------------------------------------------------------%
function localStopFcn(dMode)

hFig = dMode.FigureHandle;
hToggle = findall(hFig,'Tag','exploration.pan3d');
hMenu = findall(hFig,'Tag','exploration.pan3dMenu');
if ~isempty(hToggle)
    set(hToggle,'State','off');
end
if ~isempty(hMenu)
    set(hMenu,'Checked','off');
end

% Note that the figure Pointer & PointerShapeCData properties will be 
% restored to values that were cached when the localStartFcn by the
% uimode.mModeController localRecoverFigure

%---------------------------------------------------------------------%
function localWindowButtonDownFcn(hFig,evd,dMode)

% Ignore right clicks.
if strcmp(hFig.SelectionType,'alt')
    return
end

ax = ancestor(evd.HitObject, 'axes');
if isempty(ax)
    return
end
ax = ax(1);

if strcmp(hFig.SelectionType,'open')
    localAxesReset([],[],dMode);
    set(dMode,'WindowButtonUpFcn',[]);
    return
end
setptr(hFig,'closedhand');
dMode.ModeStateData.mousedown = true;
dMode.ModeStateData.CurrentAxes = ax;
dMode.ModeStateData.AxesMarkedClean = true;
dMode.ModeStateData.CurrentAxesMarkedCleanListener = curvefit.createListener( ...
    ax, 'MarkedClean', @(es,ed) localMarkAxesClean(es,dMode));
dMode.ModeStateData.LastPoint = ax.CurrentPoint;


% During the pan gesture, suspend the FitFigure object axes limit listeners
% which redraw the FunctionSurface and ContourSurface.
dMode.ModeStateData.FitFigure.HSurfacePanel.HSurfacePlot.setAxesLimitListenersEnabled(false);
dMode.ModeStateData.FitFigure.HContourPanel.HContours.setAxesLimitListenersEnabled(false);

set(dMode,'WindowButtonUpFcn', curvefit.gui.event.callback(@localWindowButtonUpFcn,dMode));

%---------------------------------------------------------------------%
function localWindowButtonUpFcn(hFig,evd,dMode)

ax = ancestor(evd.HitObject, 'axes');

% If exiting from a pan, reset the mouse pointer to open-hand
if isequal(ax,dMode.ModeStateData.CurrentAxes)
    if dMode.ModeStateData.mousedown
        setptr(hFig,'hand');
    else
        setptr(hFig,'arrow');
    end
elseif isempty(ax)
    ax = dMode.ModeStateData.CurrentAxes;
    setptr(hFig,'arrow');
end

if isempty(ax)
    return
end
if strcmp(hFig.SelectionType,'open')
    return
end
if ~isfield(dMode.ModeStateData,'LastPoint') || isempty(dMode.ModeStateData.LastPoint)
    return
end
if ~isfield(dMode.ModeStateData,'CurrentAxes') || isempty(dMode.ModeStateData.CurrentAxes)
    return
end

% Find the perpendicular connecting rays p1 and p2.
p2 = ax.CurrentPoint;
p1 = dMode.ModeStateData.LastPoint;
v = iFindPerpendicular(p1, p2);

dMode.ModeStateData.AxesMarkedClean = false;

% Restore the FitFigure object axes limit listeners which redraw the
% FunctionSurface and ContourSurface.
dMode.ModeStateData.FitFigure.HSurfacePanel.HSurfacePlot.setAxesLimitListenersEnabled(true);
dMode.ModeStateData.FitFigure.HContourPanel.HContours.setAxesLimitListenersEnabled(true);

if ~any(isnan(v(:))) && isprop(ax, 'RequestedLimits')
    % Set the dynamic axes property "RequestedLimits".
    ax.RequestedLimits = {iAdjustLim(ax.XLim-v(1)),  iAdjustLim(ax.YLim-v(2)), iAdjustLim(ax.ZLim-v(3))};
end

% Reset mode state
dMode.ModeStateData.LastPoint = [];
dMode.ModeStateData.CurrentAxesMarkedCleanListener = [];
dMode.ModeStateData.mousedown = false;
set(dMode,'WindowButtonUpFcn',[]);

function localWindowButtonMotionFcn(hFig,evd,dMode)

ax = ancestor(evd.HitObject, 'axes');

if ~isempty(ax) 
    if ~dMode.ModeStateData.mousedown
        setptr(hFig,'hand');
    else
        setptr(hFig,'closedhand');
    end
else
    ax = dMode.ModeStateData.CurrentAxes;
    setptr(hFig,'arrow');
end


if ~isfield(dMode.ModeStateData,'CurrentAxes') || ~isequal(ax,dMode.ModeStateData.CurrentAxes)
    return
end

if ~isfield(dMode.ModeStateData,'LastPoint') || isempty(dMode.ModeStateData.LastPoint)
    return
end
if isfield(dMode.ModeStateData,'AxesMarkedClean') && ~dMode.ModeStateData.AxesMarkedClean
    return
end

p2 = specgraphhelper('convertViewerCoordsToDataSpaceCoords', ax,...
    localConvertFigToViewer(ax,evd.Point),true)';
p1 = dMode.ModeStateData.LastPoint;
v = iFindPerpendicular(p1, p2);
dMode.ModeStateData.AxesMarkedClean = false;
if ~any(isnan(v(:))) && isprop(ax, 'RequestedLimits')
        % Set the dynamic axes property "RequestedLimits".
    ax.RequestedLimits = {iAdjustLim(ax.XLim-v(1)),  iAdjustLim(ax.YLim-v(2)), iAdjustLim(ax.ZLim-v(3))};
end
drawnow; % Needed to stop motion events queuing

function localMarkAxesClean(ax,dMode)

if isfield(dMode.ModeStateData,'CurrentAxes') && isequal(dMode.ModeStateData.CurrentAxes,ax)
    dMode.ModeStateData.AxesMarkedClean = true;
end

function viewerPt = localConvertFigToViewer(ax,pt)

panelParent = ancestor(ax,'uicontainer');
if ~isempty(panelParent)
    
    panelParentPosition = getpixelposition(panelParent,true);
    if size(pt,1)==1 % Single row ordered pair
        viewerPt = pt-panelParentPosition(1:2);
    else % Column vectors of ordered pairs
        viewerPt = pt+panelParentPosition(1:2)'*ones(1,size(pt,2));
    end
else
    viewerPt = pt;
end

function v = iFindPerpendicular(p1, p2)
denom = (p2(2,:)-p2(1,:))*((p1(2,:)-p1(1,:))');
if abs(denom) < eps(denom)
    lambda = 0;
else
    lambda = (p1(1,:)-p2(1,:))*((p1(2,:)-p1(1,:))')/denom;
end
v = (p2(1,:)-p1(1,:))+(p2(2,:)-p2(1,:))*lambda;

function localAxesReset(~,~,dMode)

fig = dMode.ModeStateData.FitFigure.Handle;
set(dMode,'WindowButtonMotionFcn','');
cachedMousePointer = getptr(fig);
setptr(fig,'watch');
drawnow update % Make sure the mouse pointer displays
dMode.ModeStateData.FitFigure.resetToDataLimits();
set(fig,cachedMousePointer{:});
set(dMode,'WindowButtonMotionFcn',curvefit.gui.event.callback(@localWindowButtonMotionFcn,dMode));

function lim = iAdjustLim(lim)
% iAdjustLim ensures that lim(1) is less than lim(2) but the difference is
% at least the minimum that axes will render 

sumLim = sum(abs(lim));
if sumLim == 0
    delta = 1e-10;
else
    delta = 1e-10*( sumLim ); 
end
if diff(lim) <= delta
   % ... then, adjust them to ensure that lim(1) is less than lim(2)
   % Find them mean of lim(1) and lim(2) and add -eps and +eps
   % respectively.
   meanLim = mean(lim);
   lim = [meanLim-delta, meanLim+delta];
end



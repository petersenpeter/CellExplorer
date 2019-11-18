function hui = rotate3dContextMenu( rotaObj )
%ROTATE3DCONTEXTMENU Creates a context menu for the rotate3d mode
%   The standard context menu for the rotate3d mode contains entries to set
%   the aspect ratio. This is not desired in CFTOOL. Thus,
%   this is a replication of the standard context menu without the aspect
%   ratio entries.

%   Copyright 2013 The MathWorks, Inc.

hui = uicontextmenu('Parent',rotaObj.FigureHandle, 'Tag', 'cftoolRotate3dMenu');

props = [];
props.Label = getString(message('MATLAB:uistring:rotate3d:Reset'));
props.Parent = hui;
props.Separator = 'off';
props.Tag = 'sftoolRotate3dResetView';
props.Callback = {@localUIContextMenuCallback,rotaObj};
uimenu(props);

props = [];
props.Label = getString(message('MATLAB:uistring:rotate3d:SnapToXY'));
props.Parent = hui;
props.Tag = 'SnapToXY';
props.Separator = 'on';
props.Callback = {@localUIContextMenuCallback,rotaObj};
uimenu(props);

props = [];
props.Label = getString(message('MATLAB:uistring:rotate3d:SnapToXZ'));
props.Parent = hui;
props.Tag = 'SnapToXZ';
props.Separator = 'off';
props.Callback = {@localUIContextMenuCallback,rotaObj};
uimenu(props);

props = [];
props.Label = getString(message('MATLAB:uistring:rotate3d:SnapToYZ'));
props.Parent = hui;
props.Tag = 'SnapToYZ';
props.Separator = 'off';
props.Callback = {@localUIContextMenuCallback,rotaObj};
uimenu(props);

props = [];
props.Label = getString(message('MATLAB:uistring:rotate3d:Rotate_Options'));
props.Parent = hui;
props.Separator = 'on';
props.Callback = '';
props.Tag = 'Rotate_Options';
u2 = uimenu(props);

props = [];
props.Label = getString(message('MATLAB:uistring:rotate3d:Rotate_Fast'));
props.Parent = u2;
props.Separator = 'off';
props.Checked = 'off';
props.Tag = 'Rotate_Fast';
p(1) = uimenu(props);

props = [];
props.Label = getString(message('MATLAB:uistring:rotate3d:Rotate_Continuous'));
props.Parent = u2;
props.Separator = 'off';
props.Checked = 'on';
props.Tag = 'Rotate_Continuous';
p(2) = uimenu(props);

set(p(1:2),'Callback',{@localSwitchRotateStyle,rotaObj});
end

%--------------------------------------------------------------------%
function localUIContextMenuCallback(obj,~,rotaObj)

% Get axes handle
hFig = rotaObj.FigureHandle;
% If we are here, then we clicked on something contained in an
% axes. Rather than calling HITTEST, we will get this information
% manually.
hAxes = ancestor(rotaObj.FigureHandle,'axes');
if isempty(hAxes)
    hAxes = get(hFig,'CurrentAxes');
    if isempty(hAxes)
        return;
    end
end

switch get(obj,'Tag')
    case 'sftoolRotate3dResetView';
        % Reset the number of buttons down
        resetplotview(localVectorizeAxes(hAxes),'ApplyStoredView');
    case 'SnapToXY';
        view(hAxes,0,90);
    case 'SnapToXZ';
        view(hAxes,0,0);
    case 'SnapToYZ';
        view(hAxes,90,0);
end
end

%--------------------------------------------------------------------%
function axList = localVectorizeAxes(hAx)
% Given an axes, return a vector representing any plotyy-dependent axes.
% Note: This code is implementation-specific and meant as a place-holder
% against the time when we have multiple data-spaces in one axes.

axList = hAx;
if ~isempty(axList)
    if isappdata(hAx,'graphicsPlotyyPeer')
        newAx = getappdata(hAx,'graphicsPlotyyPeer');
        if ishghandle(newAx)
            axList = [axList;newAx];
        end
    end
end
end

%--------------------------------------------------------------------%
function localSwitchRotateStyle(obj,~,rotaObj) 
% Switch rotate style

tag = get(obj,'Tag');

% Radio buttons
if strcmp(tag,'Rotate_Continuous')
    set(rotaObj,'RotateStyle','orbit');
elseif strcmp(tag,'Rotate_Fast')
    set(rotaObj,'RotateStyle','box');
end
end




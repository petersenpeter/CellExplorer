function L = createListener(src, event, callback)
%createListener Create a new listener
%
%  L = createListener(src, event, callback) creates a listener on the
%  specified event of the src object, array of objects or cell array of
%  objects.
%
%  If event is a property name in src then a listener will be created on
%  the PostSet event of that property.
%
%  The callback may be either a function handle or a cell array that
%  contains a function handle and additional arguments.
%
%  This factory method will automatically choose the type of listener to
%  create based on the src and event, switching between MCOS and legacy
%  listeners and also between synchronous and queued callbacks.  Queued
%  callbacks are chosen when the event appears to be one that is the
%  direct result of a user action.
%
%  See also: curvefit.ListenerTarget, curvefit.Handle

%   Copyright 2012 The MathWorks, Inc.

if iIsGUIEvent(src, event)
    % Create a listener that queues the callback
    L = iCreateGUIListener(src, event, callback);
else
    % Create a listener that immediately executes the callback
    L = iCreateListener(src, event, callback);
end


function L = iCreateListener(src, eventname, callback)
%iCreateListener Create an MCOS listener on either an event or a property.

% Create appropriate listener
IsProp = iIsProp(src, eventname);
if IsProp
    L = curvefit.proplistener(src, eventname, callback);
else
    L = curvefit.listener(src, eventname, callback);
end


function L = iCreateGUIListener(src, eventname, callback)
%iCreateGUIListener Create a listener on a GUI interface event or property

if iIsProp(src, eventname)
    L = curvefit.gui.event.proplistener(src, eventname, callback);
else
    L = curvefit.gui.event.listener(src, eventname, callback);
end


function ret = iIsProp(src, propname)
%iIsProp Check whether a string is a property name

if iscell(src)
    % Use object in first cell to find source property object
    propCheckObj = src{1};
else
    % Use first object in array to find source property object
    propCheckObj = src(1);
end

ret = isprop(propCheckObj, propname);


function ret = iIsGUIEvent(src, event)
% Decide whether a src/event combination is a GUI input source event or
% not.

% First rule: all events on curvefit.Handle objects are non-GUI
if iscell(src)
    % Use object in first cell to determine type of listener
    srcTypeCheckObj = src{1};
else
    % Use first object in array to determine type of listener
    srcTypeCheckObj = src(1);
end
ret = ~isa(srcTypeCheckObj, 'curvefit.Handle');

% Second rule: filter HG events that are not caused by an interactive action
EventsToFilter = {'ObjectBeingDestroyed', 'MarkedClean', 'MarkedDirty'};
ret = ret && ~any(strcmp(event,  EventsToFilter));

% Third rule: property events are non-GUI
ret = ret && ~iIsProp(srcTypeCheckObj, event);

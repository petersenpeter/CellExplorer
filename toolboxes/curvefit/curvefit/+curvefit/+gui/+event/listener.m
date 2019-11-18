function listener = listener(obj, eventname, callback)
%LISTENER Create a listener on an event
%
%   L = LISTENER(obj, eventName, callback) creates a listener on a graphics
%   object.  The eventName should always be for the contemporary version of
%   the event, and will be mapped to legacy events automatically.  If obj
%   is a Java object, the callback will be passed the raw Java event data.
%
%   Examples: 
%
%   (1) If the handle object h holds a surface and should be deleted when
%   the surface is, then a listener can be set up like this:
%
%       h.Listener = curvefit.gui.event.listener( h.Surface, ...
%           'ObjectBeingDestroyed', @h.deleteCallback ) 
%
%   (2) To listen to resize events on a uipanel, a listener can be created
%   on 'SizeChanged', no matter which version of the panel is used:
%       
%       h.Listener = curvefit.gui.event.listener( uipanel, ...
%           'SizeChanged', @h.resize ) 
%
%   The callback will automatically be queued in the shared GUI EventQueue.
%
%   See also: curvefit.gui.event.EventQueue

%   Copyright 2008-2011 The MathWorks, Inc.

% Support both a function handle and cell-array style callbacks.
if ~iscell(callback)
    callback = {callback};
end

% Convert function handle to a queuing callback
queuedCallback = curvefit.gui.event.callback(callback{:});

% Use interruptListener to implement switch between listener types
listener = curvefit.gui.event.interruptListener(obj, eventname, queuedCallback);

function listener = interruptListener(obj, eventname, callback)
%INTERRUPTLISTENER Create a listener that will interrupt other listeners
%
%   L = INTERRUPTLISTENER(obj, eventName, callback) creates a listener on a
%   graphics object.  The eventName should always be for the contemporary
%   version of the event, and will be mapped to legacy events
%   automatically.  Listeners created using this function will not queue
%   their callbacks in the shared EventQueue: they will immediately
%   interrupt and execute.
%
%   Examples: 
%
%   (1) If the handle object h holds a surface and should be deleted when
%   the surface is, then a listener can be set up like this:
%
%       h.Listener = curvefit.gui.event.interruptListener( h.Surface, ...
%           'ObjectBeingDestroyed', @h.deleteCallback ) 
%
%   (2) To listen to resize events on a uipanel, a listener can be created
%   on 'SizeChanged', no matter which version of the panel is used:
%       
%       h.Listener = curvefit.gui.event.interruptListener( uipanel, ...
%           'SizeChanged', @h.resize ) 

%   Copyright 2011-2012 The MathWorks, Inc.

listener = curvefit.listener(obj, eventname, callback);

% Ensure that GUI listeners allow recursion, so that we get a chance to
% queue them.
makeRecursive(listener);

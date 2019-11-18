function listener = proplistener(obj, propname, callback)
%PROPLISTENER  Listener object for property PropertyPostSet events 
%
%   L = PROPLISTENER(obj, propertyName, callback)
%
%   Example:
%   If the handle object h needs to redraw when some axes have their x-limits
%   changed the listener may be created as follows.
%
%       h.Listener = curvefit.gui.event.proplistener( hAxes, 'XLim', @h.redraw )
%
%   The callback will automatically be queued in the shared GUI EventQueue.
%
%   Note:
%   This function only creates listeners for property post-set events.
%
%   See also: curvefit.gui.event.EventQueue

%   Copyright 2008-2012 The MathWorks, Inc.

% Support both a function handle and cell-array style callbacks.
if ~iscell(callback)
    callback = {callback};
end

% Convert function handle to a queuing callback
queuedCallback = curvefit.gui.event.callback(callback{:});

listener = curvefit.proplistener(obj, propname, queuedCallback);

% Ensure that GUI listeners allow recursion, so that we get a chance to
% queue them.
makeRecursive(listener);

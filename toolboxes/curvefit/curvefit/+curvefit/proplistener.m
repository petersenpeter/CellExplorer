function listener = proplistener(Source, PropName, Callback)
%PROPLISTENER  Listener object for property PropertyPostSet events 
%
%   L = PROPLISTENER(obj, propertyName, callback)
%
%   Example:
%   If the handle object h needs to redraw when some axes have their x-limits
%   changed the listener may be created as follows.
%
%       h.Listener = curvefit.proplistener( hAxes, 'XLim', @h.redraw )
%
%   Note:
%   This function only creates listeners for property post-set events.

%   Copyright 2008-2012 The MathWorks, Inc.

persistent Factory
if isempty(Factory)   
    Factory = struct(...
        'Java', @iJavaError, ...
        'Legacy', @iCreateHandleListener, ...
        'Matlab', @iCreateEventListener);
end

listener = makeListener(Factory, Source, PropName, Callback);


function listener = iCreateHandleListener(Source, PropName, Callback)
% Find property on the first object
property = findprop( Source(1), PropName );
% Make listener
listener = handle.listener( Source, property, 'PropertyPostSet', Callback );


function listener = iCreateEventListener(Source, PropName, Callback)
% Event listeners may be created on cells or arrays, so we have to handle
% both.
if iscell(Source)
    property = findprop(Source{1}, PropName);
else
    property = findprop(Source(1), PropName);
end
listener = event.proplistener( Source, property, 'PostSet', Callback );
    

function listener = iJavaError(~, ~, ~)
% Property listeners on Java handles are unreliable - they only fire if the
% property is actually set through the Matlab object interface.  Throwing
% an error here prevents them being accidentally used.
listener = [];
error(message('curvefit:curvefit:proplistener:JavaPropertyListener'));

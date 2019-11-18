function listener = listener(Source, Event, Callback)
%LISTENER Create a listener on an event
%
%   L = LISTENER(obj, eventName, callback) creates a non-queuing listener
%   on an object.  The eventName should always be for the contemporary
%   version of the event, and will be mapped to legacy events
%   automatically.  The source object may be either a scalar object, an
%   array of objects or a cell array of objects.
%
%   In most cases, listeners should be created via the createListener
%   function rather than by directly calling this function.
%
%   Examples: 
%
%   (1) If the handle object h holds a surface and should be deleted when
%   the surface is, then a listener can be set up like this:
%
%       h.Listener = curvefit.listener( h.Surface, 'ObjectBeingDestroyed', ...
%           @h.deleteCallback ) 
%
%   (2) To listen to resize events on a uipanel, a listener can be created
%   on 'SizeChanged', no matter which version of the panel is used:
%       
%       h.Listener = curvefit.listener( uipanel, 'SizeChanged', @h.resize ) 

%   Copyright 2008-2012 The MathWorks, Inc.

persistent Factory
if isempty(Factory)
    Factory = struct(...
        'Java', @iCreateJavaListener, ...
        'Legacy', @iCreateHandleListener, ...
        'Matlab', @event.listener);
end

listener = makeListener(Factory, Source, Event, Callback);
end


function listener = iCreateHandleListener(Source, Event, Callback)
    % Translate event names to original HG names
    switch Event
        case 'SizeChanged'
            Event = 'ResizeEvent';
        otherwise
            % No name change is required
    end
    
    % Create a legacy listener
    listener = handle.listener( Source, Event, Callback );
end


function listener = iCreateJavaListener(Source, Event, Callback)
    listener = handle.listener( Source, Event, iJavaCallback(Callback));
end

function javaCallback = iJavaCallback(originalCallback)
    % Return handle to nested function
    javaCallback = @evalCallback;
    
    function evalCallback(src, evt)
        originalCallback(src, evt.JavaEvent);
    end
end

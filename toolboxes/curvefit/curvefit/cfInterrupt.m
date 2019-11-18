function stop = cfInterrupt(action, stop)
%cfInterrupt   Interrupt the fitting process
%
%   stop = cfInterrupt( 'get' ) gets the current interrupt status
%   cfinterrupt( 'set', stop ) sets the current interrupt status.
%
%   stop = true implies that fitting should/will be stopped.
%   stop = false implies that fitting is free to continue.

%   Copyright 2009-2011 The MathWorks, Inc.

persistent PERSISTENT_STOP
if isempty( PERSISTENT_STOP )
    PERSISTENT_STOP = false;
end

switch action
    case 'get'
        % Give callbacks the chance to stop the fitting
        drawnow();
        % Get the value of the STOP
        stop = PERSISTENT_STOP;
        
    case 'set'
        PERSISTENT_STOP = stop;
        
    otherwise
        error( message( 'curvefit:cfInterrupt:InvalidAction' ) );
end
end

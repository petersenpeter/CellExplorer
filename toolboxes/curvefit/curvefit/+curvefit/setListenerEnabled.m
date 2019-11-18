function setListenerEnabled(L, state)
%SETLISTENERENABLED   Set the enabled state for a listener
%
%   SETLISTENERENABLED(L, STATE) sets the enabled state of the listener L.
%   STATE is a logical scalar.  This function will work correctly with listeners
%   whose Enabled property is a logical or an 'on'/'off' string.

%   Copyright 2008-2011 The MathWorks, Inc.

% If the current value of Enabled is logical ...
if islogical( L.Enabled )
    % ... then we can directly use the given state
    L.Enabled = state;
else
    % ... otherwise we need to convert ...
    if state
        % ... true to 'on' ...
        L.Enabled = 'on';
    else
        % ... and false to 'off'
        L.Enabled = 'off';
    end
end

end

function onOff = booleanToOnOff( tf )
% booleanToOnOff returns 'on' if tf is true and 'off' otherwise.

%   Copyright 2011 The MathWorks, Inc.
if tf
    onOff = 'on';
else
    onOff = 'off';
end
end
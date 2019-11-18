function postConstructorSetup(h)
%POSTCONSTRUCTORSETUP   Set property values after construction.
%
%   POSTCONSTRUCTORSETUP(OBJ)

%   Copyright 2010 The MathWorks, Inc.

h.LowessOptionsVersion = 1;
h.method = 'LowessFit';
h.Robust = 'off';
h.Span = 0.25;
end

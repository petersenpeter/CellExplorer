function disp(obj)
%DISP   DISP for FITTYPE.

%   Copyright 1999-2005 The MathWorks, Inc.



objectname = inputname(1);

[ignore,line2] = makedisplay(obj,objectname);

fprintf('     %s\n', line2);

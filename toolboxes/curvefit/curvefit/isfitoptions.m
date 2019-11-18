function flag = isfitoptions(obj)
% ISFITOPTIONS True for fitoptions object.
%   ISFITOPTIONS(OBJ) returns 1 if OBJ is a fitoptions object and 0 otherwise.

%   Copyright 2001-2005 The MathWorks, Inc. 

flag = false;
if isa(obj, 'curvefit.basefitoptions')
    flag = true;
end
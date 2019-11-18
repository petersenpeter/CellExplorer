function flag = islinear(model)
%ISLINEAR Returns 1 for linear models and 0 for nonlinear.
%
%   See also FITTYPE.

%   Copyright 2001-2004 The MathWorks, Inc. 

flag = model.linear;

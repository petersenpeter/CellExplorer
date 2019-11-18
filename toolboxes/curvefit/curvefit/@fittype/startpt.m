function num = startpt(model)
%STARTPT function to compute start point.
%   STARTPT(FITTYPE) returns the function handle of a function
%   to compute a starting point for FITTYPE based on xdata and ydata.
%   
%
%   See also FITTYPE/FORMULA.

%   Copyright 2001-2008 The MathWorks, Inc.

num = model.fStartpt;

function args = argnames(fun)
%ARGNAMES Argument names.
%   ARGNAMES(FUN) returns the names of the input arguments of the
%   FITTYPE object FUN as a cell array of strings.
%
%   See also FITTYPE/FORMULA.

%   Copyright 1999-2004 The MathWorks, Inc.

args = cellstr(fun.args);

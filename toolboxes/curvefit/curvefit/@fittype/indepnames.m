function names = indepnames(fun)
%INDEPNAMES Independent parameter names.
%   INDEPNAMES(FUN) returns the names of the independent parameters of the
%   FITTYPE object FUN as a cell array of strings.
%
%   See also DEPENDNAMES, FORMULA.

%   Copyright 1999-2008 The MathWorks, Inc.

names = cellstr(fun.indep);

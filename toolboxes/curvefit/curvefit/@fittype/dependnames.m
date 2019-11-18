function names = dependnames(fun)
%DEPENDNAMES Dependent parameter names.
%   DEPENDNAMES(FUN) returns the names of the dependent parameters of the
%   FITTYPE object FUN as a cell array of strings.
%
%   See also FITTYPE/INDEPNAMES, FITTYPE/FORMULA.

%   Copyright 1999-2004 The MathWorks, Inc.

names = cellstr(fun.depen);
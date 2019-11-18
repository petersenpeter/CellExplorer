function names = probnames(fun)
%PROBNAMES Problem dependent parameter names.
%   PROBNAMES(FUN) returns the names of the problem dependent parameters of the
%   FITTYPE object FUN as a cell array of strings.
%
%   See also FITTYPE/FORMULA.

%   Copyright 1999-2004 The MathWorks, Inc.

if isempty(fun.prob)
   names = {};
else
   names = cellstr(fun.prob);
end

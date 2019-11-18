function args = formula(fun)
%FORMULA Function formula.
%   FORMULA(FUN) returns the formula for the FITTYPE object FUN.
%
%   See also FITTYPE/ARGNAMES, FITTYPE/CHAR.

%   Copyright 1999-2004 The MathWorks, Inc.

args = fun.defn;

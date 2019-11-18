function args = fevalexpr(fun)
%FEVALEXPR expression to feval.
%   FEVALEXPR(FUN) returns the expression for the FITTYPE object FUN.
%
%   See also FITTYPE/ARGNAMES, FITTYPE/CHAR.

%   Copyright 1999-2004 The MathWorks, Inc.

args = fun.expr;

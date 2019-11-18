function intexpr = integexpr(fun)
% INTEGEXPR Integral expression.
%   INTEGEXPR(FUN) returns the integral expression of the
%   FITTYPE object FUN. At this time, it is always a function handle.
%
%   See also FITTYPE/DERIVEXPR, FITTYPE/FORMULA.

%   Copyright 2001-2004 The MathWorks, Inc. 

intexpr = fun.intexpr;
function derexpr = derivexpr(fun)
% DERIVEXPR Derivative expression.
%   DERIVEXPR(FUN) returns the derivative expression of the
%   FITTYPE object FUN. At this time, it is always a function handle.
%
%   See also FITTYPE/INTEGEXPR, FITTYPE/FORMULA.

%   Copyright 2001-2004 The MathWorks, Inc. 

derexpr = fun.derexpr;
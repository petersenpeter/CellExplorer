function coeffs = coeffnames(fun)
%COEFFNAMES Coefficient names.
%   COEFFNAMES(FUN) returns the names of the coefficients of the
%   FITTYPE object FUN as a cell array of strings.
%
%   See also FITTYPE/FORMULA.

%   Copyright 1999-2004 The MathWorks, Inc.

if isempty(fun.coeff)
   coeffs = {};
else
   coeffs = cellstr(fun.coeff);
end

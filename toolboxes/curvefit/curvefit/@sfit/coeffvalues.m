function coeffs = coeffvalues( obj )
%COEFFVALUES   Coefficient values.
%   COEFFVALUES(SF) returns the values of the coefficients of the
%   SFIT object SF as a row vector.
%
%   See also SFIT/PROBVALUES, FITTYPE/FORMULA.

%   Copyright 2008 The MathWorks, Inc.

if isempty( obj.fCoeffValues )
   coeffs = {};
else
   coeffs = [obj.fCoeffValues{:}];
end

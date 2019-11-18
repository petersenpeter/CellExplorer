function probs = probvalues( obj )
%PROBVALUES   Problem parameter values.
%   PROBVALUES(SF) returns the values of the problem parameters of the SFIT
%   object SF as a row vector.
%
%   See also SFIT/COEFFVALUES, FITTYPE/FORMULA.

%   Copyright 2008 The MathWorks, Inc.

if isempty( obj.fProbValues )
   probs = {};
else
   probs = [obj.fProbValues{:}];
end

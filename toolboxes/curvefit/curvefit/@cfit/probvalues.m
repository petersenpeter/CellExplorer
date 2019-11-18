function probs = probvalues(fun)
%PROBVALUES Problem parameter values.
%   PROBVALUES(FUN) returns the values of the problem parameters of the
%   CFIT object FUN as a row vector.
%
%   See also CFIT/COEFFVALUES, FITTYPE/FORMULA.

%   Copyright 2001-2004 The MathWorks, Inc. 

if isempty(fun.probValues)
   probs = {};
else
   probs = [fun.probValues{:}];
end

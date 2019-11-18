function activebounds = isActiveBounds(coefficients, lowerbound, upperbound)
% isActiveBounds   True for bounds that are active
%
% Syntax:
%   activebounds = isActiveBounds(coefficients, lowerbound, upperbound)
%
% Inputs:
%   coefficients -- vector of coefficients
%   lowerbound -- vector of lower bounds
%   upperbound -- vector of upper bounds
%
% Outputs:
%   activebounds -- logical vector that is true where a coefficient is
%   equal to either the lower or upper bound.

%   Copyright 2014-2014 The MathWorks, Inc.

activebounds = iAlmostEqual( coefficients(:), lowerbound(:) ) ...
    |          iAlmostEqual( coefficients(:), upperbound(:) );
end

function tf = iAlmostEqual( A, B )
% iAlmostEqual   True for elements of A and B that are "almost equal".
tf = abs(A-B) < sqrt(eps);
end

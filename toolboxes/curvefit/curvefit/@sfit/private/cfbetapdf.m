function y = cfbetapdf(x,a,b)
%CFBETAPDF Adapted from BETAPDF in the Statistics Toolbox.

%   Copyright 2001-2008 The MathWorks, Inc.

if nargin < 3, 
   error(message('curvefit:cfbetapdf:threeArgsRequired'));
end

% Initialize Y to zero.
y = zeros(size(x));

% Return NaN for parameter values outside their respective limits.
k1 = find(a <= 0 | b <= 0);
if any(k1)
    tmp = NaN;
    y(k1) = tmp(ones(size(k1))); 
end

% Return Inf for x = 0 and a < 1 or x = 1 and b < 1.
% Required for non-IEEE machines.
k2 = find((x == 0 & a < 1) | (x == 1 & b < 1));
if any(k2)
    tmp = Inf;
    y(k2) = tmp(ones(size(k2))); 
end

% Return the beta density function for valid parameters.
k = find(~(a <= 0 | b <= 0 | x <= 0 | x >= 1));
if any(k)
%    y(k) = x(k) .^ (a(k) - 1) .* (1 - x(k)) .^ (b(k) - 1) ./ beta(a(k),b(k));
     tmp(k) = (a(k) - 1).*log(x(k)) + (b(k) - 1).*log((1 - x(k))) - betaln(a(k),b(k));
     y(k) = exp(tmp(k));
end

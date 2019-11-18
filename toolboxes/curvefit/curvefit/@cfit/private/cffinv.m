function x = cffinv(p,v1,v2)
%CFFINV   Inverse of the F cumulative distribution function.
%   Copied from Statistics Toolbox function finv
%
%   Inputs must have the same size

%   Copyright 2001-2008 The MathWorks, Inc.

x = zeros(size(p));

k = (v1 <= 0 | v2 <= 0 | isnan(p));
if any(k(:))
   x(k) = NaN;
end

k1 = (p > 0 & p < 1 & v1 > 0 & v2 > 0);
if any(k1(:))
    z = cfbetainv(1 - p(k1),v2(k1)/2,v1(k1)/2);
    x(k1) = (v2(k1) ./ z - v2(k1)) ./ v1(k1);
end

k2 = (p == 1 & v1 > 0 & v2 > 0);
if any(k2(:))
   x(k2) = Inf;
end

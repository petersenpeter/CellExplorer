function x = cftinv(p,v)
%CFTINV Adapted from TINV in the Statistics Toolbox.

%   Copyright 2001-2008 The MathWorks, Inc.


% Initialize Y to zero, or NaN for invalid d.f.
x=zeros(size(p));

if v==1
  x = tan(pi * (p - 0.5));
  return
end

% The inverse cdf of 0 is -Inf, and the inverse cdf of 1 is Inf.
k0 = find(p == 0 & ~isnan(x));
if any(k0)
    tmp   = Inf;
    x(k0) = -tmp(ones(size(k0)));
end
k1 = find(p ==1 & ~isnan(x));
if any(k1)
    tmp   = Inf;
    x(k1) = tmp(ones(size(k1)));
end

% For small d.f., call betainv which uses Newton's method
if v<1000
   k = find(p >= 0.5 & p < 1 & ~isnan(x));
   wuns = ones(size(k));
   if any(k)
       z = cfbetainv(2*(1-p(k)),(v/2)*wuns,0.5*wuns);
       x(k) = sqrt(v ./ z - v);
   end
   
   k = find(p < 0.5 & p > 0 & ~isnan(x));
   wuns = ones(size(k));
   if any(k)
       z = cfbetainv(2*(p(k)),(v/2)*wuns,0.5*wuns);
       x(k) = -sqrt(v ./ z - v);
   end
   return
end


% For large d.f., use Abramowitz & Stegun formula 26.7.5
k = find(p>0 & p<1 & ~isnan(x));
if any(k)
   xn = sqrt(2) * erfinv(2*p(k) - 1);
   df = v;
   x(k) = xn + (xn.^3+xn)./(4*df) + ...
           (5*xn.^5+16.*xn.^3+3*xn)./(96*df.^2) + ...
           (3*xn.^7+19*xn.^5+17*xn.^3-15*xn)./(384*df.^3) +...
           (79*xn.^9+776*xn.^7+1482*xn.^5-1920*xn.^3-945*xn)./(92160*df.^4);
end
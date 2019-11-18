function [v,b] = sprpp(tx,a)
%SPRPP Right Taylor coefficients from local B-coefficients.
%
%   [V,B] = SPRPP(TX,A)
%
%   uses knot insertion to derive from the B-spline coefficients
%   A(.,:) relevant for the interval  [TX(.,k-1) .. TX(.,k)]  (with
%   respect to the knot sequence  TX(.,1:2k-2) )  the polynomial
%   coefficients V(.,1:k) relevant for the interval  [0 .. TX(.,k)] .
%   Here,    [ ,k] := size(A) .
%   Also, it is assumed that  TX(.,k-1) <= 0 < TX(.,k) .
%
%   In the process, uses repeated insertion of  0  to derive, in
%   B(.,1:k) , the B-spline coefficients relevant for the interval
%   [0 .. TX(.,k)]  (with respect to the knot sequence
%   [0,...,0,TX(.,k:2*(k-1))]) .
%
%   See also SPLPP.

%   Carl de Boor 25 feb 89
%   Copyright 1987-2008 The MathWorks, Inc. 


k = length(a(1,:)); km1 = k-1; b = a;
for r=1:km1
   for i=1:k-r
      b(:,i) =(tx(:,i+km1).*b(:,i)-tx(:,i+r-1).*b(:,i+1))./...
               (tx(:,i+km1)-tx(:,i+r-1));
   end
end

%  Use differentiation at  0  to generate the derivatives

v = b;
for r=2:k
   factor = (k-r+1)/(r-1);
   for i=k:-1:r
      v(:,i) = (v(:,i) - v(:,i-1))*factor./tx(:,i+k-r);
   end
end

v = v(:,k:-1:1);

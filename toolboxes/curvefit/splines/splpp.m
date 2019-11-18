function [v,b] = splpp(tx,a)
%SPLPP Left Taylor coefficients from local B-coefficients.
%
%   [V,B] = SPLPP(TX,A)
%
%   uses knot insertion to derive from the B-spline coefficients
%   A(.,:) relevant for the interval [TX(.,k-1) .. TX(.,k)]  (with
%   respect to the knot sequence TX(.,1:2k-2) )  the B-spline
%   coefficients B(.,1:k) relevant for the interval  [TX(.,k-1) .. 0]
%   (with respect to the knot sequence [TX(.,1:k-1),0,...,0] ), with
%   [ ,k]:=size(A) .
%
%   It is assumed that  TX(.,k-1) < 0 <= TX(.,k) .
%
%   From this, computes V(j) := D^{k-j}s(0-)/(k-j)!  , j=1,...,k ,
%   with  s  the spline described by the given knots and coefficients.
%
%   See also SPRPP, SP2PP.

%   Carl de Boor 25 feb 89
%   cb 10 mar 96 (vectorize)
%   Copyright 1987-2008 The MathWorks, Inc. 

k = length(a(1,:)); km1 = k-1; b = a;
for r=1:km1
   for i=km1:-1:r
      b(:,i+1) = (tx(:,i+k-r).*b(:,i)-tx(:,i).*b(:,i+1))./ ...
                         (tx(:,i+k-r)-tx(:,i));
   end
end

%  Use differentiation at  0  to generate the derivatives

v = b;
for r=1:km1
   factor = (k-r)/r;
   for i=1:k-r
      v(:,i) = (v(:,i) - v(:,i+1))*factor./tx(:,i+r-1);
   end
end

% Note: the first B-spline has knots tx_0,...,tx_k, but its evaluation only
% uses tx_1,...,tx_k . Similarly, the evaluation of the last, or k-th, B-spline
% only requires its `interior' knots  tx_k,...,tx_(2k-2) .
%
% Since the first B-spline has knots  tx_0,...,tx_k , we have  t_j=tx_(j-1) in
% the usual formulae. E.g., in the first step, we overwrite
%  a(j)  by  (-tx_(j-1)a(j)+tx_(j+k-2)a(j-1))/(-tx_...+tx_...) ,
% and do this for  j=2,...,k.

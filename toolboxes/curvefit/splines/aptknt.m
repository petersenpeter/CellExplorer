function [knots,k] = aptknt(tau,k)
%APTKNT Acceptable knot sequence
%
%   APTKNT(TAU,K)  returns, for a given nondecreasing sequence TAU with
%   TAU(i) < TAU(i+K-1), all i, a knot sequence, KNOTS, for which the 
%   Schoenberg-Whitney conditions
%
%            KNOTS(i) <  TAU(i)  <  KNOTS(i+K) , i=1:length(TAU)
%
%   hold (with equality only for the first or last knot), ensuring that
%   the space of splines of order 
%              K  :=  min(K,length(TAU))  
%   with knot sequence KNOTS has a unique interpolant to arbitrary data
%   at the data sites TAU; the K used is, optionally, returned.
%
%   For example, for strictly increasing  x , and given corresponding  y ,
%
%      sp = spapi(aptknt(x,k),x,y);
%
%   gives a spline f  of order  min(k,length(x))  satisfying f(x(i)) = y(i),
%   all i (and the same result is obtained by spapi(k,x,y) ).
%   Be aware, though, of the fact that, for highly nonuniform  x , the 
%   determination of this spline can be ill-conditioned, leading possibly
%   to very strange behavior away from the interpolation points.
%
%   At present, the knot sequence chosen here is the initial guess used for
%   the iterative determination of the `optimal' knots in OPTKNT.
%
%   See also AUGKNT, AVEKNT, NEWKNT, OPTKNT.

%   Copyright 1987-2008 The MathWorks, Inc.

% If  tau(1) <= ... <= tau(n) with no more than  k-2  consecutive equalities,
% and  n>k , then the output  xi = aveknt(tau,k)  is strictly increasing and,
% for any a<tau(1), tau(n)<b, the output  knots = augknt([a xi b],k)  satisfies
% the above Schoenberg-Whitney conditions wrto  tau . 
%
% Indeed, then  
%                  knots(1:k) = a < tau(1) <= ... <= tau(k),
% while, for  i=1:n-k,
%           knots(k+i) =  xi(i) = (tau(i+1)+...+tau(i+k-1))/(k-1), 
% hence (using the fact that at most k-1 consecutive tau's can be equal)
%                 tau(i) < knots(k+i) < tau(i+k) ,   i=1:n-k ,
% and, finally,
%               tau(n-k+1) <= ... <= tau(n) < b = knots(n+[1:k]).  
% Letting now  a -->  tau(1)  and  b --> tau(end)  will not change any of these
% inequalities, except those involving the first and last data site may not
% be strict any more. But that is ok since these will be the endpoints of the
% corresponding basic interval, hence only right, respectively, left limits
% matter there.

n = length(tau); 
if n<2, error(message('SPLINES:APTKNT:toofewTAU')), end

k = max(1,min(k,n)); dtau = diff(tau);
if any(dtau<0)
   error(message('SPLINES:APTKNT:TAUdecreasing')), end
if k==1 % simply use midpoints between data sites
   if ~all(dtau)
      error(message('SPLINES:APTKNT:TAUnotstrictlyincreasing'))
   end
   knots = [tau(1) tau(1:n-1)+dtau/2 tau(n)];
else
   if any(tau(k:n)==tau(1:n-k+1))
      error(message('SPLINES:APTKNT:TAUmulttoolarge', sprintf( '%g', k - 1 )))
   end
   knots = augknt([tau(1) aveknt(tau,k) tau(end)],k);
end

function [newknots,distfn] = newknt(f,newl)
%NEWKNT New break distribution.
%
%   [NEWKNOTS,DISTFN] = NEWKNT(F,NEWL)   returns the knot sequence NEWKNOTS
%   (for splines of the same order as F) that cuts the basic interval for F 
%   into NEWL pieces in such a way that a certain p.linear monotone function 
%   (whose ppform is in DISTFN) related to the high derivative of F is 
%   equidistributed.  
%   The default value for NEWL is the number of polynomial pieces of F.
%
%   The intent is to choose a knot sequence suitable to the fine
%   approximation of a function  g  whose rough approximation in F
%   is assumed to contain enough information about  g  to make this
%   feasible.
%
%   For example, after obtaining the least-squares approximation to given
%   data X,Y by splines of order K with M-1 equally spaced interior knots via
%
%      sp = spap2(augknt(linspace(X(1),X(end),M+1),K),K,X,Y);
%
%  one could hope for a better approximation (with the same number of pieces) by
%
%      sp = spap2(newknt(sp),K,X,Y);
%
%   See also OPTKNT, APTKNT, AVEKNT.

%   Copyright 1987-2008 The MathWorks, Inc.

if f.form(1)=='B', f = sp2pp(f); end
[breaks,coefs,l,k,d] = ppbrk(f);
if length(d)>1||d>1||iscell(breaks)
   error(message('SPLINES:NEWKNT:onlyuniscalar'))
end
%  it would be feasible to have it function for curves as well by choosing
%  DISTFN to have as its derivative the maximum over all component
%  functions.

if nargin<2, newl = l; end

if l==1||newl==1   % if there is only one piece, or only one piece is asked for,
                   % return uniform break sequence;
   newknots = augknt(linspace(breaks(1), breaks(end), newl+1),k);
   if nargout>1 distfn = ppmak([0 breaks(end)-breaks(1)], [1 0]); end
   return
end

% The distribution function DISTFN is constructed as the integral of the
% K-th root of the absolute value of the K-th derivative of  PP .
%  Since  PP  is of degree < K , this requires some approximation. The ap-
% proximation to the absolute value of the K-th derivative is found as the
% piecewise constant on the same break sequence whose value on the interval
%  BREAKS(i)..BREAKS(i+1)  is the derivative at
%   (BREAKS(i-1)+3BREAKS(i)+3BREAKS(i+1)+BREAKS(i+2))/8
% of the parabola that agrees with the variation of the (K-1)st derivative
% of PP at the three points BREAKS(i-1/2), BREAKS(i+1/2), BREAKS(i+3/2) .

temp = abs(diff(coefs(:,1)).'./(breaks(3:l+1)-breaks(1:l-1)));
temp = (temp([1 1:l-1])+temp([1:l-1 l-1])).^(1/k);
distfn = fnint(ppmak(breaks,temp(:).'));

% The total variation of DISTFN is its value at BREAKS(l+1) , i.e.,
var = fnval(distfn,breaks(l+1));
if var==0
   newknots = augknt(linspace(breaks(1), breaks(end), newl+1),k);
   return
end

% The break sequence NEWBRK is to be chosen so that
%        DISTFN(NEWBRK) =
steps = [0:newl]*(var/newl); newbrk([1 newl+1]) = breaks([1 end]);

% For this, do the inverse interpolation:
coefs = ppbrk(distfn,'c');
flats = find(coefs(:,1)==0);
if (~isempty(flats)), coefs(flats,1) = 1; end
breaks = breaks-breaks(1);
invbrk = [coefs(:,2).' var];
coefs = [1./coefs(:,1),reshape(breaks(1:l),l,1)];

if ~isempty(flats)
   temp = ppmak(invbrk,coefs,1);
   newbrk(2:newl) = newbrk(1) + ...
                    (ppual(temp,steps(2:newl))+ppual(temp,steps(2:newl),'l'))/2;
else
   newbrk(2:newl) = newbrk(1) + fnval(ppmak(invbrk,coefs,1),steps(2:newl));
end

newknots = augknt(newbrk,k);

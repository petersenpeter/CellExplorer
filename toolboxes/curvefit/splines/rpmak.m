function rp = rpmak(breaks,coefs,d)
%RPMAK Put together a rational spline in rpform.
%
%   RPMAK(BREAKS,COEFS), RPMAK(BREAKS,COEFS,D) and RPMAK(BREAKS,COEFS,SIZEC)
%   all return the rpform of the rational spline specified by the input, with 
%   COEFS interpreted according to whether or not the third input argument is 
%   present. 
%
%   This is exactly the output of PPMAK(BREAKS,COEFS), PPMAK(BREAKS,COEFS,D+1)
%   and PPMAK(BREAKS,COEFS,SIZEC) except that it is tagged to be the rpform of a
%   rational spline, namely the rational spline whose denominator is provided by
%   the last component of the spline, while its remaining components describe
%   the numerator.
%
%   In particular, the input coefficients must be (d+1)-vector valued for some
%   d>0 and cannot be ND-valued.
%
%   For example, since ppmak([-5 5],[1 -10 26]) provides the ppform
%   of the polynomial  t |-> t^2+1  on the interval [-5 .. 5], while 
%   ppmak([-5 5], [0 0 1]) provides the ppform of the quadratic polynomial
%   t |-> 1  there, the command
%
%      runge = rpmak([-5 5],[0 0 1; 1 -10 26],1);
%
%   provides the rpform on the interval [-5 .. 5] for the rational function 
%   t |-> 1/(t^2+1)  famous from Runge's example concerning polynomial inter-
%   polation at equally spaced sites.
%
%   See also RPBRK, RSMAK, PPMAK, SPMAK, FNBRK.

%   Copyright 1987-2009 The MathWorks, Inc.

if nargin>2
   if length(d)==1, d = d+1; end
   rp = ppmak(breaks,coefs,d);
else
   rp = ppmak(breaks,coefs);
end

dp1 = fnbrk(rp,'dim');
if length(dp1)>1
   error(message('SPLINES:RPMAK:onlyvec'))
end
if dp1==1
   error(message('SPLINES:RPMAK:needmorecomps'))
end
rp.dim = dp1-1; rp.form = 'rp';

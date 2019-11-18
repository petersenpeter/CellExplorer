function knots = optknt(tau,k,maxiter)
%OPTKNT Optimal knot distribution for interpolation.
%
%   OPTKNT(TAU,K)  returns an `optimal' knot sequence for interpolation at
%   data sites TAU(1), ..., TAU(n) by splines of order K. 
%   TAU must be an increasing sequence, but this is not checked.
%
%   OPTKNT(TAU,K,MAXITER) specifies the number MAXITER of iterations to be
%   tried, the default being 10.
%
%   The interior knots of this knot sequence are the  n-K  sign-changes in
%   any absolutely constant function  h ~= 0  that satisfies 
%
%          integral{ f(x)h(x) : TAU(1) < x < TAU(n) } = 0
%
%   for all splines  f  of order K with knot sequence TAU.
%
%   Example:
%   Micchelli/Rivlin/Winograd and Gaffney/Powell would approve of the
%   following way of constructing a spline interpolant of order K to
%   given data  x, y :
%
%      x = sort([0, rand(1,11)*(2*pi),2*pi]); y = sin(x); k = 5;
%      sp = spapi(optknt(x,k),x,y);
%      fnplt(sp), hold on, plot(x,y,'o'), hold off
%
%   See also APTKNT, NEWKNT, AVEKNT.

%   Copyright 1987-2008 The MathWorks, Inc.

n = length(tau); nmk = n-k;
signs = 1-2*rem([nmk-1:-1:0],2);
tauext = [tau repmat(tau(n),1,k)];
% initial guess:
xi = aveknt(tau,k);
tol = 1.e-7*(tau(n)-tau(1))/(nmk); 
if nargin<3||isempty(maxiter), maxiter = 10; end

% Newton iteration, a la `Computational aspects of optimal recovery'
for iter = 1:maxiter
   ais = [signs*spcol(tauext,k+1,xi,'sp') -1/2];     % a_1,...,a_n  from (18)
   temp = cumsum(ais(n:-1:1).').'; cumais = temp(n:-1:1);% sum{a_j: j = i,...,n}
   % now solve for the changes in  xi  (see eqns (20) and (21))
   mmdflag = spparms('autommd'); spparms('autommd',0);    % suppress pivoting
   dx = signs.* ...
      ((-cumais(1:nmk).*(tau(k+[1:nmk])-tau([1:nmk]))/k)/spcol(tau,k,xi,'sp'));
   spparms('autommd',mmdflag);
   maxdx = max(abs(dx)); xi = xi+dx;
   % make sure the change does not destroy order nor the Schoenberg-Whitney
   % conditions:
   for checks=1:20
      if all(diff(xi)>0)&&all(xi>tau(1:nmk))&&all(xi<tau(k+1:n))
         checks=0; break, end
      dx = dx/2; xi = xi-dx;
   end
   if checks>0
      error(message('SPLINES:OPTKNT:noconv'))
   end
   if maxdx<tol, knots = augknt([tau(1) xi tau(end)],k); return, end
end
error(message('SPLINES:OPTKNT:maxiter', maxiter));

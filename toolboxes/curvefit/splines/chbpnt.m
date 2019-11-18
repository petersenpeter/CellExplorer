function [tau,sp] = chbpnt(t,k,tol,test)
%CHBPNT Good data sites, the Chebyshev-Demko points 
%
%   CHBPNT(T,K) returns the extreme points of the Chebyshev spline of 
%   order K for the knot sequence T, as particularly good points for 
%   interpolation from the spline space S_{K,T}. Also returns, optionally, the
%   Chebyshev spline itself, that is, the maximally oscillating spline
%   in S_{K,T}, normalized to have its last extreme value equal to 1.
%
%   The spline is computed by the Remes algorithm, with the relative
%   difference between largest and smallest absolute extremum required to
%   be no larger than the TOL supplied, whose default value is .001 .
%
%   For example, if you have decided to approximate the square-root function
%   on the interval  [0 .. 1]  by cubic splines with knot sequence 
%
%      k = 4; n = 10; t = augknt(((0:n)/n).^8,k);
%
%   then a good approximation to the square-root function from that specific
%   spline space is given by
%
%      x = chbpnt(t,k); sp = spapi(t,x,sqrt(x));
%
%   as is evidenced by the near equi-oscillation of the error.
%
%  See also CHEBDEM, AVEKNT.

%   Copyright 1987-2011 The MathWorks, Inc.

if nargin<4, test = 0; end 
% By definition, for given knot sequence  t  in R^{n+k},  C_t  is the
% unique element of  $_{t,k}  of max-norm 1  that maximally oscillates on
% the interval  [t_k .. t_{n+1}]  and is positive near  t_{n+1} . This means
% that there is a unique strictly increasing  tau in  R^n  so that the
% function  C in $_{k,t}  given by  C(tau(i))=(-)^{n-i} , all  i , has
% max-norm 1 on  [t_k .. t_{n+1}] . This implies that  tau(1) = t_k ,
%  tau(n) = t_{n+1} , and that  t_i < tau(i) < t_{k+i} , all i .  In fact,
%  t_{i+1} <= tau(i) <= t_{i+k-1} , all i . This brings up the point
% that the knot sequence is assumed to make such an inequality possible,
% i.e., the elements of  $_{k,t}  are assumed to be continuous.
%
%  In short, the Chebyshev spline  C  looks just like the Chebyshev poly-
% nomial.  It performs similar functions. For example, its extrema  tau
% are particularly good points to interpolate at from  $_{k,t}  since the
% norm of the resulting projector is about as small as can be.

if nargin<3, tol = .001; end
itermax = 10;

n = length(t)-k;

tau = aveknt(t,k); difftau = diff(tau);
b = rem(n-1:-1:0,2)*2-1;
sp = spapi(t,tau,b);
 

for lw=1:itermax
   if test 
      figure
      fnplt(sp); 
      title( getString(message('SPLINES:resources:plotTitle_Approximation', num2str(lw))) )
      hold on; 
      plot(tau, zeros(size(tau)),'or') 
      pause
   end

  % For the complete leveling, we use the  Murnaghan-Wrench variant of the
  % Remez algorithm. This means that, for our current guess of the tau's,
  % we construct the unique spline that equioscillates at these tau's.
  % Then, do one step of the Newton iteration for finding the local extrema of
  % the resulting spline.
  Dsp = fnder(sp); intau = tau(2:n-1);
  Dsptau = fnval(Dsp,intau); DDsptau = fnval(fnder(Dsp),intau);
    %  Here are the two alternatives:
    % dtau = -Dsptau./fnval(fnder(Dsp),intau);  is just Newton, while
    % dtau = (dt.*Dsptau)./(2*(2*b(2:n-1)./dt + Dsptau));  is obtained as
    %   the step that leads to the local extremum 
    % of the parabola that matches sp at tau(i) twice and once at tau(j), with 
    %  j = i+1 in case sp(tau(i)) Dsp(tau(i))>0
    %  j = i-1 in case sp(tau(i)) Dsp(tau(i))<0
    % That parabola is f(x) = b(i) + Dspi*(x-ti) - c (x-ti)^2, with
    % c = (2b(i)/dt + Dspi)/dt, hence that extreme point xi satisfies
    % 0 = Dspi - c 2 (xi-ti), or 
    % xi-ti = Dspi/(2c) = dt*Dspi/(2*(2b(i)/dt + Dspi)), with
    % dt = tau(j)-tau(i), Dspi = Dsp(tau(i)).
  bin = b(2:n-1); dt = tau((2:n-1)+sign(bin.*Dsptau)) - intau;   
    % We use the second way when we are far from leveling, e.g., when DDsp 
    % is positive at a point supposedly near a local maximizer:
  index = find(bin.*DDsptau>=0);
  if ~isempty(index) 
     DDsptau(index) = (-2)*(2*bin(index)./dt(index) + Dsptau(index))./dt(index);
  end
  dtau = -Dsptau./DDsptau;
  tau(2:n-1) =  tau(2:n-1)+dtau;
  
  % make certain that this does not disorder the tau's
  difftauold = difftau;
  while 1
     difftau = diff(tau);
     if all(difftau>.1*difftauold) 
         break
     end
     dtau = dtau/2; 
     tau(2:n-1) = tau(2:n-1)-dtau;
  end

  % .. and compute the values of our current approximation there
  extremes = abs(fnval(sp,tau));
  % .. and construct the new approximation
  sp = spapi(t,tau,b);
  
  minext = min(extremes); 
  maxext = max(extremes);
  % Their difference is an estimate of how far we are from total leveling.
  if test 
      xlabel([num2str(minext-1),', ',num2str(maxext-1)])
      hold off
  end
  
  if maxext-minext<=tol*minext, return, end

end

fprintf( '%s\n', getString(message('SPLINES:resources:FailedToReachTolerance',...
    num2str(tol,'%8f'),num2str(itermax,'%3g'))) )

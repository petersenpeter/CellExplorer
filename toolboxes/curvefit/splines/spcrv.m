function curve = spcrv(x,k,maxpnt)
%SPCRV Spline curve by uniform subdivision.
%
%   CURVE = SPCRV(X)  uses repeated midpoint knot insertion to generate a
%   fine sequence of successive values CURVE(:,i) of the spline
%
%      t |-->  sum  B(t-K/2;j,...,j+k)*X(j)  for  t  in  [K/2 .. n-K/2]
%               j
%
%   from the input (d,n)-array X. 
%   For d>1, each CURVE(:,i) is a point on the corresponding spline curve.
%   The insertion process stops as soon as there are >= MAXPNT knots. 
%   The default for K is 4. The default for MAXKNT is 100.
%
%   CURVE = SPCRV(X,K) also specifies the order, K.
%   
%   CURVE = SPCRV(X,K,MAXPNT) also specifies the lower bound, MAXPNT, for
%   the number of points to be returned.
%
%   Example:
%
%     k=3; c = spcrv([1 0;0 1;-1 0;0 -1; 1 0].',k); plot(c(1,:),c(2,:))
%
%   plots three quarters of an approximate circle, while, with k=4, only
%   half an approximate circle is plotted.
%
%   See also CSCVN, SPCRVDEM, SPALLDEM.

%   Copyright 1987-2010 The MathWorks, Inc.

y = x; kntstp = 1;
if nargin<2||isempty(k), k = 4; end
[d,n] = size(x);
if n<k
   error(message('SPLINES:SPCRV:toofewpoints', sprintf( '%.0f', n ), sprintf( '%.0f', k )));
elseif k<2
   error(message('SPLINES:SPCRV:ordertoosmall', sprintf( '%.0f', k )));
else
   if k>2
      if nargin<3||isempty(maxpnt), maxpnt = 100; end
      while n<maxpnt
         kntstp = 2*kntstp; m = 2*n; yy(:,2:2:m) = y; yy(:,1:2:m) = y;
         for r=2:k
            yy(:,2:m) = (yy(:,2:m)+yy(:,1:m-1))*.5;
         end
         y = yy(:,k:m); n = m+1-k;
      end
   end

   if nargout==1 curve = y; end

   %  disable the plotting of breaks for the time being

%  kl = floor((k-2)*.5); knots = 1:kntstp:n;
%  yk = .5*(y(:,knots+kl)+y(:,knots+k-2-kl));
%  if d==1
%     plot([1:n],y,symbol,knots,yk,'x'); pause
%  elseif d==2
%     plot(y(1,:),y(2,:),symbol,yk(1,:),yk(2,:),'x'), pause
%  else
%     plot3(y(1,:),y(2,:)y(3,:),symbol,yk(1,:),yk(2,:),yk(3,:),'x'), pause
%  end

end

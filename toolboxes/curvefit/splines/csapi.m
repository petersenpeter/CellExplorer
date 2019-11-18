function output = csapi(x,y,xx)
%CSAPI Cubic spline interpolant with not-a-knot end condition.
%
%   PP  = CSAPI(X,Y)  returns the cubic spline interpolant (in ppform) to the 
%   given data (X,Y) using the not-a-knot end conditions.
%   The interpolant matches, at the data site X(j), the given data value
%   Y(:,j), j=1:length(X). The data values may be scalars, vectors, matrices,
%   or even ND-arrays. Data points with the same site are averaged.
%   For interpolation to gridded data, see below.
%
%   CSAPI(X,Y,XX)  is the same as FNVAL(CSAPI(X,Y),XX).
%
%   For example, 
%
%      values = csapi([-1:5]*(pi/2),[-1 0 1 0 -1 0 1], linspace(0,2*pi));
%
%   gives a surprisingly good fine sequence of values for the sine over its
%   period.
%
%   It is also possible to interpolate to data values on a rectangular grid,
%   as follows:
%
%   PP = CSAPI({X1, ...,Xm},Y)  returns the m-cubic spline interpolant (in
%   ppform) that matches the data value Y(:,j1,...,jm) at the data site
%   (X1(j1), ..., Xm(jm)), for ji=1:length(Xi) and i=1:m.
%   The entries of each Xi must be distinct.  Y must have size
%   [d,length(X1),...,.length(Xm)], with  d  a vector of natural numbers, and
%   with an empty  d  acceptable when the function is to be scalar-valued.
%
%   CSAPI({X1, ...,Xm},Y,XX)  is the same as FNVAL(CSAPI({X1,...,Xm},Y),XX).
%
%   For example, the statements
%
%      x = -1:.2:1; y=-1:.25:1; [xx, yy] = ndgrid(x,y); 
%      z = sin(10*(xx.^2+yy.^2)); pp = csapi({x,y},z);
%      fnplt(pp)
%
%   produce the picture of an interpolant to a bivariate function. 
%   Use of MESHGRID instead of NDGRID here would produce an error.
%
%   See also CSAPE, SPAPI, SPLINE, NDGRID.

%   Copyright 1987-2010 The MathWorks, Inc.

if iscell(x)     % we are to handle gridded data
   
   m = length(x);
   sizey = size(y);
   if length(sizey)<m
     error(message('SPLINES:CSAPI:toofewdims')), end

   if length(sizey)==m,  % grid values of a scalar-valued function
     if issparse(y), y = full(y); end 
     sizey = [1 sizey]; 
   end

   sizeval = sizey(1:end-m); sizey = [prod(sizeval), sizey(end-m+(1:m))];
   y = reshape(y, sizey); 
   
   v = y; sizev = sizey;
   for i=m:-1:1   % carry out coordinatewise interpolation
      [b,v,l,k] = ppbrk(csapi1(x{i}, reshape(v,prod(sizev(1:m)),sizev(m+1)) ));
      breaks{i} = b;
      sizev(m+1) = l*k; v = reshape(v,sizev);
      if m>1
         v = permute(v,[1,m+1,2:m]); sizev(2:m+1) = sizev([m+1,2:m]);
      end
   end
   % At this point, V contains the tensor-product pp coefficients;
   % It remains to make up the formal description:
   pp = ppmak(breaks, v);
   if length(sizeval)>1, pp = fnchg(pp,'dz',sizeval); end

else             % we have univariate data
   pp = csapi1(x,y);
end

if nargin==2
   output = pp;
else
   output = fnval(pp,xx);
end

function pp = csapi1(x,y)
%CSAPI1 Univariate cubic spline interpolant with not-a-knot end condition.

%     Generate the cubic spline interpolant in pp form, depending on
% the number of data points.

[xi,yi,sizeval] = chckxywp(x,y);

[n,yd] = size(yi); dd = ones(1,yd);
dx = diff(xi); divdif = diff(yi)./dx(:,dd);

if (n==2), % the interpolant is a straight line
   pp=ppmak(xi.',[divdif.' yi(1,:).'],yd);
elseif (n==3), % the interpolant is a parabola
   yi(2:3,:)=divdif;
   yi(3,:)=diff(divdif)*(1/(xi(3)-xi(1)));
   yi(2,:)=yi(2,:)-yi(3,:)*dx(1);
   pp = ppmak( [xi(1),xi(3)], yi([3 2 1],:).' );
else % set up the sparse linear system for solving for the slopes at  xi .
   c = spdiags([ [dx(2:n-1);0;0] ...
                 [0;2*(dx(2:n-1)+dx(1:n-2));0] ...
                 [0;0;dx(1:n-2)] ], [-1 0 1], n, n);
     % the first two and last two equations are special:
   xi31 = xi(3)-xi(1); xin = xi(n)-xi(n-2);
   c(1,1:2) = [dx(2) xi31]; c(n,n-1:n) = [xin dx(n-2)];
   b = zeros(n,yd);
   b(1,:)=((dx(1)+2*xi31)*dx(2)*divdif(1,:)+dx(1)^2*divdif(2,:))/xi31;
   b(2:n-1,:)=3*(dx(2:n-1,dd).*divdif(1:n-2,:)+dx(1:n-2,dd).*divdif(2:n-1,:));
   b(n,:) = ...
   (dx(n-1)^2*divdif(n-2,:)+((2*xin+dx(n-1))*dx(n-2))*divdif(n-1,:))/xin;

     % solve for the slopes ...   (protect current spparms settings)
   mmdflag = spparms('autommd');
   spparms('autommd',0);    % suppress pivoting
   s=c\b;
   spparms('autommd',mmdflag);

     %                          ... and convert to pp form

   c4 = (s(1:n-1,:)+s(2:n,:)-2*divdif(1:n-1,:))./dx(:,dd);
   c3 = (divdif(1:n-1,:)-s(1:n-1,:))./dx(:,dd) - c4;
   pp = ppmak(xi.', ...
     reshape([(c4./dx(:,dd)).' c3.' s(1:n-1,:).' yi(1:n-1,:).'],(n-1)*yd,4),yd);
end
if length(sizeval)>1, pp = fnchg(pp,'dz',sizeval); end

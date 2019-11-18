function sp = spapi(knots,x,y,noderiv)
%SPAPI Spline interpolation.
%
%   SPAPI(KNOTS,X,Y)      (with both KNOTS and X vectors)
%   returns the spline  f  (if any) of order
%         k := length(KNOTS) - length(X)
%   with knot sequence KNOTS for which Y(:,j) equals f(X(j)) , all j.
%   This is taken in the osculatory sense in case some data sites are
%   repeated, i.e., in the sense that  D^m(j) f(X(j)) = Y(:,j)  with
%   m(j) := #{ i<j : X(i) = X(j) }, and  D^m(j) f  the m(j)-th derivative of f.
%   If you don't want this interpretation, call SPAPI with an additional
%   (fourth) input argument in which case the average of all data values
%   at the same data site is matched at that site.
%   The data values, Y(:,j), may be scalars, vectors, matrices, or even
%   ND-arrays.
%
%   SPAPI(K,X,Y)          (with K a positive integer)
%   is the same as  SPAPI(APTKNT(sort(X),K),X,Y), i.e., it uses APTKNT to
%   obtain from K and X a suitable knot sequence.
%
%   SPAPI({KNOTS1,...,KNOTSm},{X1,...,Xm},Y)
%   returns in SP the m-variate tensor-product spline of coordinate order
%      ki := length(KNOTSi) - length(Xi)
%   with knot sequence KNOTSi in the i-th variable, i=1,...,m, for which
%      Y(:,j1,...,jm) = f(X1(j1),...,Xm(jm)),  all j := (j1,...,jm) .
%   As in the univariate case, KNOTSi may also be a positive integer, in
%   which case the i-th knot sequence is obtained from Xi via APTKNT.
%   Note the possibility of interpolating to d-valued data. However,
%   in contrast to the univariate case, if the data to be interpolated are
%   scalar-valued, then the input array Y is permitted to be m-dimensional,
%   in which case
%   Y(j1,...,jm) = f(X1(j1),...,Xm(jm)),  all j := (j1,...,jm) .
%   Multiplicities in the sequences Xi lead to osculatory interpolation just
%   as in the univariate case.
%
%   For example, if the points in the vector  t  are all distinct, then
%
%      sp = spapi(augknt(t,4,2),[t t],[cos(t) -sin(t)]);
%
%   provides the C^1 piecewise cubic Hermite interpolant to the function
%   f(x) = cos(x)  at the points in  t . If matching of slopes is only
%   required at some subsequence  s  of  t  but that includes the leftmost
%   and the rightmost point in  t , one would use instead
%
%      sp = spapi( augknt([t s],4), [t s], [cos(t) -sin(s)] );
%
%   or even just
%
%      sp = spapi( 4, [t s], [cos(t) -sin(s)] );
%
%   and the last works even if s fails to include the extreme points of t,
%   and produces even a C^2 piecewise cubic interpolant to these Hermite data.
%
%   As another example,
%
%      sp = spapi( {[0 0 1 1],[0 0 1 1]}, {[0 1],[0 1]}, [0 0;0 1] );
%
%   constructs the bilinear interpolant to values at the corners of a square,
%   as would the statement
%
%      sp = spapi({2,2},{[0 1],[0 1]},[0 0;0 1]);
%
%   As another example, the statements
%
%      x = -2:.5:2; y=-1:.25:1; [xx, yy] = ndgrid(x,y);
%      z = exp(-(xx.^2+yy.^2));
%      sp = spapi({3,4},{x,y},z);
%      fnplt(sp)
%
%   produce the picture of an interpolant (piecewise quadratic in x,
%   piecewise cubic in y) to a bivariate function.
%   Use of MESHGRID instead of NDGRID here would produce an error.
%
%   As an illustration of osculatory interpolation to gridded data, here
%   is complete bicubic interpolation, with the data explicitly derived
%   from the bicubic polynomial  g(x,y) = x^3y^3, to make it easy for
%   you to see exactly where the slopes and slopes of slopes (i.e., cross
%   derivatives) must be placed in the data values supplied. Since our  g  is
%   a bicubic polynomial, its interpolant, f , must be  g  itself.
%   We test this.
%
%      sites = {[0,1],[0,2]}; coefs = zeros(4,4); coefs(1,1) = 1;
%      g = ppmak(sites,coefs);
%      Dxg = fnval(fnder(g,[1,0]),sites);
%      Dyg = fnval(fnder(g,[0,1]),sites);
%      Dxyg = fnval(fnder(g,[1,1]),sites);
%      f = spapi({4,4}, {sites{1}([1,2,1,2]),sites{2}([1,2,1,2])}, ...
%               [fnval(g,sites), Dyg ; ...
%                Dxg.'         , Dxyg]);
%      if any( squeeze( fnbrk(fn2fm(f,'pp'), 'c') ) - coefs )
%        'something went wrong', end
%
%   SPAPI(...,'noderiv') does not do osculatory interpolation but, instead, 
%   merely averages all data values at the same site.
%
%   See also SPAPS, SPAP2.

%   Copyright 1987-2010 The MathWorks, Inc.

if iscell(knots) % gridded data are to be interpolated by tensor product splines
   if ~iscell(x)
      error(message('SPLINES:SPAPI:Xnotcell'))
   end
   m = length(knots);
   if m~=length(x)
      error(message('SPLINES:SPAPI:wrongsizeX'))
   end
   sizey = size(y);
   if length(sizey)<m
      error(message('SPLINES:SPAPI:wrongsizeY'))
   end

   if length(sizey)==m,  % grid values of a scalar-valued function
     if issparse(y), y = full(y); end
     sizey = [1 sizey];
   end

   sizeval = sizey(1:end-m); sizey = [prod(sizeval), sizey(end-m+(1:m))];
   y = reshape(y, sizey);

   v = y; sizev = sizey;
   for i=m:-1:1   % carry out coordinatewise interpolation
      if nargin>3
         temp = ...
	  spapi1(knots{i},x{i}, reshape(v,prod(sizev(1:m)),sizev(m+1)),noderiv);
         sizev(m+1) = fnbrk(temp,'number');
      else
         temp = spapi1(knots{i},x{i}, reshape(v,prod(sizev(1:m)),sizev(m+1)));
      end
      v = reshape(spbrk(temp,'c'), sizev);
      if length(knots{i})==1, knots{i} = spbrk(temp,'knots'); end
      if m>1
         v = permute(v,[1,m+1,2:m]); sizev(2:m+1) = sizev([m+1,2:m]);
      end
   end
   % At this point, V contains the tensor-product B-spline coefficients;
   % also, the various knot sequences will have been checked.
   % It remains to return information:
   sp = spmak(knots, v, sizev);
   if length(sizeval)>1, sp = fnchg(sp,'dz',sizeval); end

else             % univariate spline interpolation
   if nargin>3
      sp = spapi1(knots,x,y,noderiv);
   else
      sp = spapi1(knots,x,y);
   end
end

function sp = spapi1(knots,x,y,noderiv)
%SPAPI1 univariate spline interpolation

if nargin>3
   [x,y,sizeval] = chckxywp(x,y);
else
   [x,y,sizeval] = chckxywp(x,y,1);
end
if length(knots)==1 % the order is being specified; get the knots via APTKNT
   k = knots;
   if k~=fix(k), error(message('SPLINES:SPAPI:nonintegerorder')), end
   if k<1
      error(message('SPLINES:SPAPI:wrongorder')), end
   if k==1&&length(x)==1
      knots = [x, x+1];
   else
      [knots,k] = aptknt(x,k);
   end
else

   if ~isempty(find(diff(knots)<0,1))
      error(message('SPLINES:SPAPI:decreasingknots'))
   end

   n = length(x); npk = length(knots); k = npk-n;
   if k<1
     error(message('SPLINES:SPAPI:datadontmatchknots', sprintf( '%.0f', n ), sprintf( '%.0f', npk )));
   end
end

%  Generate the collocation matrix and divide it into the possibly reordered
%  sequence of given values to generate the B-spline coefficients of the
%  interpolant, then put it all together into SP.

sp = spmak(knots,slvblk(spcol(knots,k,x,'slvblk'),y).');
if length(sizeval)>1, sp = fnchg(sp,'dz',sizeval); end

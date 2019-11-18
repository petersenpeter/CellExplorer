function sp = spap2(knots,k,x,y,w)
%SPAP2 Least squares spline approximation.
%
%   SPAP2(KNOTS,K,X,Y)  returns the B-form of the least-squares approximation
%   f  to the data X, Y by splines of order K with knot sequence KNOTS.  
%   The spline approximates, at the data site X(j), the given data value
%   Y(:,j), j=1:length(X).
%   The data values may be scalars, vectors, matrices, or even ND-arrays.
%   Data points with the same site are replaced by their (weighted) average.
%   
%    f  is the spline of order K with knot sequence KNOTS for which
%
%   (*)    Y = f(X)
%
%   in the mean-square sense, i.e., the one that minimizes
%
%   (**)   sum_j W(j) |Y(:,j) - f(X(j))|^2 ,
%
%   with  W = ones(size(X)). Other weights can be specified by an optional
%   additional argument, i.e., by using
%
%   SPAP2(KNOTS,K,X,Y,W) which returns the spline  f  of order K with knot
%   sequence KNOTS that minimizes (**). A better choice than the default
%   W = ones(size(X))  would be the composite trapezoid rule weights 
%   W = ([dx;0]+[0;dx]).'/2 , with dx = diff(X(:))  (assuming that X is
%   strictly increasing).
%
%   If the data sites satisfy the Schoenberg-Whitney conditions
%
%   (***)   KNOTS(j) < X(j) < KNOTS(j+K) ,
%                               j=1:length(X)=length(KNOTS)-K ,
%
%   (with equality permitted at knots of multiplicity K), then  f  is
%   the unique spline of that order satisfying  (***)  exactly.  No
%   spline is returned unless (***) is satisfied for some subsequence
%   of X.
%   
%   Since it might be difficult to supply such a knot sequence for the given
%   data sites, it is also possible to specify KNOTS as a positive integer,
%   in which case, if possible, a knot sequence will be supplied that satisfies
%   (***) for some subsequence of X and results in a spline consisting of KNOTS 
%   polynomial pieces.
%
%   If Y is a matrix or, more generally, an ND array, of size [d1,...,ds,n] say,
%   then Y(:,...,:,j) is the value being approximated at X(j), and the
%   resulting spline is correspondingly [d1,...,ds]-valued. In that case, the
%   expression  |Y(:,j) - f(X(j))|^2  in the error measure (**) is meant as
%   the sum of squares of all the d1*...*ds entries of  Y(:,j)-f(X(j)) .
%   
%   It is also possible to fit to gridded data:
%
%   SPAP2( {KNOTS1,...,KNOTSm}, [K1,...,Km], {X1,...,Xm}, Y ) returns
%   the m-variate tensor-product spline of coordinate order Ki and with knot 
%   sequence KNOTSi in the i-th variable, i=1,...,m, for which
%
%   Y(:,...,:,i1,...,im) = f(X1(i1),...,Xm(im)),  all i := (i1,...,im) 
%
%   in the (possibly weighted) mean-square sense.
%   Note the possibility of fitting to vector-valued and even ND-valued data.
%   However, in contrast to the univariate case, if the data to be fitted are
%   scalar-valued, then the input array Y is permitted to be m-dimensional,
%   in which case
%   Y(i1,...,im) = f(X1(i1),...,Xm(im)),  all i := (i1,...,im) 
%   in the (possibly weighted) mean-square sense.
%
%   Example 1:
%
%      spap2(augknt(x([1 end]),2),2,x,y);
%
%   provides the least-squares straight-line fit to data x,y, assuming that
%   all the sites x(j) lie in the interval [x(1) .. x(end)], while
%
%      spap2(1,2,x,y);
%
%   accomplishes this without that assumption, and, with that assumption,
%
%      w = ones(size(x)); w([1 end]) = 100;
%      spap2(1,2,x,y,w);
%
%   forces that fit to come very close to the first and last data point.
%
%   Example 2: The statements
%
%      x = -2:.2:2; y=-1:.25:1; [xx, yy] = ndgrid(x,y); 
%      z = exp(-(xx.^2+yy.^2)); 
%      sp = spap2({augknt([-2:2],3),2},[3 4],{x,y},z);
%      fnplt(sp)
%
%   produce the picture of an approximant to a bivariate function. 
%   Use of MESHGRID instead of NDGRID here would produce an error.
%
%   See also SPAPI, SPAPS.

%   Copyright 1987-2010 The MathWorks, Inc.

if nargin<5, w = []; end

if iscell(knots) % gridded data are to be fitted by tensor product splines

   if ~iscell(x)
      error(message('SPLINES:SPAP2:Xnotcell'))
   end
   m = length(knots);
   if m~=length(x)
      error(message('SPLINES:SPAP2:wrongsizeX'))
   end
   sizey = size(y);
   if length(sizey)<m
     error(message('SPLINES:SPAP2:wrongsizeY'))
   end

   if length(sizey)==m,  % grid values of a scalar-valued function
     if issparse(y), y = full(y); end 
     sizey = [1 sizey]; 
   end

   sizeval = sizey(1:end-m); sizey = [prod(sizeval), sizey(end-m+(1:m))];
   y = reshape(y, sizey); 

   if iscell(k), k = cat(2,k{:}); end
   if length(k)==1, k = repmat(k,1,m); end
   if isempty(w), w = cell(1,m); end
   
   v = y; sizev = sizey;
   for i=m:-1:1   % carry out coordinatewise least-squares fitting
      [knots{i},v,sizev(m+1),k(i)] = spbrk(spap21(knots{i}, k(i), x{i}, ...
                      reshape(v,prod(sizev(1:m)),sizev(m+1)),w{i}));
      v = reshape(v,sizev);
      if m>1
         v = permute(v,[1,m+1,2:m]); sizev(2:m+1) = sizev([m+1,2:m]);
      end
   end
   % At this point, V contains the tensor-product B-spline coefficients.
   % It remains to put together the spline:
   sp = spmak(knots, v, sizev);
   if length(sizeval)>1, sp = fnchg(sp,'dz',sizeval); end

else             % univariate spline interpolation
   sp = spap21(knots,k,x,y,w);
end

function sp = spap21(knots,k,x,y,w)
%SPAP21 Univariate least squares spline approximation.

if isempty(w), [x,y,sizeval]   = chckxywp(x,y,1);
else           [x,y,sizeval,w] = chckxywp(x,y,1,w);
end
nx = length(x);

if length(knots)==1 % we are to use a spline with KNOTS pieces
   k = min(k,nx); maxpieces = nx-k+1;
   if knots<1||knots>maxpieces
      warning(message('SPLINES:SPAP2:wrongknotnumber', sprintf( '%g', maxpieces )))
      knots = max(1,min(maxpieces,knots));
   end
   if knots==1&&k==1
      if nx==1, knots = [x(1) x(1)+1];
      else      knots = x([1 end]).';
      end
   else
      knots = aptknt(x(round(linspace(1,nx,knots-1+k))),k);
   end
end

%  Generate the collocation matrix and divide it into the possibly reordered
%  sequence of given values to generate the B-spline coefficients of the
%  interpolant, then put it all together into SP. But trap any error from
%  SLVBLK, in order to provide a more helpful error message.

try
   if isempty(w)
      sp = spmak(knots,slvblk(spcol(knots,k,x,'slvblk','noderiv'),y).');
   else
      sp = spmak(knots,slvblk(spcol(knots,k,x,'slvblk','noderiv'),y,w).');
   end
catch laster
  if ~isempty(findstr('SLVBLK',laster.identifier))
     error(message('SPLINES:SPAP2:noSWconds'))
  else
     rethrow(laster.message)
  end
end
if length(sizeval)>1, sp = fnchg(sp,'dz',sizeval); end

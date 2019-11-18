function [output,p] = csaps(x,y,p,xx,w)
%CSAPS Cubic smoothing spline.
%
%   CSAPS(X,Y)  returns the ppform of a cubic smoothing spline for the
%   given data X,Y. The smoothing spline approximates, at the data site X(j),
%   the given data value Y(:,j), j=1:length(X). The data values may be
%   scalars, vectors, matrices, or even ND-arrays. Data points with the
%   same site are replaced by their (weighted) average, and this may affect the
%   smoothing spline.
%   For smoothing of gridded data, see below.
%
%   This smoothing spline  f  minimizes
%
%   P * sum_j W(j) |Y(:,j) - f(X(j))|^2  +  (1-P) * integral |D^2 f|^2 .
%
%   Here, the sum is over j=1:length(X);
%   X  and  Y  are the result of replacing any data points with the same site
%   by their weighted average, with its weight the sum of the corresponding
%   weights;
%   the integral is taken over the interval [min(X) .. max(X)];
%   |z|^2  is the sum of the squares of the entries of  z ;
%   D^2 f  is the second derivative of the function  f ;
%   W = ones(length(X),1)  is the default value for W; and
%   the default value for the smoothing parameter P is chosen,
%   in an ad hoc fashion and in dependence on X, as indicated in
%   the next paragraph. You can supply a specific value for P, by using
%   CSAPS(X,Y,P)  instead.
%
%   When P is 0, the smoothing spline is the least-squares straight line fit
%   to the data, while, at the other extreme, i.e., when P is 1, it is the
%   `natural' or variational cubic spline interpolant. The transition region
%   between these two extremes is usually only a rather small range of values
%   for P and its location strongly depends on the data sites. It is in this
%   small range that P is chosen when it is not supplied, or when an empty
%   P or a negative P is input.
%   If P > 1 , the corresponding solution of the above minimization problem
%   is returned, but this amounts to a roughening rather than a smoothing.
%
%   If the resulting smoothing spline, pp, is to be evaluated outside its basic 
%   interval, it should be replaced by fnxtr(pp) to ensure that its second
%   derivative is zero outside that interval.
%
%   [OUT,P] = CSAPS(X,Y,...)  returns the value of P actually used, and this
%   is particularly useful when no P or an empty P was specified.
%
%   If you have difficulty choosing P but have some feeling for the size
%   of the noise in Y, consider using instead  spaps(X,Y,tol)  which, in
%   effect, chooses P in such a way that the roughness measure,
%                integral (D^2 f)^2 ,
%   is as small as possible subject to the condition that the error measure,
%                sum_i W(i)(Y(i) - f(X(i)))^2 ,
%   does not exceed the specified  tol . This usually means that the error
%   measure equals the specified  tol .
%
%   CSAPS(X,Y,P,XX)  returns the value(s) at XX of the cubic smoothing spline,
%   unless XX is empty, in which case the ppform of the cubic smoothing
%   spline is returned. This latter option is important when the user wants
%   the smoothing spline (rather than its values) corresponding to a specific
%   choice of error weights, as is discussed next.
%
%   CSAPS(X,Y,P,XX,W)  returns, depending on whether or not XX is empty, the
%   ppform, or the values at XX, of the cubic smoothing spline for the
%   specified weights W. Any negative weight is replaced by 0, and that
%   makes the resulting smoothing spline independent of the corresponding
%   data point. When data points with the same site are averaged, their
%   weights are summed.
%
%   See below for the case of GRIDDED data.
%
%   Example:
%      x = linspace(0,2*pi,21); y = sin(x)+(rand(1,21)-.5)*.1;
%      pp = csaps(x,y, .4, [], [ones(1,10), repmat(5,1,10), 0] );
%   returns a smooth fit to the data that is much closer to the data
%   in the right half, because of the much larger weight there, except for
%   the last data point, for which the weight is zero.
%
%   It is also possible to vary the smoothness requirement, by having P be a
%   sequence (of the same length as X) rather than a scalar.
%   In that case, the roughness measure is taken to be
%                   integral lambda(t)*(D^2 f(t))^2 dt ,
%   with the roughness weight  lambda  the piecewise constant function with
%   interior breaks X whose value on the interval (X(i-1),X(i)) is P(i)  for
%   i=2:length(x),  while P(1) continues to be taken as the smoothing
%   parameter, P.
%
%   Example:
%      pp1 = csaps(x,y, [.4,ones(1,10),repmat(.2,1,10)], [], ...
%                                  [ones(1,10), repmat(5,1,10), 0]);
%   uses the same data, smoothing parameter, and error weight as in the
%   earlier example, but chooses the roughness weight to be only .2 in the
%   right half of the interval and gives, correspondingly, a rougher but
%   better fit there, -- except for the last data point which is ignored.
%   A plot showing both examples for comparison could now be obtained by
%      fnplt(pp); hold on, fnplt(pp1,'r'), plot(x,y,'ok'), hold off
%      title('cubic smoothing spline, with right half treated differently:')
%      xlabel(['blue: larger error weights; ', ...
%              'red: also smaller roughness weights'])
%
%   CSAPS({X1,...,Xm},Y, ... )  provides a cubic smoothing spline to data
%   values Y on the m-dimensional rectangular grid specified by the  m
%   vectors X1, ..., Xm, and these may be of different lengths. Now,
%   Y has size [d,length(X1), ..., length(Xm)], with  d  the size of a
%   data value.
%   If Y is only of size [length(X1), ..., length(Xm)], i.e., the apparent
%   d is [], then  d  is taken to be [1], i.e., the function is scalar-valued.
%   As to the optional arguments,  P , XX , W , if present, they must be as
%   follows:
%
%   P must be a cell-array with  m  entries, or else an m-vector, except that
%   it may also be a scalar or empty, in which case it is converted to an
%   m-cell-array with all entries equal to the given P. The optional second
%   output argument will always be an m-cell-array.
%
%    XX  can either be a matrix with  m  rows, and then each of its columns
%   is taken as a point in m-space at which the smoothing spline is to be
%   evaluated; or else, XX must be a cell-array {XX1, ..., XXm} specifying
%   the m-dimensional grid at which to evaluate the smoothing spline.
%   With such an XX present, the values of the smoothing spline at the points
%   specified by XX are returned. If there is no XX or else XX is empty,
%   the ppform of the smoothing spline is returned instead.
%
%    W  must be a cell array of length  m , with each W{i} either a vector
%   of the same length as Xi, or else empty, and in that case the default
%   value, ones(1,length(Xi)), is used for W{i}.
%
%   Example:
%      x = {linspace(-2,3,51),linspace(-3,3,61)};
%      [xx,yy] = ndgrid(x{1},x{2}); y = peaks(xx,yy);
%      noisy = y+(rand(size(y))-.5);
%      [smooth,p] = csaps(x,noisy,[],x);
%      surf(x{1},x{2},smooth.')
%   adds uniform noise from the interval [-.5,.5] to the values of MATLAB's
%   PEAKS function on a 51-by-61 uniform grid, then obtains smoothed values
%   from CSAPS along with the smoothing parameters chosen by CSAPS, and plots
%   these smoothed values. -- Notice the use of NDGRID and the need to use the
%   transpose of the array  smooth  in the SURF command.
%   If the resulting surface does not strike you as smooth enough, try a
%   slightly smaller P than the one, .9998889, used, for each variable,
%   by CSAPS in this case:
%      smoother = csaps(x,noisy,.996,x);
%      figure, surf(x{1},x{2},smoother.')
%
%   See also SPAPS, CSAPSDEM, TPAPS.

%   Copyright 1987-2010 The MathWorks, Inc.

if nargin<3||isempty(p), p = -1; end
if nargin<4, xx = []; end
if nargin<5, w = []; end

if iscell(x)     % we are to handle gridded data

   m = length(x);
   sizey = size(y);
   if length(sizey)<m
     error(message('SPLINES:CSAPS:toofewdims')), end

   if length(sizey)==m,  % grid values of a scalar-valued function
     if issparse(y), y = full(y); end 
     sizey = [1 sizey]; 
   end

   sizeval = sizey(1:end-m); sizey = [prod(sizeval), sizey(end-m+(1:m))];
   y = reshape(y, sizey); 
   
   if ~iscell(p)  % because of the possibility of weighted roughness measures
                  % must have P be a cell array in the multivariate case.
      if length(p)~=m, p = repmat(p(1),1,m); end
      p = num2cell(p);
   end
   if isempty(w), w = cell(1,m); end

   v = y; sizev = sizey;
   for i=m:-1:1   % carry out coordinatewise smoothing
      [cs,p{i}] = csaps1(x{i}, reshape(v,prod(sizev(1:m)),sizev(m+1)), ...
                  p{i}, [], w{i});
      [breaks{i},v,l,k] = ppbrk(cs);
      sizev(m+1) = l*k; v = reshape(v,sizev);
      if m>1
         v = permute(v,[1,m+1,2:m]); sizev(2:m+1) = sizev([m+1,2:m]);
      end
   end
   % At this point, V contains the tensor-product pp coefficients;
   % It remains to make up the formal description:
   output = ppmak(breaks, v);
   if length(sizeval)>1, output = fnchg(output,'dz',sizeval); end
   if ~isempty(xx)
      output = fnval(output,xx);
   end

else             % we have univariate data

   [output,p] = csaps1(x,y,p,xx,w);

end

function [output,p] = csaps1(x,y,p,xx,w)
%CSAPS1 univariate cubic smoothing spline

n=length(x); if isempty(w), w = ones(1,n); end
[xi,yi,sizeval,w,origint,p] = chckxywp(x,y,2,w,p);
n = size(xi,1); yd = size(yi,2); dd = ones(1,yd);

dx = diff(xi); divdif = diff(yi)./dx(:,dd);
if n==2 % the smoothing spline is the straight line interpolant
   pp=ppmak(xi.',[divdif.' yi(1,:).'],yd); p = 1;
else % set up the linear system for solving for the 2nd derivatives at  xi .
     % this is taken from (XIV.6)ff of the `Practical Guide to Splines'
     % with the diagonal matrix D^2 there equal to diag(1/w) here.
     % Make use of sparsity of the system.

   dxol = dx;
   if length(p)>1 
      lam = p(2:end).'; p = p(1);
      dxol = dx./lam;
   end

   R = spdiags([dxol(2:n-1), 2*(dxol(2:n-1)+dxol(1:n-2)), dxol(1:n-2)],...
                                         -1:1, n-2,n-2);
   odx=1./dx;
   Qt = spdiags([odx(1:n-2), -(odx(2:n-1)+odx(1:n-2)), odx(2:n-1)], ...
                                                0:2, n-2,n);
   % solve for the 2nd derivatives
   W = spdiags(1./w(:),0,n,n);
   Qtw = Qt*spdiags(1./sqrt(w(:)),0,n,n);
   if p<0 % we are to determine an appropriate P
      QtWQ = Qtw*Qtw.'; p = 1/(1+trace(R)/(6*trace(QtWQ)));
          % note that the resulting  p  behaves like
          %   1/(1 + w_unit*x_unit^3/lambda_unit)
          % as a function of the various units chosen
      u=((6*(1-p))*QtWQ+p*R)\diff(divdif);
   else
      u=((6*(1-p))*(Qtw*Qtw.')+p*R)\diff(divdif);
   end
   % ... and convert to pp form
   % Qt.'*u=diff([0;diff([0;u;0])./dx;0])
   yi = yi - ...
    (6*(1-p))*W*diff([zeros(1,yd)
                 diff([zeros(1,yd);u;zeros(1,yd)])./dx(:,dd)
                 zeros(1,yd)]);
   c3 = [zeros(1,yd);p*u;zeros(1,yd)];
   c2=diff(yi)./dx(:,dd)-dxol(:,dd).*(2*c3(1:n-1,:)+c3(2:n,:));
   if exist('lam','var')
      dxtl = dx.*lam;
      pp=ppmak(xi.',...
      reshape([(diff(c3)./dxtl(:,dd)).',3*(c3(1:n-1,:)./lam(:,dd)).', ...
                                    c2.',yi(1:n-1,:).'], (n-1)*yd,4),yd);
   else
      pp=ppmak(xi.',...
      reshape([(diff(c3)./dx(:,dd)).',3*c3(1:n-1,:).',c2.',yi(1:n-1,:).'],...
                                                            (n-1)*yd,4),yd);
   end
end

if ~isempty(origint), pp = fnchg(pp,'int',origint); end
if length(sizeval)>1, pp = fnchg(pp,'dz',sizeval); end

if isempty(xx)
   output = pp;
else
   output = fnval(pp,xx);
end

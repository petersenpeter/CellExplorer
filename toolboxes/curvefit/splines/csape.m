function pp = csape(x,y,conds,valconds)
%CSAPE Cubic spline interpolation with various end conditions.
%
%   PP  = CSAPE(X,Y)  returns the cubic spline interpolant (in ppform) to the 
%   given data (X,Y) using Lagrange end conditions (the default in table below).
%   The interpolant matches, at the data site X(j), the given data value
%   Y(:,j), j=1:length(X). The data values may be scalars, vectors, matrices,
%   or even ND-arrays. Data points with the same site are averaged.
%   For interpolation to gridded data, see below.
%
%   PP  = CSAPE(X,Y,CONDS)  uses the end conditions specified by CONDS, with
%   corresponding end condition values  endcondvals .
%   If there are two more data values than data sites, then the first (last) 
%   data value is taken as the value for the left (right) end condition, i.e.,
%   endcondvals = Y(:,[1 end]).
%   Otherwise, default values are used.
%
%   CONDS may be a *string* whose first character matches one of the
%   following: 'complete' or 'clamped', 'not-a-knot', 'periodic',
%   'second', 'variational', with the following meanings:
%
%   'complete'    : match endslopes (as given, with
%                   default as under *default*)
%   'not-a-knot'  : make spline C^3 across first and last interior
%                   break (ignoring given end condition values if any)
%   'periodic'    : match first and second derivatives at first data
%                   point with those at last data point
%                   (ignoring given end condition values if any)
%   'second'      : match end second derivatives (as given,
%                   with default [0 0], i.e., as in variational)
%   'variational' : set end second derivatives equal to zero
%                   (ignoring given end condition values if any)
%   The *default* : match endslopes to the slope of the cubic that
%                   matches the first four data at the respective end.
%
%   By giving CONDS as a 1-by-2 matrix instead, it is possible to
%   specify *different* conditions at the two endpoints, namely
%   CONDS(i) with value endcondvals(:,i), with i=1 (i=2) referring to the
%   left (right) endpoint.
%
%   CONDS(i)=j  means that the j-th derivative is being specified to
%   be endcondvals(:,i) , j=1,2.  CONDS(1)=0=CONDS(2)  means periodic end
%   conditions.
%
%   If CONDS(i) is not specified or is different from 0, 1 or 2, then
%   the default value for CONDS(i) is  1  and the default value of
%   endcondvals(:,i) is taken.  If no end condition values are specified,
%   then the default value for endcondvals(:,i) is taken to be
%
%    deriv. of cubic interpolant to nearest four points, if   CONDS(i)=1;
%                     0                                  if   CONDS(i)=2.
%
%   For backward compatibility, it is also possible to specify endcondvals as
%   an optional fourth input argument, but only for univariate data.
%   
%   It is also possible to handle gridded data, by having X be a cell array
%   containing  m  univariate meshes and, correspondingly, having Y be an
%   m-dimensional array (or an (m+length(d))-dimensional array if the function 
%   is to have values of size d ). 
%   Correspondingly, CONDS is a cell array with m entries, and,
%   consistent with the tensor product procedure used, also the tensor product
%   of the univariate end conditions is enforced and must be supplied with
%   values; see the example below.
%
%   For example,
%
%      fnplt(csape( [0:4], [1 0 -1 0 1;0 1 0 -1 0], 'periodic')), axis equal
%
%   plots a circle, while
%
%      x = linspace(0,2*pi,21);  pp = csape( x, [1 sin(x) 0], [1 2] );
%
%   gives a good approximation to the sine function on the interval [0 .. 2*pi]
%   (matching its slope 1 at the left endpoint, x(1) = 0, and its second 
%   derivative 0 at the right endpoint, x(21) = 2*pi, in addition to its value
%   at every x(i), i=1:21).
%
%   As an illustration of the specification of end conditions in a multivariate
%   setting, here is complete bicubic interpolation, with the data explicitly
%   derived from the bicubic polynomial  g(x,y) = x^3y^3, to make it easy for 
%   you to see exactly where the slopes and slopes of slopes (i.e., cross 
%   derivatives) must be placed in the data values supplied. Since our  g  is a
%   bicubic polynomial, its interpolant, f , must be  g  itself.  We test this.
%
%      sites = {[0 1],[0 2]}; coefs = zeros(4,4); coefs(1,1) = 1;
%      g = ppmak(sites,coefs);
%      Dxg = fnval(fnder(g,[1 0]),sites);
%      Dyg = fnval(fnder(g,[0 1]),sites);
%      Dxyg = fnval(fnder(g,[1 1]),sites);
%      f = csape(sites,[Dxyg(1,1),   Dxg(1,:),    Dxyg(1,2); ...
%                       Dyg(:,1), fnval(g,sites), Dyg(:,2) ; ...
%                       Dxyg(2,1),   Dxg(2,:),    Dxyg(2,2)], ...
%                                                {'complete','complete'});
%      if any(squeeze(fnbrk(f,'c'))-coefs), 'something went wrong', end
%
%   As a multivariate vector-valued example, here is a sphere, done as a 
%   parametric bicubic spline, using prescribed slopes in one direction and
%   periodic end conditions in the other:
%
%      x = 0:4; y=-2:2; s2 = 1/sqrt(2);
%      clear v
%      v(3,:,:) = [0 1 s2 0 -s2 -1 0].'*[1 1 1 1 1];
%      v(2,:,:) = [1 0 s2 1 s2 0 -1].'*[0 1 0 -1 0];
%      v(1,:,:) = [1 0 s2 1 s2 0 -1].'*[1 0 -1 0 1];
%      sph = csape({x,y},v,{'clamped','periodic'});
%      values = fnval(sph,{0:.1:4,-2:.1:2});
%    surf(squeeze(values(1,:,:)),squeeze(values(2,:,:)),squeeze(values(3,:,:)))
%      % the previous two lines could have been replaced by: fnplt(sph) 
%      axis equal, axis off
%
%   See also CSAPI, SPAPI, SPLINE.

%   The grandfathered CSAPE calling sequence:
%   CSAPE(X,Y,CONDS,VALCONDS) enables the user, in the case of univariate
%   data, to specify end condition values VALCONDS, with VALCONDS(:,j) the
%   value for the left (j=1) and right (j=2) end condition, respectively.

%   Copyright 1987-2010 The MathWorks, Inc.

%     Generate the cubic spline interpolant in ppform.

if nargin<3, conds = [1 1]; end

if iscell(x)       % we are dealing with gridded data

   m = length(x);
   sizey = size(y);
   if length(sizey)<m
     error(message('SPLINES:CSAPE:toofewdims')), end

   if length(sizey)==m,  % grid values of a scalar-valued function
     if issparse(y), y = full(y); end 
     sizey = [1 sizey]; 
   end

   sizeval = sizey(1:end-m); sizey = [prod(sizeval), sizey(end-m+(1:m))];
   y = reshape(y, sizey); 

   if ~iscell(conds), conds = num2cell(repmat(conds,m,1),2); end
   
   v = y; sizev = sizey;
   for i=m:-1:1   % carry out coordinatewise interpolation
      [b,v,l,k] = ppbrk(csape1(x{i}, ...
                   reshape(v,prod(sizev(1:m)),sizev(m+1)),conds{i}));
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

else         % we are dealing with univariate data

   if nargin<4
      pp = csape1(x,y,conds);
   else
      pp = csape1(x,y,conds,valconds);
   end
end

function pp = csape1(x,y,conds,valconds)
%     Generate the cubic spline interpolant in ppform.
% The fourth argument still permitted here for backward compatibility

[xi,yi,sizeval,endvals] = chckxywp(x,y,0);
if ~isempty(endvals), valconds = endvals.'; end
[yn,yd] = size(yi); dd = ones(1,yd);
dx = diff(xi); divdif = diff(yi)./dx(:,dd);

[n,yd] = size(yi); dd = ones(1,yd);

valsnotgiven=0;
if ~exist('valconds','var'), valsnotgiven=1;  valconds = zeros(yd,2); end
if ischar(conds)
   if     conds(1)=='c', conds = [1 1];
   elseif conds(1)=='n', pp = csapi(x,y); return
   elseif conds(1)=='p', conds = [0 0];
   elseif conds(1)=='s', conds = [2 2];
   elseif conds(1)=='v', conds = [2 2]; valconds = zeros(yd,2);
   else, error(message('SPLINES:CSAPE:unknownends', conds))
   end
end

   % set up the linear system for solving for the slopes at XI.
dx = diff(xi); divdif = diff(yi)./dx(:,dd);
c = spdiags([ [dx(2:n-1,1);0;0] ...
            2*[0;dx(2:n-1,1)+dx(1:n-2,1);0] ...
              [0;0;dx(1:n-2,1)] ], [-1 0 1], n, n);
b = zeros(n,yd);
b(2:n-1,:)=3*(dx(2:n-1,dd).*divdif(1:n-2,:)+dx(1:n-2,dd).*divdif(2:n-1,:));
if ~any(conds)
   c(1,1)=1; c(1,n)=-1;
elseif conds(1)==2
   c(1,1:2)=[2 1]; b(1,:)=3*divdif(1,:)-(dx(1)/2)*valconds(:,1).';
else
   c(1,1:2) = [1 0]; b(1,:) = valconds(:,1).';
   if (valsnotgiven||conds(1)~=1)  % if endslope was not supplied,
                                   % get it by local interpolation
     b(1,:)=divdif(1,:);
     if n>2, ddf=(divdif(2,:)-divdif(1,:))/(xi(3)-xi(1));
       b(1,:) = b(1,:)-ddf*dx(1); end
     if n>3, ddf2=(divdif(3,:)-divdif(2,:))/(xi(4)-xi(2));
       b(1,:)=b(1,:)+(ddf2-ddf)*(dx(1)*(xi(3)-xi(1)))/(xi(4)-xi(1)); end
   end
end
if ~any(conds)
   c(n,1:2)=dx(n-1)*[2 1]; c(n,n-1:n)= c(n,n-1:n)+dx(1)*[1 2];
   b(n,:) = 3*(dx(n-1)*divdif(1,:) + dx(1)*divdif(n-1,:));
elseif conds(2)==2
   c(n,n-1:n)=[1 2]; b(n,:)=3*divdif(n-1,:)+(dx(n-1)/2)*valconds(:,2).';
else
   c(n,n-1:n) = [0 1]; b(n,:) = valconds(:,2).';
   if (valsnotgiven||conds(2)~=1)  % if endslope was not supplied,
                                   % get it by local interpolation
      b(n,:)=divdif(n-1,:);
      if n>2, ddf=(divdif(n-1,:)-divdif(n-2,:))/(xi(n)-xi(n-2));
        b(n,:) = b(n,:)+ddf*dx(n-1); end
      if n>3, ddf2=(divdif(n-2,:)-divdif(n-3,:))/(xi(n-1)-xi(n-3));
        b(n,:)=b(n,:)+(ddf-ddf2)*(dx(n-1)*(xi(n)-xi(n-2)))/(xi(n)-xi(n-3));
      end
   end
end

  % solve for the slopes ..  (protect current spparms setting)
mmdflag = spparms('autommd');
spparms('autommd',0); % suppress pivoting
s=c\b;
spparms('autommd',mmdflag);

  %                          .. and convert to ppform
c4 = (s(1:n-1,:)+s(2:n,:)-2*divdif(1:n-1,:))./dx(:,dd);
c3 = (divdif(1:n-1,:)-s(1:n-1,:))./dx(:,dd) - c4;
pp = ppmak(xi.', ...
   reshape([(c4./dx(:,dd)).' c3.' s(1:n-1,:).' yi(1:n-1,:).'],(n-1)*yd,4),yd);
if length(sizeval)>1, pp = fnchg(pp,'dz',sizeval); end

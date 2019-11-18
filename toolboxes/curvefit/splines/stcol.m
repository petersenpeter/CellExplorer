function colmat = stcol(centers, x, varargin)
%STCOL Scattered translates collocation matrix.
%
%   COLMAT = STCOL(CENTERS, X, TYPE) returns the matrix whose (i,j)-entry is
%
%      psi_j( X(:,i) ),   i=1:size(X,2),  j=1:n ,
%
%   with psi_j and  n  depending on the CENTERS and on the string TYPE,
%   as detailed in STMAK.
%
%   CENTERS and X must be matrices with the same number of rows.  
%
%   The default for TYPE is 'tp', and, for this default, n is size(CENTERS,2)
%   and the functions psi_j are given by
%
%      psi_j(x) := psi( x - CENTERS(:,j) ),   j=1:n,
%
%   with psi the thin-plate spline basis function
%
%      psi(x) := |x|^2 log |x|^2 ,
%
%   and |x| denoting the Euclidean norm of the vector x.
%
%   COLMAT = STCOL(..., 'tr') returns the transpose of STCOL(...).
%
%   The matrix COLMAT is the coefficient matrix in the linear system
%
%      sum_j a_j psi_j(X(:,i))  =  y_i,    i=1:size(X,2)
% 
%   that the coefficients a_j of the function  f := sum_j a_j psi_j  must
%   satisfy in order that f interpolate the value y_i at the site X(:,i), 
%   all i.
%
%   Example.
%      a = [0,2/3*pi,4/3*pi]; centers = [cos(a), 0; sin(a), 0];
%      [x1,x2] = ndgrid(linspace(-2,2,45)); 
%      xx = [x1(:) x2(:)].';
%      coefs = [1 1 1 -3.5];
%      y = reshape( coefs*stcol(centers,xx,'tr'), size(x1));
%      surf(x1,x2,y), view([240,15]), axis off
%   evaluates and plots a weighted sum of four scattered translates
%   psi(x-centers(:,j)), j=1:4, of the thin-plate spline basis function.
%
%   See also STMAK, STBRK, STVAL, SPCOL.

%   Copyright 1987-2010 The MathWorks, Inc.

transp = 0; type = 'tp';
for j=1:nargin-2
   narg = varargin{j};
   if ~isempty(narg)&&ischar(narg)
      if isequal(narg(1:2),'tr'), transp = 1;
      else, type = narg;
      end
   end
end

[d,nc] = size(centers);
[dx,nx] = size(x);
if dx~=d
   error(message('SPLINES:STCOL:wrongsizeX', num2str( d ))), end

if transp
   temp = repmat(1:nx,nc,1);
   points = x(:,temp) - reshape(repmat(centers(:),1,nx),d,nx*nc);
else
   temp = nc; nc = nx; nx = temp;
   temp = repmat(1:nx,nc,1);
   points = reshape(repmat(x(:),1,nx),d,nx*nc) - centers(:,temp);
end
ap2 = sum(points.*points,1);

switch d
case 1
   ap = sqrt(ap2); 
   colmat = reshape(ap2.*ap,nc,nx); 
case 2
   ap2(find(ap2==0)) = 1;
   switch type
   case 'tp'
      colmat = reshape(ap2.*log(ap2),nc,nx); 
   case 'tp00'
      if transp
         colmat = [reshape(ap2.*log(ap2),nc,nx) ; x; ones(1,nx)]; 
      else
         colmat = [reshape(ap2.*log(ap2),nc,nx), x.', ones(nc,1)]; 
      end
   case 'tp10'
      if transp
         colmat = [reshape(2*(points(1,:).*(log(ap2)+1)),nc,nx); ones(1,nx)]; 
      else
         colmat = [reshape(2*(points(1,:).*(log(ap2)+1)),nc,nx), ones(nc,1)]; 
      end
   case 'tp01'
      if transp
         colmat = [reshape(2*(points(2,:).*(log(ap2)+1)),nc,nx); ones(1,nx)]; 
      else
         colmat = [reshape(2*(points(2,:).*(log(ap2)+1)),nc,nx), ones(nc,1)]; 
      end
   otherwise
      error(message('SPLINES:STCOL:unknowntype', type)) 
   end
otherwise
   error(message('SPLINES:STCOL:atmostbivar'))
end

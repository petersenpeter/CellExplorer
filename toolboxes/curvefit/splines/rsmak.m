function rs = rsmak(knots,varargin)
%RSMAK Put together rational spline in rBform.
%
%   RSMAK(KNOTS,COEFS) returns the rBform of the rational spline
%   specified by the input.
%
%   This is exactly the output of SPMAK(KNOTS,COEFS) except that it is tagged 
%   to be the B-form of a rational spline, namely the rational spline 
%   whose denominator is provided by the last component of the spline, while 
%   its remaining components describe the numerator. Correspondingly, the
%   dimension of its target is one less than it would be for the output of
%   SPMAK(KNOTS,COEFS).
%
%   In particular, the input coefficients must be (d+1)-vector valued for some
%   d>0 and cannot be ND-valued.
%
%   For example, since spmak([-5 -5 -5 5 5 5],[26 -24 26]) provides the B-form
%   of the polynomial t |-> t^2+1 on the interval [-5 .. 5], while 
%   spmak([-5 -5 -5 5 5 5], [1 1 1]) provides the B-form of the constant
%   function 1 there, the command
%
%      runge = rsmak([-5 -5 -5 5 5 5],[1 1 1; 26 -24 26]);
%
%   provides the rBform on the interval [-5 .. 5] for the rational function 
%   t |-> 1/(t^2+1)  famous from Runge's example concerning polynomial inter-
%   polation at equally spaced sites.
%
%   RSMAK(KNOTS,COEFS,SIZEC) is used when COEFS has trailing singleton
%   dimensions in which case SIZEC must be the vector giving the intended
%   size of COEFS. In particular, SIZEC(1) must be the actual first dimension
%   of COEFS, hence SIZEC(1)-1 is the dimension of the target.
%   
%   The rBform is the homogeneous version of a NURBS, in the sense that the
%   typical coefficient in the rBform has the form [w(i)*c(:,i);w(i)], with
%   c(:,i) the corresponding control point of the NURBS and w(i) its
%   corresponding weight.
%
%   RSMAK(OBJECT, ... ) returns the specific geometric shape specified
%   by the string OBJECT. For example,
%
%   RSMAK('circle',RADIUS,CENTER)  provides a quadratic rational spline
%   that describes the circle with given RADIUS (default 1) and CENTER
%   (default (0,0) ) .
%
%   RSMAK('arc',RADIUS,CENTER,[ALPHA BETA])  provides a quadratic rational 
%   spline that describes the arc, from ALPHA to BETA (default -pi/2 to pi/2),
%   of a circle with given RADIUS (default 1) and CENTER (default (0,0) ).
%   
%   RSMAK('cone',RADIUS,HEIGHT)  provides a quadratic rational spline
%   that describes the symmetric cone of given RADIUS (default 1) and 
%   half-height HEIGHT (default 1) centered on the z-axis with apex at (0,0,0).
%
%   RSMAK('cylinder',RADIUS,HEIGHT)  provides a quadratic rational spline
%   that describes the cylinder of given RADIUS (default 1) and 
%   height (default 1) centered on the z-axis.
%
%   RSMAK('torus',RADIUS,RATIO)  provides a quadratic rational spline
%   that describes the torus of given outer RADIUS (default 1) and inner
%   radius RADIUS*RATIO (default: RATIO = 1/3) that is centered at (0,0,0)
%   and with its major circle in the (x,y)-plane.
%
%   RSMAK('southcap',RADIUS,CENTER)  provides the south sixth of a sphere of 
%   given RADIUS (default 1) and given CENTER (default (0,0,0) ).
%
%   Use fncmb(rs,transf) to subject the resulting geometric objects to the
%   affine transformation specified by transf.  For example, the following 
%   generates a plot of 2/3 a sphere, as supplied by the `southcap', two 
%   of its rotates, and its reflection:
%
%      southcap = rsmak('southcap');
%      xpcap = fncmb(southcap,[0 0 -1;0 1 0;1 0 0]);
%      ypcap = fncmb(xpcap,[0 -1 0; 1 0 0; 0 0 1]);
%      northcap = fncmb(southcap,-1);
%      fnplt(southcap), hold on, fnplt(xpcap), fnplt(ypcap), fnplt(northcap)
%      axis equal, shading interp, view(-115,10), axis off, hold off
%
%   See also RSBRK, RPMAK, PPMAK, SPMAK, FNBRK.

%   Copyright 1999-2010 The MathWorks, Inc.

if ischar(knots)
             % set defaults for input if needed
   if isempty(varargin) 
      radius = 1;
   else
      radius = varargin{1}; 
      if length(varargin)>1, arg2 = varargin{2}; end
   end

   switch knots
   
   case 'circle' % follow Farin and Lee, representing the circle as
                 % four quadratic BB-patches

      if ~exist('arg2','var'), arg2 = [0;0]; end

      oo = 1/sqrt(2);
      x = radius*[1 1 0 -1 -1 -1  0  1 1]+arg2(1); 
      y = radius*[0 1 1  1  0 -1 -1 -1 0]+arg2(2);
      w =        [1 oo 1 oo 1 oo 1 oo 1];
      rs = spmak(augknt(0:4,3,2),[x.*w;y.*w;w]);
      rs.form = 'rB';
      rs.dim = 2;

    case 'arc'  % follow Hoschek, Farin and others in representing a 
                % short enough arc  (i.e., of angle <= pi) as a
                % rational quadratic. Subdivide larger angles.
       
      if ~exist('arg2','var'), arg2 = [0;0]; end
      if length(varargin)==3, reach = varargin{3};
         if length(reach)==1, reach = [reach,reach]; end
      elseif length(varargin)==4 % then, for backward compatibility
         reach = [varargin{3},varargin{4}];
         % must make sure that alpha and beta are within pi of each other
         reach = sort(mod(reach,2*pi));
         if diff(reach) > pi, reach(2) = reach(2)-2*pi; end
      else reach = [-pi/2 pi/2]; end

      npieces = max(1,ceil(2*abs(diff(reach))/pi));
      halfangles = linspace(reach(1),reach(2),1+npieces*2);
      oo = cos(diff(halfangles(1:2)));
      w = [repmat([1 oo],1,npieces),1];
      rs = spmak(augknt(0:npieces,3,2), ...
          [radius*[cos(halfangles);sin(halfangles)] ...
	   + [arg2, repmat([oo*arg2 arg2],1,npieces)]; w]);
      rs.form = 'rB';
      rs.dim = 2;

   case 'torus' % can think of it as a centered circle parallel to the 
            % (x,y)-plane whose radius and difference from the (x,y)-plane
            % also forms a (smaller) off-centered circle. 
            % Hence, with (c_x,c_y)/w the centered circle written as a
            % vector-valued rational spline, and (d_x,d_y)/w the smaller,
            % off-centered circle, the torus is (c_xd_x,c_yd_x,wd_y)/(ww)
            % (with all products here tensor products of univariate
            % functions).

      if ~exist('arg2','var'), arg2 = 1/3; end
      circle = rsmak('circle');
      [coefs,knots] = fnbrk(circle,'coefs','knots');
      r = radius*(1-arg2)/2;
      % must choose the center (c,0) and radius r of the circle formed by
      % radius and height of the centered circle in such a way that
      % c+r = RADIUS and c-r = arg2*RADIUS.
      cd = [coefs(3,:)*(radius*(1+arg2)/2) + r*coefs(1,:); r*coefs(2,:) ];
      % now use the fact that the coefficient vector in the B-form of the
      % tensor product of two splines is the outer product of the coefficient
      % vectors of the two univariate splines.
      newcoefs = zeros(4,size(coefs,2),size(coefs,2));
      newcoefs(1,:,:) = coefs(1,:).'*cd(1,:);
      newcoefs(2,:,:) = coefs(2,:).'*cd(1,:);
      newcoefs(3,:,:) = coefs(3,:).'*cd(2,:);
      newcoefs(4,:,:) = coefs(3,:).'*coefs(3,:);
      rs = spmak({knots,knots},newcoefs);
      rs.form = 'rB';
      rs.dim = 3;

   case 'cylinder' % follow Tony DeRose, taking the tensor product of a circle
                   % with a line.
   
      if ~exist('arg2','var'), arg2 = 1; end
      circle = rsmak('circle',radius,[0;0]);
      [coefs,knots] = fnbrk(circle,'coefs','knots');
      newcoefs = zeros(4,size(coefs,2),2);
      newcoefs([1 2 4],:,1) = coefs;
      newcoefs([1 2 4],:,2) = coefs;
      newcoefs(3,:,2) = arg2*coefs(3,:);
      rs = spmak({knots,[0 0 1 1]},newcoefs);
      rs.form = 'rB';
      rs.dim = 3;

   case 'cone' % analogous to `cylinder'
   
      if ~exist('arg2','var'), arg2 = 1; end
      circle = rsmak('circle',radius,[0;0]);
      [coefs,knots] = fnbrk(circle,'coefs','knots');
      newcoefs = zeros(4,size(coefs,2),2);
      newcoefs([1 2 4],:,2) = coefs;
      newcoefs(3,:,2) = arg2.*coefs(3,:);
      newcoefs(1:3,:,1) = -newcoefs(1:3,:,2);
      newcoefs(4,:,1) = coefs(3,:);
      rs = spmak({knots,[0 0 1 1]},newcoefs);
      rs.form = 'rB';
      rs.dim = 3;

   case 'southcap' % the south sixth of a sphere, as given by J. Cobb in
                   % `A rational bicubic representation of the sphere',
                   % TR, Computer Science, U.Utah, 1988, as quoted (with one 
                   % excessive minus sign) in G. Farin, NURBS, AKPeters, 1999.

      s = sqrt(2); t = sqrt(3); u = -5*sqrt(6)/3;
      coefs = zeros([4,5,5]);
      coefs(:,:,1) = [4*(1-t) -s        0             s         4*(t-1)
                      4*(1-t) s*(t-4)   (4/3)*(1-2*t) s*(t-4)   4*(1-t)
                      4*(1-t) s*(t-4)   (4/3)*(1-2*t) s*(t-4)   4*(1-t)
                      4*(3-t) s*(3*t-2) (4/3)*(5-t)   s*(3*t-2) 4*(3-t)];

      coefs(:,:,2) = [s*(t-4) (2-3*t)/2 0             (3*t-2)/2 s*(4-t)
                      -s      (2-3*t)/2 s*(2*t-7)/3   (2-3*t)/2 -s
                      s*(t-4) -(t+6)/2  u             -(t+6)/2  s*(t-4)
                      s*(3*t-2) (t+6)/2 s*(t+6)/3     (t+6)/2   s*(3*t-2)];

      coefs(:,:,3) = [4*(1-2*t)/3 s*(2*t-7)/3 0 -s*(2*t-7)/3 -4*(1-2*t)/3
                      0       0         0             0         0
                      4*(1-2*t)/3 u      4*(t-5)/3    u        4*(1-2*t)/3
                      4*(5-t)/3   s*(t+6)/3 4*(5*t-1)/9 s*(t+6)/3 4*(5-t)/3];

      coefs(:,:,4) = [s*(t-4) (2-3*t)/2 0             (3*t-2)/2 s*(4-t)
                      s      -(2-3*t)/2 -s*(2*t-7)/3 -(2-3*t)/2 s
                      s*(t-4) -(t+6)/2  u             -(t+6)/2  s*(t-4)
                      s*(3*t-2) (t+6)/2 s*(t+6)/3     (t+6)/2   s*(3*t-2)];

      coefs(:,:,5) = [4*(1-t) -s        0             s         4*(t-1)
                      4*(t-1) s*(4-t)   (4/3)*(2*t-1) s*(4-t)   4*(t-1)
                      4*(1-t) s*(t-4)   (4/3)*(1-2*t) s*(t-4)   4*(1-t)
                      4*(3-t) s*(3*t-2) (4/3)*(5-t)   s*(3*t-2) 4*(3-t)];

      if radius~=1
         coefs(1:3,:,:) = radius*coefs(1:3,:,:);
      end
      knots = [-1 -1 -1 -1 -1 1 1 1 1 1];
      rs = spmak({knots,knots},coefs);
      rs.form = 'rB';
      rs.dim = 3;
      if exist('arg2','var')&&any(arg2), rs = fncmb(rs,arg2); end

   otherwise
      error(message('SPLINES:RSMAK:unknowntype', knots))
   end

else
   rs = spmak(knots,varargin{:});
   dp1 = fnbrk(rs,'dim');
   if length(dp1)>1
      error(message('SPLINES:RSMAK:onlyvec'))
   end
   if dp1==1
      error(message('SPLINES:RSMAK:needmorecomps'))
   end
   rs.dim = dp1-1; rs.form = 'rB';
end

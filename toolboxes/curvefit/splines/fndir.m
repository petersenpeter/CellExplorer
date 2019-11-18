function fdir = fndir(f,direction)
%FNDIR Directional derivative of a function.
%
%   FNDIR(F,DIRECTION)  returns the (ppform of the) derivative in the given 
%   DIRECTION(s) of the function contained in F (and of the same order).
%   If the function in F is m-variate, then DIRECTION must be a (list of)
%   m-vector(s), i.e., of size [m,nd] for some nd. 
%
%   Assuming the function in F to be m-variate and d-valued, FDIR describes
%   the (prod(d)*nd)-valued function whose value V at a point X, reshaped as
%   an array of size [d,nd], provides in its j-th `column' V(:,j) the 
%   derivative, at X and of the function in F, in the direction
%   DIRECTION(:,j), j=1:nd.
%   If you prefer the function returned to reflect fully the dimensions of 
%   F's target, use instead
%
%      fdir = fnchg( fndir(f,direction), ...
%                    'dim',[fnbrk(f,'dim'),size(direction,2)] );
%
%   FNDIR does not work for rational splines; for them, use FNTLR instead.
%
%   Example: If  f  describes an m-variate d-vector-valued function and 
%    x  is some point in its domain, then
%  
%      reshape(fnval(fndir(f,eye(m)),x),d,m)
%
%   is the Jacobian of that function at that point. 
%   As a related example, the next statements plot the gradients of (a good 
%   approximation to) the Franke function at a regular mesh: 
%
%      xx = linspace(-.1,1.1,13); yy = linspace(0,1,11);
%      [x,y] = ndgrid(xx,yy); z = franke(x,y);
%      pp2dir = fndir(csapi({xx,yy},z),eye(2));
%      grads = reshape(fnval(pp2dir,[x(:) y(:)].'),[2,length(xx),length(yy)]);
%      quiver(x,y,squeeze(grads(1,:,:)),squeeze(grads(2,:,:)))
%
%   See also FNDER, FNTLR, FNINT.

%   Copyright 1987-2010 The MathWorks, Inc.

if nargin<2
   error(message('SPLINES:FNDIR:needdir')), end

if ~isstruct(f), f = fn2fm(f); end

try %treat the function as vector-valued if it is not
   sizeval = fnbrk(f,'dim');
   if length(sizeval)>1, f = fnchg(f,'dz',prod(sizeval)); end
catch
   error(message('SPLINES:FNDIR:unknownform', f.form))
end

if f.form(1)=='B', f = fn2fm(f,'pp'); end

switch f.form(1:2)
case 'pp' % the function is in ppform:

   if fnbrk(f,'var')>1 % the function is multivariate
      [breaks,coefs,l,k,d] = ppbrk(f);
      m = length(k);
      dirsize = size(direction);
      if dirsize(1)~=m
         error(message('SPLINES:FNDIR:mustbevec', num2str( m )))
      end
      sizec = [d,l.*k]; %size(coefs); 
      fdirc = zeros([sizec,dirsize(2)]);
      for i=m:-1:1
         dd = prod(sizec(1:m));
         if any(direction(i,:))~=0
            dpp = fndirp(ppmak(breaks{i},reshape(coefs,dd*l(i),k(i)),dd));
            %fdirc = fdirc + direction(i)*reshape(dpp.coefs,sizec);
            fdirc = fdirc + ...
                    reshape(dpp.coefs(:)*direction(i,:),[sizec,dirsize(2)]);
         end
         if m>1
            sizec(2:m+1) = sizec([m+1,2:m]);
            coefs = permute(coefs,[1,m+1,2:m]);
            fdirc = permute(fdirc,[1,m+1,2:m,m+2]);
         end
      end
      sizec(1) = d*dirsize(2);
      if m>1&&dirsize(2)>1
         fdir = ppmak(breaks,reshape(permute(fdirc,[1,m+2,2:m+1]),sizec),sizec);
      else
         fdir = ppmak(breaks,fdirc,sizec);
      end
   else
      fdir = fncmb(fndirp(f),direction);
   end
case {'rB','rp'}
   error(message('SPLINES:FNDIR:notforrs'))
case 'st'
   error(message('SPLINES:FNDIR:notforst'))
otherwise
   error(message('SPLINES:FNDIR:unknownfn'))
end

function fprime = fndirp(f)
%FNDIRP Differentiate a univariate function in ppform, but keep its order.
[breaks,coefs,l,k,d] = ppbrk(f);
fprime = ppmak(breaks, ...
               [zeros(d*l,1),coefs(:,1:k-1).*repmat([k-1:-1:1],d*l,1)],d);

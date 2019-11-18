function v = ppual(pp,x,left)
%PPUAL Evaluate function in ppform.
%
%   This is the function used by FNVAL when a spline in ppform is to be
%   evaluated.
%
%   V = PPUAL(PP,X)  returns the value, at the entries of X, of the
%   function  f  whose ppform is in PP.
%   V = PPUAL(PP,X,'l<anything>')  takes  f  to be left-continuous.
%   If  f  is m-variate and the third input argument is actually an m-cell,
%   LEFT say, then, continuity from the left is enforced in the i-th
%   variable if  LEFT{i}(1) = 'l'.
%
%   Roughly speaking, V is obtained by replacing each entry of X by the value
%   of  f  there. The details, as laid out in the help for FNVAL, depend on
%   whether or not  f  is scalar-valued and whether or not  f  is univariate.
%
%   See also FNVAL, SPVAL, RSVAL, STVAL, PPVAL.

%   Copyright 1987-2010 The MathWorks, Inc.

if ~isstruct(pp), pp = fn2fm(pp); end

if iscell(pp.breaks)   % we are dealing with a multivariate spline

   [breaks,coefs,l,k,d] = ppbrk(pp); m = length(breaks);
   sizec = [d,l.*k]; % size(coefs)

   if nargin>2 % set up LEFT appropriately
      if ~iscell(left)
         temp = left; left = cell(1,m); [left{:}] = deal(temp);
      end
   else
      left = cell(1,m);
   end

   if iscell(x)  % evaluation on a mesh

      if length(x)~=m
         error(message('SPLINES:PPUAL:needgrid', num2str( m )))
      end

      v = coefs; sizev = sizec;
      nsizev = zeros(1,m);
      for i=m:-1:1
         nsizev(i) = length(x{i}(:)); dd = prod(sizev(1:m));
         v = reshape(ppual1(...
              ppmak(breaks{i},reshape(v,dd*l(i),k(i)),dd), x{i}, left{i} ),...
                [sizev(1:m),nsizev(i)]);
         sizev(m+1) = nsizev(i);
         if m>1
            v = permute(v,[1,m+1,2:m]); sizev(2:m+1) = sizev([m+1,2:m]);
         end
      end
      if d>1
         v = reshape(v,[d,nsizev]);
      else
         v = reshape(v,nsizev);
      end

   else          % evaluation at scattered points

      % locate the scattered data in the break sequences:
      [mx,n] = size(x);
      if mx~=m, error(message('SPLINES:PPUAL:wrongx', num2str( m ))), end

      ix = zeros(m,n);
      for i=1:m
         [ox,iindex] = sort(x(i,:));
         ix(i,iindex) = get_index(breaks{i}(2:end-1),ox,left{i});
      end

      % ... and now set up lockstep polynomial evaluation
      % %%First,  select the relevant portion of the coefficients array.
      % This has the additional pain that now there are k(i) coefficients
      % for the i-th univariate interval.
      % The coefficients sit in the (m+1)-dimensional array COEFS, with
      % the (i+1)st dimension containing the coefficients in the i-th
      % dimension, and organized to have first the highest coefficients
      % for each interval, then the next-highest, etc (i.e., as if coming
      % from an array of size [l(i),k(i)]).
      % ix(:,j) is the index vector for the lower corner of j-th point
      % The goal is to extract, for the j-th point, the requisite coefficients
      % from the equivalent one-dimensional array for COEFS, computing a
      % base index from ix(:,j), and adding to this the same set of offsets
      % computed from the l(i) and k(i).

      temp = l(1)*(0:k(1)-1)';
      for i=2:m
         lt = length(temp(:,1));
         temp = [repmat(temp,k(i),1), ...
                 reshape(repmat(l(i)*(0:k(i)-1),lt,1),k(i)*lt,1)];
      end
      % also take care of the possibility that the function in PP is
      % vector-valued:
      lt = length(temp(:,1));
      temp=[reshape(repmat((0:d-1).',1,lt),d*lt,1) temp(repmat(1:lt,d,1),:)];

      temp = num2cell(1+temp,1);
      offset = repmat(reshape(sub2ind(sizec,temp{:}),d*prod(k),1),1,n);

      temp = num2cell([ones(n,1) ix.'],1);
      base = repmat(sub2ind(sizec,temp{:}).',d*prod(k),1)-1;
      v = reshape(coefs(base+offset),[d,k,n]);

      % ... then do a version of local polynomial evaluation
      for i=m:-1:1
         s = reshape(x(i,:) - breaks{i}(ix(i,:)),[1,1,n]);
         otherk = d*prod(k(1:i-1));
         v = reshape(v,[otherk,k(i),n]);
         for j=2:k(i)
            v(:,1,:) = v(:,1,:).*repmat(s,[otherk,1,1])+v(:,j,:);
         end
         v(:,2:k(i),:) = [];
      end
      v = reshape(v,d,n);
   end
else
   if nargin<3, left = []; end
   v = ppual1(pp,x,left);
end

function v = ppual1(pp,x,left)
%PPUAL1 Evaluate univariate function in ppform.

[mx,nx] = size(x); lx = mx*nx; xs = reshape(x,1,lx);

%  take apart PP
[breaks,c,l,k,d] = ppbrk(pp);
%  if there are no points to evaluate at, return empty matrix of appropriate
%  size.
if lx==0, v = zeros(d,0); return, end

% for each data site, compute its break interval
[index,NaNx] = get_index(breaks(2:end-1),xs,left);
index(NaNx) = 1;

% now go to local coordinates ...
xs = xs-breaks(index);
if d>1 % ... replicate XS and INDEX in case PP is vector-valued ...
   xs = reshape(repmat(xs,d,1),1,d*lx);
   index = reshape(repmat(1+d*index,d,1)+repmat((-d:-1).',1,lx), d*lx, 1 );
end
% ... and apply nested multiplication:
v = c(index,1).';
for i=2:k
   v = xs.*v + c(index,i).';
end

if ~isempty(NaNx) && k==1 && l>1, v = reshape(v,d,lx); v(:,NaNx) = NaN; end
v = reshape(v,d*mx,nx);

function [index,NaNx] = get_index(mesh,sites,left)
%GET_INDEX appropriate mesh intervals for given ordered data sites

if isempty(left)||left(1)~='l'
   [~, index] = histc(sites,[-inf,mesh,inf]);
   NaNx = find(index==0); index = min(index,numel(mesh)+1);
else
   [~, index] = histc(-sites,[-inf,-fliplr(mesh),inf]);
   NaNx = find(index==0); index = max(numel(mesh)+2-index,1);
end

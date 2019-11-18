function v = spval(sp,x,left)
%SPVAL Evaluate function in B-form.
%
%   This is the function used by FNVAL when a spline in B-form is to be
%   evaluated.
%
%   V = SPVAL(SP,X)  returns the value, at the entries of X, of the
%   function  f  whose B-form is in SP.
%   V = SPVAL(SP,X,'l<anything>')  takes  f  to be left-continuous.
%   If  f  is m-variate and the third input argument is actually an m-cell,
%   LEFT say, then, continuity from the left is enforced in the i-th 
%   variable if  LEFT{i}(1) = 'l'.  
%
%   Roughly speaking, V is obtained by replacing each entry of X by the value
%   of  f  there. The details, as laid out in the help for FNVAL, depend on
%   whether or not  f  is scalar-valued and whether or not  f  is univariate.
%
%   See also FNVAL, PPUAL, RSVAL, STVAL, PPVAL.

%   Copyright 1987-2010 The MathWorks, Inc.

if ~isstruct(sp)
   error(message('SPLINES:SPVAL:fnnotstruct')), end
if iscell(sp.knots)  % we are dealing with a tensor product spline

   [t,a,n,~,d] = spbrk(sp); m = length(t);

   if nargin>2 % set up left appropriately
      if ~iscell(left)
         temp = left; left = cell(1,m); [left{:}] = deal(temp);
      end
   else
      left = cell(1,m);
   end

   if iscell(x)  % evaluation on a mesh

      v = a; sizev = [d,n]; nsizev = zeros(1,m);

      for i=m:-1:1
         nsizev(i) = length(x{i}(:));
         v = reshape(...
         spval1(spmak(t{i},reshape(v,prod(sizev(1:m)),sizev(m+1))), ...
                 x{i},left{i}),   [sizev(1:m),nsizev(i)]);
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
 
   else          % evaluation at scattered points;
                 % this will eventually be done directly here.
      v = ppual(sp2pp(sp),x);
      temp = cell2mat(fnbrk(sp,'interv')).'; mm = 2:2:(2*m); nx = size(x,2);
      v(min([x-repmat(temp(mm-1),1,nx); repmat(temp(mm),1,nx)-x])<0) = 0;
   end

else                 % we are dealing with a univariate spline
   if nargin<3, left = []; end
   v = spval1(sp,x,left);
end

function v = spval1(sp,x,left)
%SPVAL1 Evaluate univariate function in B-form.

[mx,nx] = size(x); lx = mx*nx; xs = reshape(x,1,lx);

%  Take apart spline:
[t,a,n,k,d] = spbrk(sp);
%  If there are no points to evaluate at, return empty matrix of appropriate
%  size:
if lx==0, v = zeros(d,0); return, end

%  Otherwise, augment the knot sequence so that first and last knot each
%  has multiplicity  >= K . (AUGKNT would not be suitable for this since
%  any change in T must be accompanied by a corresponding change in A.)

index = find(diff(t)>0); addl = k-index(1); addr = index(end)-n;
if ( addl>0 || addr>0 )
   npk = n+k; t = t([ones(1,addl) 1:npk npk(ones(1,addr))]);
   a = [zeros(d,addl) a zeros(d,addr)];
   n = n+addl+addr;
end

% For each data point, compute its knot interval:
if isempty(left)||left(1)~='l'
   [~, index] = histc(xs,[-inf,t(k+1:n),inf]);
   NaNx = find(index==0); index = min(index+(k-1),n);
else
   [~, index] = histc(-xs,[-inf,-fliplr(t(k+1:n)),inf]);
   NaNx = find(index==0); index = max(n+1-index,k);
end
if ~isempty(NaNx), index(NaNx) = k; end

% Now, all is ready for the evaluation.
if  k>1  % carry out in lockstep the first spline evaluation algorithm
         % (this requires the following initialization):
   dindex = reshape(repmat(index,d,1),d*lx,1);
   tx =reshape(t(repmat(2-k:k-1,d*lx,1)+repmat(dindex,1,2*(k-1))),d*lx,2*(k-1));
   tx = tx - repmat(reshape(repmat(xs,d,1),d*lx,1),1,2*(k-1));
   dindex = reshape(repmat(d*index,d,1)+repmat((1-d:0).',1,lx),d*lx,1);
   b = repmat(d*(1-k):d:0,d*lx,1)+repmat(dindex,1,k);
   a = a(:); b(:) = a(b);

   % (the following loop is taken from SPRPP)

   for r = 1:k-1
      for i = 1:k-r
         b(:,i) = (tx(:,i+k-1).*b(:,i)-tx(:,i+r-1).*b(:,i+1)) ./ ...
                  (tx(:,i+k-1)    -    tx(:,i+r-1));
      end
   end

   v = reshape(b(:,1),d,lx);
else     % the spline is piecewise constant, hence ...
   v = a(:,index);
   if ~isempty(NaNx), v(:,NaNx) = NaN; end
end

% Finally, zero out all values for points outside the basic interval:
index = find(x<t(1)|x>t(n+k));
if ~isempty(index)
   v(:,index) = zeros(d,length(index));
end
v = reshape(v,d*mx,nx);

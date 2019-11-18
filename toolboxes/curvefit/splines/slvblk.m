function x = slvblk(blokmat,b,w)
%SLVBLK Solve almost block-diagonal linear system.
%
%   SLVBLK(BLOKMAT,B)  returns the solution (if any) of the linear system  
%   A*X=B, with the matrix A stored in BLOKMAT in the spline almost block
%   diagonal form (as generated, e.g., in SPCOL).
%
%   If the system is overdetermined (i.e., has more equations than
%   unknowns), the least-squares solution is returned.  
%
%   SLVBLK(BLOKMAT,B,W)  returns the vector X that minimizes the 
%   weighted l_2 sum
%
%      sum_j W(j)*( (A*X-B)(j) )^2 .
%
%   This is useful when the system is overdetermined.
%   The default for W is the sequence [1,1,1,...].
%
%   Example:
%   The following statements generate some noisy data, then use SLVBLK to
%   determine the least-squares approximation, weighted by the weights of
%   the composite trapezoidal rule, to those data by cubic splines with
%   two uniformly spaced knots, and plot the results:
%   
%      x = [0,sort(rand(1,31)),1]*(2*pi);
%      y = sin(x)+(rand(1,33)-.5)/10;
%      k = 4; knots = augknt(linspace(x(1),x(end),3),k);
%      dx = diff(x); w = ([dx 0] + [0 dx])/2;
%      sp = spmak(knots,slvblk(spcol(knots,k,x,'slvblk','noderiv'),y.',w).');
%      fnplt(sp,2); hold on, plot(x,y,'ok'), hold off
%
%   See also SPCOL, SPAPS, SPAPI, SPAP2.

%   Copyright 1987-2008 The MathWorks, Inc.

% If BLOKMAT is sparse, handle the problem sparsely:
if issparse(blokmat)
   if nargin>2&&~isempty(w)
      n = length(w); spw = sparse(1:n,1:n,sqrt(w));
      x = (spw*blokmat)\(spw*b);
   else
      x = blokmat\b;
   end
   return
end

% get the basic information
[nb,rows,ncols,last,blocks] = bkbrk(blokmat);

ne = sum(rows);nu = sum(last);
if any(cumsum(rows)<cumsum(last))||any(last>ncols)
   error(message('SPLINES:SLVBLK:matrixnot11'))
end

[brow,bcol] = size(b);
if(ne~=brow)
   error(message('SPLINES:SLVBLK:wrongrightside'))
end

blocks = [blocks b];
ccols = ncols+bcol;
if nargin>2, w = sqrt(w); blocks = repmat(w(:),1,ccols).*blocks; end

f = 1; l = 0; elim = 0;
for j=1:nb
   if (f<=l) % shift the rows still remaining from previous block
      blocks(f:l,:) = ...
         [blocks(f:l,elim+1:ncols) zeros(l+1-f,elim),blocks(f:l,ncols+1:ccols)];
   end
   l = l+rows(j);

   elim = last(j);
   % ideally, one would now use
   %   [q,r] = qr(blocks(f:l,1:elim));
   % followed up by
   %   blocks(f:l,:) = q'*blocks(f:l,:);
   %   f = f+elim;
   % but, unfortunately, this generates the possibly very large square matrix q
   % The unhappy alternative is to do the elimination explicitly here, using
   % Householder reflections (and an additional inner loop):
   for k=1:elim
      a = norm(blocks(f:l,k));
      vv = abs(blocks(f,k))+a;
      c = vv*a;
      if blocks(f,k)<0, vv = -vv; end
      q = [vv;blocks(f+1:l,k)];
      blocks(f:l,:) = ...
       blocks(f:l,:)-repmat(q/c,1,ccols).*repmat(q'*blocks(f:l,:),l+1-f,1);
       %blocks(f:l,:)-((q/c)*ones(1,ccols)).*(ones(l+1-f,1)*(q'*blocks(f:l,:)));
      f = f+1;
   end
end

% now we are ready for back-substitution
x = zeros(f-elim-1+ncols,bcol);

for j=nb:-1:1
   elim = last(j); l = f-1; f = f-elim;
   % here is another occasion where empty matrices of various sizes would help;
   % instead, use an if statement:
   if elim<ncols, blocks(f:l,ncols+1:ccols) = blocks(f:l,ncols+1:ccols) ...
                    - blocks(f:l,elim+1:ncols)*x(f-1+[elim+1:ncols],:); end
   x(f:l,:) = blocks(f:l,1:elim) \ blocks(f:l,ncols+1:ccols);
end
x = x(1:nu,:);

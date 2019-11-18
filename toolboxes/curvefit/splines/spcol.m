function colloc = spcol(knots,k,tau,varargin)
%SPCOL B-spline collocation matrix.
%
%   COLLOC = SPCOL(KNOTS,K,TAU)  is the matrix 
%
%      [ D^m(i)B_j(TAU(i)) : i=1:length(TAU), j=1:length(KNOTS)-K ] ,
%
%   with  D^m(i)B_j  the m(i)-fold derivative of B_j,
%   B_j  the j-th B-spline of order K for the knot sequence KNOTS,
%   TAU a sequence of sites, 
%   both KNOTS and TAU are assumed to be nondecreasing, and
%   m(i) is the integer #{ j<i : TAU(j) = TAU(i) }, i.e., the 'cumulative'
%   multiplicity of TAU(i) in TAU.
%
%   This means that the j-th column of COLLOC contains values and, perhaps,
%   derivatives, at all the entries of the vector TAU, of the j-th
%   B-spline of order K for the sequence KNOTS, i.e., the B-spline
%   with knots KNOTS(j:j+K).
%   The i-th row of COLLOC contains the value at TAU(i) of the m(i)-th
%   derivative of all these B-splines, with  m(i)  the number of earlier
%   entries of TAU that equal  TAU(i) .
%
%   Example:
%      tau = [0,0,0,1,1,2];          %  therefore,   m equals [0,1,2,0,1,0] 
%      k = 3; knots = augknt(0:2,k); %  therefore, knots equals [0,0,0,1,2,2,2]
%      colloc = spcol(knots,k,tau)
%
%   has the 6 entries of COLLOC(:,j) contain the value, first, and second
%   derivative of B_j at 0, then the value and first derivative of B_j
%   at 1, and, finally, the value of B_j at 2, with B_j the j-th B-spline of
%   order k for the knot sequence knots; e.g., B_2 is the B-spline with 
%   knots 0,0,1,2. 
%
%   You can use COLLOC to construct splines with prescribed values and,
%   perhaps, also some derivatives, at prescribed sites.
%
%   Example:
%      a = -pi; b = pi;  tau = [a a a 0 b b]; k = 5;
%      knots = augknt([a,0,b],k);
%      sp = spmak(knots, ( spcol(knots,k,tau) \ ...
%          [sin(a);cos(a);-sin(a);sin(0);sin(b);cos(b)] ).' )
%
%   provides the quartic spline, on the interval [a,b] with just one interior
%   knot, at 0, that interpolates the sine function at a,0,b, but also matches
%   its first and second derivative at  a , and its first derivative at  b .
%      
%   COLLOC = SPCOL(KNOTS,K,TAU,ARG1,ARG2,...)  provides the same or a related
%   matrix, depending on the optional arguments  ARG1, ARG2, ... .
%
%   If one of the optional arguments is 'slvblk', then COLLOC is in the al-
%   most block-diagonal format (specialized for splines) required by SLVBLK.
%
%   If one of the optional arguments is 'sparse', then COLLOC is a sparse
%   matrix.
%
%   If one of the optional arguments is 'noderiv', then multiplicities are
%   ignored, i.e., m(i) = 0 for all i.
%
%   The B-spline recurrence relations are used to generate the entries of the
%   matrix.
%
%   Example:
%      t = [0,1,1,3,4,6,6,6]; x = linspace(t(1),t(end),101); 
%      c = spcol(t,3,x); plot(x,c)
%
%   uses SPCOL to generate, in c(:,j), a fine sequence of values of the 
%   j-th quadratic B-spline for the given knot sequence t.
%
%   See also SLVBLK, SPARSE, SPAPI, SPAP2, BSPLINE.

%   Copyright 1987-2010 The MathWorks, Inc.

if ~isempty(find(diff(knots)<0))
   error(message('SPLINES:SPCOL:knotsdecreasing'))
end
if ~isempty(find(diff(tau)<0))
   error(message('SPLINES:SPCOL:TAUdecreasing'))
end

%  Compute the number  n  of B-splines of order K supported by the given
%  knot sequence and return an empty matrix in case there aren't any.

npk=length(knots); n=npk-k;
if n<1, warning(message('SPLINES:SPCOL:noBsplines'))
   colloc = zeros(length(tau),0); return
end

% Settle the options:
slvblk=0; noderiv=0;
for j=4:nargin
   argj = varargin{j-3};
   if ~isempty(argj)
      if ischar(argj)
         if     argj(1)=='s', slvblk=1;
            if length(argj)>1, if argj(2)=='p', slvblk=2; end, end
         elseif argj(1)=='n', noderiv=1;
         else error(message('SPLINES:SPCOL:wronginarg2'))
         end
      else 
         switch j  % for backward compatibility
         case 4,  slvblk=1; 
         case 5,  noderiv=1;
         end
      end
   end
end

% If  NODERIV==0, remove all multiplicities from TAU and generate repetitions
% of rows instead of rows containing values of successive derivatives.
nrows = length(tau); tau = reshape(tau,1,nrows);
if noderiv
   index = 1:nrows; m = ones(1,nrows); nd = 1; pts = tau;
else
   index = [1 find(diff(tau)>0)+1];
   m = diff([index nrows+1]); nd = max(m);
   if nd>k
      error(message('SPLINES:SPCOL:multtoohigh', sprintf( '%g', k )));
   end
   pts = tau(index);
end

%set some abbreviations
km1 = k-1;

%  augment knot sequence to provide a K-fold knot at each end, in order to avoid
% struggles near ends of basic interval,  [KNOTS(1) .. KNOTS(npk)] .
% The resulting additional B-splines, if any, will NOT appear in the output.

[augknot,addl] = augknt(knots,k); naug = length(augknot)-k;
pts = pts(:); augknot = augknot(:);

%  For each  i , determine  savl(i)  so that  K <= savl(i) < naug+1 , and,
% within that restriction,
%        augknot(savl(i)) <= pts(i) < augknot(savl(i)+1) .

savl = max(sorted(augknot(1:naug),pts), k);

b = zeros(nrows,k);

% first do those without derivatives
index1 = find(m==1);
if ~isempty(index1)
   pt1s = pts(index1); savls = savl(index1); lpt1 = length(index1);
   % initialize the  b  array.
   lpt1s = index(index1); b(lpt1s,1) = ones(lpt1,1);

   % run the recurrence simultaneously for all  pt1(i) .
   for j=1:km1
      saved = zeros(lpt1,1);
      for r=1:j
         tr = augknot(savls+r)-pt1s;
         tl = pt1s-augknot(savls+r-j);
         term = b(lpt1s,r)./(tr+tl);
         b(lpt1s,r) = saved+tr.*term;
         saved = tl.*term;
      end
      b(lpt1s,j+1) = saved;
   end
end

% then do those with derivatives, if any:
if nd>1
   indexm=find(m>1);ptss=pts(indexm);savls=savl(indexm);lpts=length(indexm);
   % initialize the  bb  array.
   %temp = [1 zeros(1,km1)]; bb = temp(ones(nd*lpts,1),:);
   bb = repmat([1 zeros(1,km1)],nd*lpts,1);
   lptss = nd*[1:lpts];

   % run the recurrence simultaneously for all  pts(i) .
   % First, bring it up to the intended level:
   for j=1:k-nd
      saved = zeros(lpts,1);
      for r=1:j
         tr = augknot(savls+r)-ptss;
         tl = ptss-augknot(savls+r-j);
         term = bb(lptss,r)./(tr+tl);
         bb(lptss,r) = saved+tr.*term;
         saved = tl.*term;
      end
      bb(lptss,j+1) = saved;
   end

   % save the B-spline values in successive blocks in  bb .

   for jj=1:nd-1
      j = k-nd+jj; saved = zeros(lpts,1); lptsn = lptss-1;
      for r=1:j
         tr = augknot(savls+r)-ptss;
         tl = ptss-augknot(savls+r-j);
         term = bb(lptss,r)./(tr+tl);
         bb(lptsn,r) = saved+tr.*term;
         saved = tl.*term;
      end
      bb(lptsn,j+1) = saved; lptss = lptsn;
   end

   % now use the fact that derivative values can be obtained by differencing:

   for jj=nd-1:-1:1
      j = k-jj;
      temp = repmat([jj:nd-1].',1,lpts)+repmat(lptsn,nd-jj,1); lptss=temp(:);
      for r=j:-1:1
         temp = repmat((augknot(savls+r)-augknot(savls+r-j)).'/j,nd-jj,1);
         bb(lptss,r) = -bb(lptss,r)./temp(:);
         bb(lptss,r+1) = bb(lptss,r+1) - bb(lptss,r);
      end
   end

   % finally, combine appropriately with  b  by interspersing the multiple
   % point conditions appropriately:
   dtau = diff([tau(1)-1 tau(:).' tau(nrows)+1]);
   index=find(min(dtau(2:nrows+1),dtau(1:nrows))==0); % Determines all rows
                                                    % involving multiple tau.
   dtau=diff(tau(index));index2=find(dtau>0)+1;     % We need to make sure to
   index3=[1 (dtau==0)];                            % skip unwanted derivs:
   if ~isempty(index2)
             index3(index2)=1+nd-m(indexm(1:length(indexm)-1));end
   b(index,:)=bb(cumsum(index3),:);

   % ... and appropriately enlarge  savl
   index = cumsum([1 (diff(tau)>0)]);
   savl = savl(index);
end

% Finally, zero out all rows of  b  corresponding to TAU outside the basic
% interval,  [knots(1) .. knots(npk)] .

index = find(tau<knots(1)|tau>knots(npk));
if ~isempty(index)
   b(index,:) = 0;
end

% The first B-spline of interest begins at KNOTS(1), i.e., at  augknot(1+addl)
% (since  augknot's  first knot has exact multiplicity K). If  addl<0 ,
% this refers to a nonexistent index and means that the first  -addl  columns
% of the collocation matrix should be trivial.  This we manage by setting
savl = savl+max(0,-addl);

if slvblk     % return the collocation matrix in almost block diagonal form.
              % For this, make the blocks out of the entries with the same
              %  SAVL(i) , with  LAST  computed from the differences.
   % There are two issues, the change in the B-splines considered because of
   % the use of  AUGKNOT  instead of  KNOTS , and the possible drop of B-splines
   % because the extreme  TAU  fail to involve the extreme knot intervals.

   % SAVL(j) is the index in  AUGKNOT  of the left knot for  TAU(j) , hence the
   % corresponding row involves  B-splines to index  savl(j) wrto augknot, i.e.,
   % B-splines to index  savl(j)-addl  wrto  KNOTS.
   % Those with negative index are removed by cutting out their columns (i.e.,
   % shifting appropriately the blocks in which they lie). Those with index
   % greater than  n  will be ignored because of  last .

   last0 = max(0,savl(1)-max(0,addl)-k); % number of cols in trivial first block
   if addl>0   % if B-splines were added on the left, remove them now:
      width = km1+k;cc = zeros(nrows*width,1);
      index = min(k,savl-addl); 
      temp = +repmat(nrows*[0:km1],nrows,1);
    cc(repmat(([1-nrows:0]+nrows*index).',1,k)+repmat(nrows*[0:km1],nrows,1))=b;
      b(:)=cc(repmat([1-nrows:0].',1,k)+repmat(nrows*(k+[0:km1]),nrows,1));
      savl=savl+k-index;
   end
   ds=(diff(savl));
   index=[0 find(ds>0) nrows];
   rows=diff(index);
   nb=length(index)-1;
   last=ds(index(2:nb));
   if addl<0  nb=nb+1; rows=[0 rows]; last=[last0 last]; end
   if slvblk==1
      colloc=[41 nb rows k last n-sum(last) b(:).'];
   else   % return the equivalent sparse matrix (cf BKBRK)
      nr = (1:nrows).'; nc = 1:k; nrnc = nrows*k;
      ncc = zeros(1,nrows); ncc(1+cumsum(rows(1:(nb-1)))) = last;
      ncc(1) = last0; ncc = reshape(cumsum(ncc),nrows,1);
      ijs = [reshape(repmat(nr,1,k),nrnc,1), ...
           reshape(repmat(ncc,1,k)+repmat(nc,nrows,1), nrnc,1), ...
           reshape(b,nrnc,1)];
      index = find(ijs(:,2)>n);
      if ~isempty(index), ijs(index,:) = []; end
      colloc = sparse(ijs(:,1),ijs(:,2),ijs(:,3),nrows,n);
   end
else          % return the collocation matrix in standard matrix form
   width = max([n,naug])+km1+km1;
   cc = zeros(nrows*width,1);
   cc(repmat([1-nrows:0].',1,k)+ ...
              repmat(nrows*savl.',1,k)+repmat(nrows*[-km1:0],nrows,1))=b;
   % (This uses the fact that, for a column vector  v  and a matrix  A ,
   %  v(A)(i,j)=v(A(i,j)), all i,j.)
   colloc = reshape(cc(repmat([1-nrows:0].',1,n) + ...
                    repmat(nrows*(max(0,addl)+[1:n]),nrows,1)), nrows,n);
end

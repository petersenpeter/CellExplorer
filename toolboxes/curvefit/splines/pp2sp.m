function sp = pp2sp(pp,sconds)
%PP2SP Convert from ppform to B-form.
%
%   PP2SP(PP)  returns the B-form of the spline whose ppform is 
%   contained in PP. The number of smoothness conditions across each 
%   interior break is guessed from the size of derivative jumps across 
%   interior breaks compared to TOL times the value of that derivative,
%   with TOL = 1.e-12.
%
%   PP2SP(PP,SCONDS)  supplies some extra information, in the following way.
%   If 0<SCONDS(1)<1, then SCONDS(1) is used as TOL.
%   If SCONDS is a sequence of nonnegative integers of the correct length,
%   then the knot sequence for the B-form is chosen so that there are
%   SCONDS(i) smoothness conditions imposed across the i-th *interior*
%   break, all i.
%
%   Up to rounding errors, the resulting form should be identical with
%   the one obtained (with considerably more calculations and no
%   absolute guarantee of success, because of the particular
%   interpolation sites chosen) as follows:
%
%   breaks= ppbrk(PP,'breaks'); l = ppbrk(PP,'l');
%   knots = augknt(breaks,k,k-SCONDS);
%   points = aveknt(knots,k);
%   SP = spapi(knots,points,fnval(PP,points));
%
%   If PP contains an m-variate spline, then SCONDS, if given, is expected
%   to be a cell-array of length m.
%
%   For example,
%
%      p0 = ppmak([0 1],[3 0 0]); p1 = sp2pp(pp2sp(pprfn(p0,[.4 .6])));
%
%   gives p1 identical to p0 (up to round-off) since the spline has no
%   discontinuity in any derivative across the additional breaks introduced
%   by PPRFN, hence PP2SP ignores these additional breaks, and SP2PP does
%   not retain any knot multiplicities (like the knot multiplicities introduced
%   by PP2SP at the endpoints of the spline's basic interval).
%
%   See also FN2FM, SP2PP, SP2BB.

%   Copyright 1987-2008 The MathWorks, Inc.

if nargin<2, sconds = []; end

if ~isstruct(pp), pp = fn2fm(pp); end

sizeval = fnbrk(pp,'dim');
if length(sizeval)>1, pp = fnchg(pp,'dz',prod(sizeval)); end

if iscell(pp.breaks) % we are dealing with a multivariate spline

   [breaks,coefs,l,k,d] = ppbrk(pp);
   m=length(k);
   if isempty(sconds), sconds = cell(1,m);
   elseif ~iscell(sconds), sconds = num2cell(repmat(sconds,1,m));
   end
   sizec = [d,l.*k]; %size(coefs);
   for i=m:-1:1
      dd = prod(sizec(1:m));
      spi = pp2sp(ppmak(breaks{i},reshape(coefs,dd*l(i),k(i)),dd),...
                           sconds{i});
      knots{i} = spi.knots;  sizec(m+1) = spi.number;
      coefs = reshape(spi.coefs,sizec);
      if m>1
         coefs = permute(coefs,[1,m+1,2:m]); sizec = sizec([1,m+1,2:m]);
      end
   end
   sp = spmak(knots,coefs,sizec);
else
   sp = pp2sp1(pp,sconds);
end

if length(sizeval)>1, sp = fnchg(sp,'dz',sizeval); end

function sp = pp2sp1(pp,sconds)
%PP2SP1 Convert univariate spline from ppform to B-form.

mustguess = 0;
  % if SCONDS is not specified, or else if its first entry is in (0..1),
  % the proper continuity across each interior knot is to be guessed, using,
  % in the second case, SCONDS(1) as the tolerance for it.
if isempty(sconds), mustguess = 1; tol = 1.e-12;
elseif (0<sconds(1)&&sconds(1)<1), mustguess = 1; tol = sconds(1);
end

[breaks,coefs,l,k,d] = ppbrk(pp);

if mustguess
                                 % guess at smoothness across breaks
   if l==1, sconds = [];
   else % evaluate each piece (but the last) at its right endpoint
      x = breaks(2:l)-breaks(1:l-1);
      if d>1 % repeat each point D times if necessary
         x = repmat(x,d,1);
      end
      x = x(:); a = coefs(1:(d*(l-1)),:);
      for ii=k:-1:2
         for i=2:ii
            a(:,i) = x.*a(:,i-1)+a(:,i);
         end
      end
      % now, at each interior break, look for the smallest i with
      %  |a(:,k-i)-coefs(:+d,k-i)|  >
      %                   >  tol*max(a(:,k-i),coefs(:,k-i),coefs(:+d,k-i))
      % taking i = k  if there is none.
      % if d>1, one would have to take the smallest such i over the d
      % functions involved.

      % first get the sizes
      temp = 1:d*(l-1); temp = [temp;temp+d;temp+l*d];
      tmp = abs([coefs;a]);
      maxes = reshape(max(reshape(tmp(temp,:),3,d*(l-1)*k)),d*(l-1),k);

      % then do the comparison
      tmp = repmat(1:k,d*(l-1),1);
      index = find(abs(coefs(d+1:d*l,:)-a)<=tol*maxes);
      tmp(index) = zeros(length(index),1);
      sconds = k - max(tmp.',[],1);
      if d>1, sconds = min(reshape(sconds,d,l-1)); end
   end
end

if (length(sconds)~=l-1)
error(message('SPLINES:PP2SP:condsdontmatchbreaks'))
end

mults = k - sconds(:).';
knots = brk2knt(breaks,[k mults k]);
rights = cumsum([1 k mults]);   %     RIGHTS(j) is the first place in the
                                %     knot sequence at which BREAKS(j)
                                %     appears (if it appears at all).

n = length(knots)-k;

% At each break  tau = BREAKS(i) ,i=1,...,l , use the de Boor-Fix formula
%
%       a_j = sum_{r=1:k} (-)^{r-1} D^{r-1} psi_j(tau) D^{k-r-1}f(tau)
%
%                                   for  t_j+ \le tau \le t_{j+k-1}-
%
% with    psi_j(t) := (knots(j+1)-t) ... (knots(j+k-1)-t)/(k-1)!
% to compute the coefficients of the  k  B-splines having the interval
%  [BREAKS(i) .. BREAKS(i+1)]  in their support. Different break intervals may,
% in this way, provide a value for the B-spline coefficient; in that case,
% choose a `most accurate' one.
% Generate the needed derivatives of  psi_j  by differentiating,  k-1  times
% with respect to  t , the program
%         v = 1
%         for i=1:(k-1)
%            v = v*(knots(j+i)-t)
%         end
% for the calculation of  (k-1)! psi(t) .

nx = k*l;
%      Each break is used k times, hence
xindex = reshape(repmat(1:l,k,1),1,nx);
%  TINDEX((j-1)*k + r)  is the index of the B-spline having the interval
%  [BREAKS(j) .. BREAKS(j+1))  as the  (k+1-r)th  knot interval in its support,
%  r=1,...,k ; i.e.,
tindex = reshape(repmat(rights(2:l+1),k,1)-repmat((k:-1:1).',1,l),1,nx);

values = zeros(k,nx);
values(k,:) = ones(1,nx);
for j=1:k-1
   xx = knots(tindex+j) -breaks(xindex);
   for i=(k-j):k-1
      values(i,:) = values(i,:).*xx + ((k-i)/i)*values(i+1,:);
   end
   values(k,:) = values(k,:).*xx;
end
% In the above, a straight-forward inner loop, with the second term being
%  -(k-i)*VALUES() , would generate in  VALUES(r,:)  the  (k-r)th derivative of
%  (k-1)!psi , while  COEFS(:,s)  contains  D^{k-s}f/(k-s)! . We want to sum
%  (-)^{k-1-r} D^{k-1-r}psi D^r f =
%                     = (-)^{k-1-r} (r!/(k-1)!) values(r+1,:) coefs(:,k-r)
% over  r = 0, ..., k-1 . In particular,
%       for  r = k-1 , the weight is 1,
%       for  r = k-2 , the weight is -1/(k-1),
%       for  r = k-3 , the weight is 1/((k-1)(k-2)) = (-1/(k-1))(-1/(k-2)),
%        etc.
%   In other words, we can incorporate these weights into the calculations
% of VALUES by changing the weight in the inner loop, from  -(k-i)  to
% +(k-i)/i , as was done above.
%
%   Here is the summing:

ac = repmat((1:d).',1,nx)+repmat(d*(xindex-1),d,1);
av = repmat(1:nx,d,1);
coefs = reshape(sum(coefs(ac(:),k:-1:1).'.*values(:,av(:)),1),d,nx);

%  Now, choose, for each B-spline coefficient, the best of possibly several
% ways of computing it, namely the one for which the corresponding  psi
% vector is the smallest (in 1-norm).
% Start this by presetting the (k,n)-array NORMS to inf, then setting
%  VALUES(i,j)  equal to the 1-norm of  VALUES(:,r)  if that vector is
% the one that computes coefficient  j  from the i-th knot interval in the
% support of the  j-th B-spline.
norms = repmat(inf,1,k*n);
vindex = ...
reshape(repmat(k*(rights(2:l+1)-k),k,1)+repmat((1-k:k+1:(k*(k-1))).',1,l),1,nx);
norms(vindex) = sum(abs(values),1);
%  ... Then, for each  j , find the number  INDEX(j)  so that
%  NORMS(INDEX(j),j)  is the smallest element in  NORMS(:,j) .
%  (worry about the one-row vs more-than-one-row discontinuity in MATLAB)
if (k==1)
   index = ones(1,n);
else
   [ignore,index] = min(reshape(norms,k,n));
end
%  ... Finally, for each  j=1:n , determine which column of VALUES this
% smallest number came from and choose the corresponding column of COEFS
% as the j-th B-spline coefficient:
norms(vindex) = 1:nx;
sp = spmak(knots, coefs(:,norms((0:n-1)*k+index)));

% Check correctness by comparing input  pp  with  sp2pp(sp) ??

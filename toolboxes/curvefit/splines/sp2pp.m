function pp = sp2pp(spline)
%SP2PP Convert from B-form to ppform.
%
%   SP2PP(SPLINE)  converts the B-form in SPLINE to the corresponding ppform
%   (on its basic interval).
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
%   See also PP2SP, SP2BB, FN2FM.

%   Copyright 1987-2008 The MathWorks, Inc.

if ~isstruct(spline), spline = fn2fm(spline); end

sizeval = fnbrk(spline,'dim');
if length(sizeval)>1, spline = fnchg(spline,'dz',prod(sizeval)); end

if iscell(spline.knots)   % we are dealing with a multivariate spline

   [t,a,n,k,d] = spbrk(spline);
   m = length(k);
   coefs = a; sizec = [prod(d),n]; % size(coefs);
   for i=m:-1:1
      ppi = sp2pp1(spmak(t{i},reshape(coefs,prod(sizec(1:m)),n(i))));
      breaks{i} = ppi.breaks;  sizec(m+1) = ppi.pieces*k(i);
      coefs = reshape(ppi.coefs,sizec);
      if m>1
         coefs = permute(coefs,[1,m+1,2:m]); sizec = sizec([1,m+1,2:m]);
      end
   end
   pp = ppmak(breaks,coefs,sizec);
      
else
   pp = sp2pp1(spline);
end

if length(sizeval)>1, pp = fnchg(pp,'dz',sizeval); end

function pp = sp2pp1(spline)
%  Take apart the  spline

[t,a,n,k,d] = spbrk(spline);

%  and augment the knot sequence so that first and last knot each have
%  multiplicity  k .

index = find(diff(t)>0); addl = k-index(1); addr = index(end)-n;
if (addl>0||addr>0)
   t = [repmat(t(1),1,addl) t(:).' repmat(t(n+k),1,addr)];
   a = [zeros(d,addl) a zeros(d,addr)];
end

%  From this, generate the pp description.

inter = find( diff(t)>0 ); l = length(inter);
if k>1
   temp = repmat(inter,d,1); dinter = temp(:);
   tx = repmat(2-k:k-1,d*l,1)+repmat(dinter,1,2*(k-1)); tx(:) = t(tx);
   tx = tx-repmat(t(dinter).',1,2*(k-1)); a = a(:);
   temp = repmat(d*inter,d,1)+repmat((1-d:0).',1,l); dinter(:) = temp(:);
   b = repmat(d*(1-k:0),d*l,1)+repmat(dinter,1,k); b(:) = a(b);
   c = sprpp(tx,b);
else temp = a(:,inter); c = temp(:);
end

%   put together the  pp

pp = ppmak([t(inter) t(inter(end)+1)],c,d);

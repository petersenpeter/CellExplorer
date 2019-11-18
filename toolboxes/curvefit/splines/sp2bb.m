function spline = sp2bb(spline)
%SP2BB Convert from B-form to BBform.
%
%   SP2BB(SPLINE)  converts the B-form in SPLINE to the corresponding BB-form,
%   obtained by using knot insertion to increase the multiplicity
%   of each knot to its maximal value, namely the order of the spline.  
%
%   See also SP2PP, PP2SP, FN2FM.

%   Copyright 1987-2008 The MathWorks, Inc.

if ~isstruct(spline), spline = fn2fm(spline); end

sizeval = fnbrk(spline,'dim');
if length(sizeval)>1, spline = fnchg(spline,'dz',prod(sizeval)); end

if iscell(spline.knots)   % we are dealing with a multivariate spline

   [t,coefs,n,k,d] = spbrk(spline);
   m=length(k);
   sizec = [d,n]; %size(coefs);
   for i=m:-1:1
      spi = sp2bb1(spmak(t{i},reshape(coefs,prod(sizec(1:m)),n(i))));
      knots{i} = spi.knots;  sizec(m+1) = spi.number;
      coefs = reshape(spi.coefs,sizec);
      if m>1
         coefs = permute(coefs,[1,m+1,2:m]); sizec = sizec([1,m+1,2:m]);
      end
   end
   spline = spmak(knots,coefs,sizec); spline.form = 'BB';
      
else
   spline = sp2bb1(spline);
end

if length(sizeval)>1, spline = fnchg(spline,'dz',sizeval); end

function spline = sp2bb1(spline)
%SP2BB1 Convert univariate spline from B-form to BBform.

[xi,m] = knt2brk(spbrk(spline,'knots'));
spline = sprfn(spline, brk2knt(xi,subplus(spbrk(spline,'order') - m)));
spline.form = 'BB';

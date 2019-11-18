function fprime = fnder(f,dorder)
%FNDER Differentiate a function.
%
%   FNDER(F) returns the (representation of the) first derivative of the
%   univariate function contained in F (and in the same form).  
%
%   FNDER(F,DORDER) returns the DORDER-th derivative, with DORDER expected
%   to be of the form [d1,...,dm] in case the function in F is m-variate,
%   and, for each i=1,..,m,  di  an integer to indicate that the function
%   in F is to be differentiated di-fold with respect to its i-th argument.
%   Here, di may be negative, resulting in di-fold integration with respect
%   to the i-th argument.
%
%   FNDER(...) does not work for rational splines; for them, use FNTLR instead.
%
%   FNDER(...) works for functions in stform only in a very limited way, namely 
%   only for type tp00, and, for that, DORDER can only be [1 0] or [0 1].
%
%   Examples:
%
%      fnval( fnder( sp, 2), 3.14 );
%   gives the value at 3.14 of the function in sp, while
%
%      sp0 = fnint( fnder( sp ) );
%   gives a function that differs from sp by some constant only (namely, by
%   its value at 0).
%
%   See also FNDIR, FNTLR, FNINT, FNCHG.

%   Copyright 1987-2011 The MathWorks, Inc.

if ~isstruct(f), f = fn2fm(f); end

try %treat the function as vector-valued if it is not
   sizeval = fnbrk(f,'dim');
   if length(sizeval)>1, f = fnchg(f,'dz',prod(sizeval)); end
catch ignore %#ok<NASGU>
   error(message('SPLINES:FNDER:unknownform', f.form));
end

if nargin<2, dorder=1; end

switch f.form(1:2)
case 'pp' % the function is in ppform:
   [breaks,coefs,l,k,d]=ppbrk(f);
   if iscell(breaks) % the function is multivariate
      m = length(k);
      if length(dorder)~=m
         error(message('SPLINES:FNDER:ordermustbevec', num2str( m ))), end
      sizec = [d,l.*k]; %size(coefs);
      for i=m:-1:1
         dd = prod(sizec(1:m));
         dpp = fnderp(ppmak(breaks{i},reshape(coefs,dd*l(i),k(i)),dd), ...
                      dorder(i));
         breaks{i} = dpp.breaks; sizec(m+1) = dpp.pieces*dpp.order;
         coefs = reshape(dpp.coefs,sizec);
         if m>1
             coefs = permute(coefs,[1,m+1,2:m]);
             sizec(2:m+1) = sizec([m+1,2:m]);
         end
      end
      fprime = ppmak(breaks,coefs,sizec);
   else
      fprime = fnderp(f,dorder);
   end

case {'B-','BB'} % the function is in B-form or BB-form;
                 % omit trivial B-spline terms.
   [knots,coefs,n,~,d]=spbrk(f);
   if iscell(knots)       % the function is multivariate
      m = length(knots);
      if length(dorder)~=m
         error(message('SPLINES:FNDER:ordermustbevec', num2str( m ))), end
      sizec = [d,n];% size(coefs);
      for i=m:-1:1
         dsp = fnderb(spmak(knots{i},...
            reshape(coefs,prod(sizec(1:m)),sizec(m+1))),dorder(i));
         knots{i} = dsp.knots; sizec(m+1) = dsp.number; 
         coefs = reshape(dsp.coefs,sizec); 
         if m>1
            coefs = permute(coefs,[1,m+1,2:m]);
            sizec(2:m+1) = sizec([m+1,2:m]);
         end
      end
      fprime = spmak(knots,coefs,sizec);
   else
      fprime = fnderb(f,dorder);
   end
case {'rp','rB'}
  error(message('SPLINES:FNDER:notforrat'))
case 'st'
   if strcmp(f.form,'st-tp00')
      if length(dorder)~=2||sum(dorder)>1
         error(message('SPLINES:FNDER:onlyfirstpartial'))
      end        
      if sum(dorder)==0, fprime = f; return, end
      [centers,coefs] = stbrk(f);
      if dorder(1)==1  % we are to differentiate wrto the first argument
         type = 'tp10'; coefs(:,[end-1,end]) = [];     
      else             % we are to differentiate wrto the second argument
         type = 'tp01'; coefs(:,[end-2,end]) = [];     
      end 
      fprime = stmak(centers,coefs,type,fnbrk(f,'interv'));
   else
       error(message('SPLINES:FNDER:notforst', f.form( 4:end )))
   end
  
otherwise
   error(message('SPLINES:FNDER:unknownfn'))
end

if length(sizeval)>1, fprime = fnchg(fprime,'dz',sizeval); end

function fprime = fnderp(f,dorder)
%FNDERP Differentiate a univariate function in ppform.
[breaks,coefs,l,k,d]=ppbrk(f);
if k<=dorder
   fprime=ppmak([breaks(1) breaks(l+1)],zeros(d,1));
elseif dorder<0    % we are to integrate
   fprime = f;
   for j=1:(-dorder)
      fprime = fnint(fprime);
   end
else
   knew=k-dorder;
   for j=k-1:-1:knew
      coefs=coefs.*repmat([j:-1:j-k+1],d*l,1);
   end
   fprime=ppmak(breaks,coefs(:,1:knew),d);
end

function fprime = fnderb(f,dorder)
%FNDERB Differentiate a univariate function in B-form.

[t,a,n,k,d]=spbrk(f);
if k<=dorder
   fprime=spmak(t,zeros(d,n));
elseif dorder<0    % we are to integrate
   fprime = f;
   for j=1:(-dorder)
      fprime = fnint(fprime);
   end
else
   knew=k-dorder;
   for j=k-1:-1:knew
      tt=t(j+1+[0:n])-t(1:n+1); z=find(tt>0); nn=length(z);
      temp=(diff([zeros(1,d);a.'; zeros(1,d)])).';
      a=temp(:,z)./repmat(tt(z)/j,d,1);
      t=[t(z) t(n+2:n+j+1)]; n=nn;
   end
   fprime=spmak(t,a);
end

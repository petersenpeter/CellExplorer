function intgrf = fnint(f,ifa)
%FNINT Integrate a function.
%
%   FNINT(F)  returns the (representation of the) indefinite integral that 
%   is zero at the left end point of the basic interval of (the function in) F.
%
%   FNINT(F,IFA)  provides the indefinite integral whose value at the 
%   left end point of the basic interval is IFA.
%
%   FNINT does not work for rational splines nor for functions in stform.
%
%   Example:
%
%      fnder(fnint(f));
%
%   is the same as f (except for round-off and, possibly, the multiplicity of
%   end knots).
%
%   See also FNDER, FNDIR.

%   Copyright 1987-2011 The MathWorks, Inc.

if ~isstruct(f), f = fn2fm(f); end

try %treat the function as vector-valued if it is not
   sizeval = fnbrk(f,'dim');
   if length(sizeval)>1, f = fnchg(f,'dz',prod(sizeval)); end
catch ignore %#ok<NASGU>
   error(message('SPLINES:FNINT:unknownform', f.form));
end

switch f.form(1:2)
case 'pp'      % the function is in ppform:
   
   if length(f.order)>1
         error(message('SPLINES:FNINT:useFNDER')), end
      
   [breaks,coefs,l,k,d]=ppbrk(f);
   coefs=coefs./repmat([k:-1:1],d*l,1);
   if nargin==1, ifa = zeros(d,1); end
   if l<2
      intgrf=ppmak(breaks,[coefs ifa],d);
   else
      % evaluate each integrated polynomial at the right endpoint of its
      % interval (this is adapted from PPUAL)
      xs=diff(breaks(1:l));index=[1:l-1];
      if d>1
         xs = reshape(repmat(xs,d,1),1,(l-1)*d);
         index = reshape(1+repmat(d*index,d,1)+repmat([-d:-1].',1,l-1), ...
                        (l-1)*d,1);
      end
      vv=xs.*coefs(index,1).';
      for i=2:k
         vv = xs.*(vv + coefs(index,i).');
      end
      if (d>1)
         junk=zeros(d,l-1);junk(:)=vv;last=(cumsum([ifa junk].')).';
      else
         last=cumsum([ifa,vv]);
      end

      intgrf=ppmak(breaks,[coefs(:,1:k) last(:)],d);
   end

case {'B-','BB'}   % the function is in B-form or BBform.
   
   if length(f.order)>1
      error(message('SPLINES:FNINT:useFNDER')), end
   
   % Set it up so that it would be correct on the interval [t(1) .. t(n+k)].
   % There is no way to make it correct everywhere since the integral of
   % a spline over the interval [t(1) .. t(n+k)] need not be zero.
   [t,a,n,k,d]=spbrk(f);

   index = find(diff(t)>0);      % increase multiplicity of last knot to  k
   needed = index(length(index)) - n; % =  k+1 - (n+k - index(length(index));
   if (needed > 0)
      t = [t repmat(t(n+k),1,needed)]; a = [a zeros(d,needed)]; n = n+needed;
   end

   if nargin>1 % if a left-end value is specified, increase left-end knot
               % multiplicity to k+1, making the additional coefficients
               %  0 , then add IFA to all coefficients of the integral.
      needed = k - index(1);
      intgrf = spmak([repmat(t(1),1,needed+1) t t(n+k)], ...
         cumsum([ifa,zeros(d,needed),a.*repmat((t(k+[1:n])-t(1:n))/k,d,1)],2));
   else
      intgrf = spmak([t t(n+k)], ...
                     cumsum(a.*repmat((t(k+[1:n])-t(1:n))/k,d,1),2));
   end
case {'rB','rp'}
   error(message('SPLINES:FNINT:notforrat'))
case 'st'
   error(message('SPLINES:FNINT:notforst'))
otherwise  % unknown representation
   error(message('SPLINES:FNINT:unknownfn'))
end

if length(sizeval)>1, intgrf = fnchg(intgrf,'dz',sizeval); end

function g = fnxtr(f,order)
%FNXTR Extrapolate function
%
%   G = FNXTR(F, ORDER) returns the spline (in ppform) that agrees with 
%   F on the latter's basic interval but is a polynomial of the given ORDER 
%   outside it, with 2 the default for ORDER, in such a way that G satisfies
%   at least ORDER smoothness conditions at the ends of F's basic interval, 
%   i.e., at the new breaks.
%
%   F must be in B-form, BBform, or ppform.
%
%   While ORDER can be any nonnegative integer, FNXTR is useful mainly for
%   0 < ORDER < order of F.
%   If ORDER is zero, then G describes the same spline as FN2FM(F,'B-') but
%   is in ppform and has a larger basic interval.
%   If ORDER is at least as big as F's order, then G describes the same pp as
%   FN2FM(F,'pp') but uses two more pieces and has a larger basic interval.
%
%   If F is m-variate, then ORDER may be an m-vector, in which case ORDER(i) 
%   specifies the matching order to be used in the i-th variable, i=1:m.
%
%   If ORDER < 0, then G is exactly the same as FN2FM(F,'pp'). This unusual
%   option is useful when, in the multivariate case, extrapolation is to take
%   place in only some but not all variables.
%   
%   For example, the cubic smoothing spline for given data x,y is, like any
%   other `natural' cubic spline, required to have zero second derivative 
%   outside the interval spanned by the data sites.  Hence, if such spline is 
%   to be evaluated outside that interval, it should be constructed as
%   s = fnxtr(csaps(x,y),2). The following figure shows the difference:
%
%      x = rand(1,21); s = csaps(x,x.^3); sn = fnxtr(s,2);
%      fnplt(s,[-.5 1.4]), hold on, fnplt(sn,[-.5 1.4],.5,'r'), hold off
%      legend('cubic smoothing spline','... properly extrapolated')
%
%   As bivariate examples,
%
%      fnplt(fnxtr(spmak({0:3,0:4},1),[3,4]))
%
%   shows the full-order extrapolation of a tensor product B-spline, while
%
%      fnplt(fnxtr(spmak({0:3,0:4},1),[3,-1]))
%
%   shows suppression of such extrapolation in the second variable.
%
%   See also  PPMAK, SPMAK, FN2FM

%   Copyright 1987-2009 The MathWorks, Inc.

try
   [form,m] = fnbrk(f,'form','var');
catch
   error(message('SPLINES:FNXTR:notafunction'))
end

switch form(1:2)
case 'pp'
case {'B-','BB'}
   f = fn2fm(f,'pp');
otherwise
   error(message('SPLINES:FNXTR:restrictform'))
end

if nargin<2, order = 2; end

if m>1     % we are to handle a tensor product spline
   if length(order)==1, order = repmat(order,1,m); end
   [breaks,coefs,l,k,d] = ppbrk(f);

      % We know that COEFS is of size [D,lk], with lk := L.*K .
      % Treating pp as a vector-valued function of just the last variable,
      % we would be looking at
      %    ppm := ppmak(BREAKS{M},reshape(COEFS,dd*L(m),K(m)),dd)
      % with   dd := D*L(1)*K(1)* ... *L(m-1)*K(m-1).
      % Then 
      %    ppm := fnxtr1(ppm,ORDER(m)) 
      % is the appropriately extrapolated pp of that last variable
      % (assuming that ORDER(m)>=0 ).
      % Now we want to extrapolate this as a function of the second-last
      % variable. For this, we cyclically permute the M dimensions, making
      % the last one the first but making no other permutations. This requires
      % the permutation  coefs = permute(coefs,[1,M+1,2:M]) and changes,
      % correspondingly,  sizec := [D,L.*K] to sizec([1,M+1,2:M]).
      % To be sure, application of FNXTR will have changed L(m) (but not K(m))
      % and will have changed BREAKS{m}, and this change has to be accounted
      % for.
      % One now cycles in this manner through the M dimensions, from last to
      % first, ending up with a pp in which, once again, the M variables
      % correspond exactly to the original M variables. That is the beauty of
      % the tensor-product construct.

   sizec = [d,l.*k]; %size(coefs);
   for i=m:-1:1
      dd = prod(sizec(1:m));

      [breaks{i},coefs,l(i)] = ppbrk(fnxtr1( ...
               ppmak(breaks{i},reshape(coefs,dd*l(i),k(i)),dd), order(i)), ...
	                          'b','c','l');
      sizec(m+1) = l(i)*k(i); coefs = reshape(coefs,sizec);
      coefs = permute(coefs,[1,m+1,2:m]); sizec = sizec([1,m+1,2:m]);
   end
   g = ppmak(breaks,coefs,sizec);

else             % we have a univariate spline
   g = fnxtr1(f,order);
end

function g = fnxtr1(f,order)
%FNXTR1 extrapolate univariate fn to the given order outside the basic interval

% if ORDER < 0, F is returned as G. This may be of help in the tensor product
% case when one wishes to extrapolate only in certain directions.
if order<0, g = f; return, end

   %add a break beyond each end
f = fnrfn(f,fnbrk(f,'interv')+[-1 1]);
k = fnbrk(f,'order');
if k<=order, g = f; return, end 
[b,c,d] = fnbrk(f,'breaks','coefs','dim');

   %in the first and last polynomial, set to zero all terms of order > ORDER 
c([1:d end-d+1:end],1:k-order) = 0;
   %get the nontrivial coefficients for the new first piece by adding the
   %new leftmost break to the ppform of the polynomial formed from the terms
   %of order <= ORDER of the now second polynomial piece, on [b(2)..(3)].
c1 = fnbrk(fnrfn(ppmak(b(2:3), c(d+1:2*d,k-order+1:k),d),b(1)),'coefs');
c(1:d,k-order+1:k) = c1(1:d,:);
g = ppmak(b,c,d);


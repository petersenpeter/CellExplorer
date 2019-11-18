function ppout = pprfn(pp,varargin)
%PPRFN Insert additional breaks into a ppform.
%
%   PPRFN(PP,ADDBREAKS)  returns the ppform of the function in PP but with
%   the break sequence refined to contain also all the points in ADDBREAKS.  
%
%   PPRFN(PP)  inserts all the midpoints of PP's knot intervals.
%
%   If PP describes an m-variate spline, then ADDBREAKS is expected to be
%   a cell array with m entries, any of which may be empty if no refinement
%   in the corresponding break sequence is wanted.
%
%   See also FNRFN, SPRFN.

%   Copyright 1987-2008 The MathWorks, Inc.

[var,sizeval] = fnbrk(pp,'var','dim');
if length(sizeval)>1, pp = fnchg(pp,'dz',prod(sizeval)); end

if var>1   % we are dealing with a multivariate spline

   if nargin>1&&~iscell(varargin{1})
      error(message('SPLINES:PPRFN:addbreaksnotcell'))
   end

   [b,c,l,k,d] = ppbrk(pp);

   m = length(l);
   coefs = c; sizec = [d,l.*k]; %size(coefs);
   for i=m:-1:1   % carry out coordinatewise breaks refinement
      dd = prod(sizec(1:m));
      if nargin>1
         ppi = ...
	   pprfn1(ppmak(b{i},reshape(coefs,dd*l(i),k(i)),dd),varargin{1}{i});
      else
         ppi = pprfn1(ppmak(b{i},reshape(coefs,dd*l(i),k(i)),dd));
      end
      b{i} = ppi.breaks; sizec(m+1) = ppi.pieces*ppi.order; 
      coefs = reshape(ppi.coefs,sizec);  
      coefs = permute(coefs,[1,m+1,2:m]); sizec(2:m+1) = sizec([m+1,2:m]);
   end

   % At this point, COEFS contains the tensor-product pp coefficients;
   % also, the various break sequences in B will have been updated. 
   % It remains to return information:
   ppout = ppmak(b, coefs, sizec);

else             % univariate spline refinement
   ppout = pprfn1(pp,varargin{:});
end
if length(sizeval)>1, ppout = fnchg(ppout,'dz',sizeval); end

function ppout = pprfn1(pp,breaks)
%PPRFN1 Insert additional breaks into a univariate ppform.

if nargin<2||(ischar(breaks)&&breaks(1)=='m') % we must supply the midpoints
                                          % of all nontrivial knot intervals
   oldbreaks = ppbrk(pp,'breaks');
   breaks = (oldbreaks(1:end-1)+oldbreaks(2:end))/2;
end

if isempty(breaks), ppout = pp; return, end
breaks = sort(breaks(:).'); lb = length(breaks);

[b,c,l,k,d] = ppbrk(pp);

index0 = find(breaks<b(1)); l0 = length(index0);
% any of these become left-end points for new pieces to the left of the first
% piece, with their coefs all computed from the first piece, i.e., jl(j) = 1.

index2 = find(breaks>b(l+1)); l2 = length(index2);

% now look at the entries of BREAKS in [B(1) .. B(L+1)]. Any of these which
% are not equal to some B(j) become new left-end points, with the coefs
% computed from the relevant piece.
index1 = (l0+1):(lb-l2);
if isempty(index1)
   index = index1;
   jl = [ones(1,l0),repmat(l,1,l2)];
else
   pointer = sorted(b(1:l+1),breaks(index1));
   % find any BREAKS(j) not in B.
   % For them, the relevant left-end point is B(POINTER(INDEX)).
   index = find(b(pointer)~=breaks(index1));
   jl = [ones(1,l0),pointer(index),repmat(l,1,l2)];
end
ljl = length(jl);
     % If all entries of BREAKS are already in B, then just return the input.
if ljl==0, ppout = pp; return, end

% if there are any BREAKS to the right of B(L+1), then B(L+1) and all but the
% rightmost of these must become left-end points, with coefs computed from
% the last piece, i.e., JL(j) = L  for these, and the rightmost BREAKS
% becomes the new right endpoint of the basic interval.
if l2>0
   tmp = breaks(lb);
   breaks(lb:-1:(lb-l2+1)) = [breaks(lb-1:-1:(lb-l2+1)),b(l+1)];
   b(l+1) = tmp;
end

% These are all the additional left-end points:
addbreaks = breaks([index0,index1(index),index2]);
% Now compute the new coefficients in lockstep:
x = addbreaks - b(jl);
if d>1 % repeat each point D times if necessary
   x = repmat(x,d,1);
   omd = (1-d:0).'; jl = repmat(d*jl,d,1)+repmat(omd,1,ljl);
end
a = c(jl,:); x = x(:);
for ii=k:-1:2
   for i=2:ii
      a(:,i) = x.*a(:,i-1)+a(:,i);
   end
end

% Now, all that's left is to insert the coefficients appropriately.
% First, get the enlarged breaks sequence:
newbreaks = sort([b, addbreaks]);
% This should be of length  L + length(JL)  +  1, requiring
newc = zeros(d*(length(newbreaks)-1),k);
if d>1
   newc(repmat(d*sorted(newbreaks,b(1:l)),d,1)+repmat(omd,1,l),:) = c;
   newc(repmat(d*sorted(newbreaks,addbreaks),d,1)+repmat(omd,1,ljl),:) = a;
else
   newc(sorted(newbreaks,b(1:l)),:) = c;
   newc(sorted(newbreaks,addbreaks),:) = a;
end

ppout = ppmak(newbreaks,newc,d);

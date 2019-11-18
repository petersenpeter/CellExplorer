function spnew = sprfn(sp,varargin)
%SPRFN Insert additional knots into B-form of a spline.
%
%   SPRFN(SP,ADDKNOTS)  inserts the specified ADDKNOTS into the B-form 
%   of the spline contained in SP. No sites are inserted if isempty(ADDKNOTS).
%
%   SPRFN(SP)  inserts the midpoints of all nontrivial knot intervals.
%
%   No knot multiplicity will be increased beyond the order of the spline.
%
%   If SP describes an m-variate spline, then ADDKNOTS is expected to be
%   a cell array with m entries, any of which may be empty if no refinement
%   in the corresponding knot sequence is wanted.
%
%   See also FNRFN, PPRFN.

%   Copyright 1987-2009 The MathWorks, Inc.

sizeval = fnbrk(sp,'dim');
if length(sizeval)>1, 
    sp = fnchg(sp,'dz',prod(sizeval)); 
end
   
if fnbrk(sp,'var')>1    % we are dealing with a multivariate spline

   if nargin>1&&~iscell(varargin{1})
      error(message('SPLINES:SPRFN:addknotsnotcell'))
   end

   [t,a,n,d] = spbrk(sp, 'knots', 'coefs', 'number', 'dimension');
   m = length(n);
   coefs = a; 
   sizec = [d,n];
   for i=m:-1:1   % carry out coordinatewise knot refinement
      if nargin>1
         spi = sprfn1(spmak(t{i},reshape(coefs,prod(sizec(1:m)),sizec(m+1))),...
                                  varargin{1}{i});
      else
         spi = sprfn1(spmak(t{i},reshape(coefs,prod(sizec(1:m)),sizec(m+1))));
      end 
      t{i} = spi.knots; 
      sizec(m+1) = spi.number; 
      coefs = reshape(spi.coefs, sizec);
      coefs = permute(coefs,[1,m+1,2:m]); 
      sizec(2:m+1) = sizec([m+1,2:m]);
   end
   % At this point, COEFS contains the tensor-product B-spline coefficients;
   % also, the various knot sequences will have been updated. 
   % It remains to return information:
   spnew = spmak(t, coefs,sizec);

else             % univariate spline refinement
   spnew = sprfn1(sp,varargin{:});
end

if length(sizeval)>1, 
    spnew = fnchg(spnew,'dz',sizeval); 
end

function spnew = sprfn1(sp,addknots)
%SPRFN1 Insert additional knots into B-form of a univariate spline.

if nargin<2||(ischar(addknots)&&addknots(1)=='m') % we must supply the midpoints
                                          % of all nontrivial knot intervals
   breaks = knt2brk(fnbrk(sp,'knots'));
   addknots = (breaks(1:end-1)+breaks(2:end))/2;
end

if isempty(addknots), 
    spnew = sp; 
    return, 
end

addknots = sort(addknots(:).'); 
ladd = length(addknots); 

[t,a,n,k,d] = spbrk(sp);

% retain only distinct points, but record their input multiplicity
index = [1 find(diff(addknots)>0)+1];
inmults = diff([index ladd+1]); 
sortedadds = addknots;
addknots = addknots(index); 
ladd = length(index);

% compute the current multiplicity of ADDKNOTS in T.
indexr = sorted(t, addknots);
temp = n+k - sorted(-t,-addknots); 
mults = indexr -  temp(ladd:-1:1);
% ... then reduce INMULTS to make certain that output has knots of
%     multiplicity at most  k .
excess = subplus(inmults+mults-k);
if any(excess>0)
   inmults = inmults - excess;
   index = find(inmults>0);
   if isempty(index)
      warning(message('SPLINES:SPRFN:alreadyfullmult'))
      spnew = sp; return
   end
   warning(message('SPLINES:SPRFN:excessmult'))
   if length(index)<ladd
      addknots = addknots(index); 
      mults = mults(index);
      inmults = inmults(index); 
      indexr = indexr(index); 
      ladd = length(addknots);
   end
end

% if the endknot multiplicity is to be increased and/or there are knots
% outside the current basic interval, do it now
lamin=1;
index = find(addknots<t(1));
if ~isempty(index) % there are knots to be put to the left
   totals = sum(inmults(index));
   t = [sortedadds(1:totals) t];
   a = [zeros(d,totals) a]; 
   n = n + totals; 
   indexr = indexr + totals;
   lamin = 1+length(index);
elseif addknots(1)==t(1)
   t = t([ones(1,inmults(1)) 1:(n+k)]);
   a = [zeros(d,inmults(1)) a]; 
   n = n+inmults(1); 
   indexr = indexr + inmults(1);
   lamin = 2;
end
lamax = ladd;
index = find(addknots>t(n+k));
if ~isempty(index) % there are knots to be put to the right
   totals = sum(inmults(index));
   t = [t sortedadds(length(sortedadds)+((1-totals):0))];
   a = [a zeros(d,totals)]; 
   n = n + totals;
   lamax = ladd-length(index);
elseif addknots(ladd)==t(n+k)
   t = t([1:(n+k) repmat(n+k,1,inmults(ladd))]);
   a = [a zeros(d,inmults(ladd))]; 
   n = n+inmults(ladd);
   lamax = ladd-1;
end

% Increase endknot multiplicity to  k , to avoid difficulties.
% (Taken from SPVAL)
index = find(diff(t)>0); 
addl = k-index(1); 
addr = index(end)-n;
if ( addl>0 || addr>0 )
   t = t([ones(1,addl) 1:(n+k) repmat(n+k,1,addr)]);
   a = [zeros(d,addl) a zeros(d,addr)];
   n = n+addl+addr; 
   indexr = indexr+addl;
end

% Ready for knot insertion, one at a time.
for la=lamin:lamax
   for mm=1:inmults(la)
      newa = a(:,[1:indexr(la)-k+1 indexr(la)-k+1:n]);
      newt = [t((1:indexr(la))) addknots(la) t((indexr(la)+1:n+k))];

      for j=(indexr(la)-k+2):(indexr(la)-mults(la))
         newa(:,j) = ...
             (a(:,j-1)*(t(j+k-1)-addknots(la)) + a(:,j)*(addknots(la)-t(j)))/...
             (          t(j+k-1)                                     -t(j) );
      end
      t = newt; 
      a = newa; 
      n = n+1; 
      indexr = indexr+1; 
      mults(la) = mults(la)+1;
   end
end

if addl>0||addr>0 % remove again those additional end knots and coefficients
   a(:,[1:addl n+((1-addr):0)]) = [];
   t([1:addl n+k+((1-addr):0)]) = []; 
end

spnew = spmak(t,a);

function [xi,m] = knt2brk(t)
%KNT2BRK From knots to breaks and their multiplicities.
%
%        [XI,M] = KNT2BRK(T)
%
%   returns the increasing list XI of distinct entries of T along with their
%   multiplicities  M(i) := #{ j : T(j) = XI(i) }, i=1:length(XI) .
%
%   For example, [xi,m] = knt2brk( [ 1 2 3 3 1 3] ) returns [1 2 3] for xi
%   and [2 1 3] for m .
%
%   See also BRK2KNT, KNT2MLT.

%   cb 15aug96
%   Copyright 1987-2008 The MathWorks, Inc. 

difft = diff(t); if any(difft<0) t = sort(t); difft = diff(t); end

[r,c] = size(t);
if r>1 % make sure to return vectors of the same kind
   index = [1;find(difft>0)+1];
   m = diff([index;r*c+1]);
else
   index = [1 find(difft>0)+1];
   m = diff([index r*c+1]);
end
xi = t(index);

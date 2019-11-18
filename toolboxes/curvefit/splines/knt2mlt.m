function [m,t] = knt2mlt(t)
%KNT2MLT Knot multiplicities.
%
%   KNT2MLT(T) returns the vector M of knot multiplicities. Precisely,
%
%   M(i) = # { j<i : T(j) = T(i) },  i=1:length(T),
%
%   with T here first sorted if the input is not.
%
%   [M,T] = KNT2MLT(T) also returns the sorted knot sequence.
%
%   For example, [m,t] = knt2mlt([ 1 2 3 3 1 3]) returns 
%   [0 1 0 0 1 2] for m and [1 1 2 3 3 3] for t.
%
%   See also KNT2BRK, BRK2KNT.

%   Copyright 1987-2011 The MathWorks, Inc.

[r,c] = size(t);
if r*c<2 m=0; return, end

difft = diff(t); if any(difft<0) t = sort(t); difft = diff(t); end

index = zeros([r,c]); index(2:end) = difft==0;
m = cumsum(index);
zz = find(diff(index)<0);
if isempty(zz) return, end

z = zeros([r,c]);
pt = m(zz);
pt(2:end) = diff(pt);
z(zz+1) = pt;
m = m - cumsum(z);

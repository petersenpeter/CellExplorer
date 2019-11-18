function [augknot,addl] = augknt(knots,k,mults)
%AUGKNT Augment a knot sequence.
%
%   AUGKNT(KNOTS,K) returns a nondecreasing and augmented knot 
%   sequence which has the first and last knot with exact multiplicity K .  
%   (This may actually shorten the knot sequence.)  
%
%   [AUGKNOT,ADDL] = AUGKNT(KNOTS,K) also returns the number of knots
%   added on the left.  (This may be negative.)
%
%   AUGKNOT = AUGKNT(KNOTS,K,MULTS) returns an augmented knot sequence
%   that, in addition, contains each interior knot MULTS times.  If
%   MULTS has exactly as many entries as there are interior knots,
%   then the j-th one (in the ordered sequence) will be repeated MULTS(j)
%   times.  Otherwise, the uniform multiplicity MULTS(1) is used, whose
%   default value is 1 .  If the sequence of interior knots in KNOTS is
%   *strictly* increasing, then this ensures that the splines of order K
%   with knot sequence AUGKNOT satisfy K-MULTS(j) smoothness conditions
%   across the j-th interior break, all j .
%
%   For example, the statement
%
%      ch = spapi(augknt(x,4,2), [x x], [y dy]);
%
%   constructs the piecewise cubic Hermite interpolant, i.e., the function  s
%   in  ch  satisfies  s(x(i)) = y(i),  (Ds)(x(i)) = dy(i), all i (assuming 
%   that  x  is strictly increasing).
%
%   See also SPALLDEM.

%   Copyright 1987-2008 The MathWorks, Inc.

if nargin<3
   if (length(k)>1|k<1)
      error(message('SPLINES:AUGKNT:wrongk')), end
   mults = 1;
end

dk = diff(knots);
if ~isempty(find(dk<0)), knots = sort(knots); dk = diff(knots); end

augknot=[];
j=find(dk>0); if isempty(j)
   error(message('SPLINES:AUGKNT:toofewknots')), end
addl = k-j(1);

interior = (j(1)+1):j(end);
%   % make sure there is a multiplicity assigned to each interior knot:
if length(mults)~=length(interior), mults = repmat(mults(1),size(interior)); end

augknot = brk2knt(knots([1 interior end]), [k mults k]);

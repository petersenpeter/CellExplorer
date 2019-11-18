function values = rsval(rs,varargin)
%RSVAL Evaluate rational spline.
%
%   VALUES = RSVAL(RS,X)  returns the value at X of the rational spline
%   whose rBform or rpform is in RS.
%
%   Specifically, this means that the d-vector valued rational spline in
%   RS is evaluated at X with the aid of SPVAL or PPUAL as if it were an
%   ordinary (d+1)-vector valued spline, then each of the resulting values
%   is divided by its last entry (changed to 1 in case it is zero),
%   and then that last entry is omitted.
%
%   VALUES is a matrix of size [d*m,n] if the function in RS is
%   univariate and d-vector valued, and [m,n] is size(X) .
%
%   If the function in RS is m-variate with m>1 and d-vector valued, then
%
%                     [d,n],         if X is of size [m,n]
%   VALUES is of size [d,n1,...,nm], if d>1  and X is {X1,...,Xm}
%                     [n1,...,nm],   if d is 1 and X is {X1,...,Xm}
%
%   See also FNVAL, SPVAL, PPVAL, RSMAK, RPMAK.

%   Copyright 1987-2008 The MathWorks, Inc.

if ~isstruct(rs)
   error(message('SPLINES:RSVAL:fnnotstruct')), end

% treat rs as a spline in B-form or ppform:

switch rs.form(2)
case 'B', temp = fnval(fn2fm(rs,'B-'),varargin{:});
case 'p', temp = fnval(fn2fm(rs,'pp'),varargin{:});
otherwise
   error(message('SPLINES:RSVAL:fnnotrat'))
end

% divide each resulting (d+1)-vector by its last entry (having changed any
% zero entry to 1), then return only the first d entries:

d = fnbrk(rs,'dim'); temp(d+1,find(temp(d+1,:)==0)) = 1;

sv = size(temp);
if length(sv)<3 newsize = [d*sv(1)/(d+1),sv(2)];
else            newsize = [d,sv(2:end)];
end

temp = reshape(temp,d+1,prod(sv)/(d+1));
values = reshape(temp(1:d,:)./temp(repmat(d+1,d,1),:),newsize);

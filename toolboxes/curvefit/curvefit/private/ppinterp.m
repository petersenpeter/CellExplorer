function F=ppinterp(x,y,method)
% PPINTERP ppform interpretation.
%
% X is a n by 1 column vector, Y is a n by m matrix. F will be a
% ppform of size m (one for each column of Y). METHOD can be one of
% the following:
%
%      nearest
%      linear
%      cubic
%      spline
%      pchip
%
%

%   Copyright 2001-2012 The MathWorks, Inc.

[n,m] = size(y);
if n == 1
    n = m;
    m = 1;
    y = y';
end
if size(x,1) == 1
    x = x';
end
if size(x,1) ~= n
    error(message('curvefit:ppinterp:lengthsMustMatch'));
end
if ~isreal(x) || ~isreal(y)
    error(message('curvefit:ppinterp:pointsShouldBeReal'))
end

if any(diff(x) < 0)
    [x,idx]=sort(x);
    y = y(idx,:);
end

if (any(diff(x)==0))
    error(message('curvefit:ppinterp:dataMustBeDistinct'));
end

switch method(1)
case 'n' % nearest
    F=mkpp([x(1); (x(1:end-1)+x(2:end))/2; x(end)]',y',m);
case 'l' % linear
    F=mkpp(x',cat(3,(diff(y)./repmat(diff(x),1,size(y,2)))', y(1:end-1,:)'),m);
case {'p', 'c'} % pchip and cubic
    F=pchip(x',y');
case 's' % spline
    F=spline(x',y');
case 'v' % v5cubic
    b = diff(x);
    if norm(diff(b),Inf) <= eps*norm(x,Inf) % equally space
        a = repmat(b,m)';
        y = [3*y(1,:)-3*y(2,:)+y(3,:);y;3*y(n,:)-3*y(n-1,:)+y(n-2,:)];
        y1 = y(1:end-3,:)'; y2 = y(2:end-2,:)'; 
        y3 = y(3:end-1,:)'; y4 = y(4:end,:)';
        coefs = cat(3,(-y1+3*y2-3*y3+y4)./(2*a.^3), (2*y1-5*y2+4*y3-y4)./(2*a.^2), (-y1+y3)./(2*a), y2);
        F=mkpp(x',coefs,m);
    else
        F = spline(x',y');
    end
otherwise
    error(message('curvefit:ppinterp:unknownMethod'));
end


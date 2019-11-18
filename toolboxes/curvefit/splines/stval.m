function values = stval(st,x)
%STVAL Evaluate function in stform.
%
%   Z = STVAL(ST,X) returns the value at X of the function whose stform
%   is in ST.
%   Z is a matrix of size [d*m,n] if the function in ST is
%   univariate and d-vector valued, and [m,n] is size(X) .
%   If the function in ST is m-variate with m>1 and d-vector valued, then
%
%                 [d,n],         if X is of size [m,n]
%    Z is of size [d,n1,...,nm], if d>1  and X is {X1,...,Xm} 
%                 [n1,...,nm],   if d is 1 and X is {X1,...,Xm} 
%
%   See also FNVAL, PPUAL, RSVAL, SPVAL, PPVAL.

%   Copyright 1987-2008 The MathWorks, Inc.

[centers, coefs] = stbrk(st);

if iscell(x) % we must determine the gridpoints from the given univariate meshes
    [xx,yy] = ndgrid(x{1},x{2});
    nx = [length(x{1}),length(x{2})];
    x = [reshape(xx,1,prod(nx));reshape(yy,1,prod(nx))];
else
    [mx,nx] = size(x);
    if mx~=2
        if nx==2 %switch the two
            x = x.'; nx = mx;
        else
            error(message('SPLINES:STVAL:wrongsizex'))
        end
    end
end

d = size(coefs,1); lx = size(x,2); values = zeros(d,lx);

% avoid use of out-of-core memory by doing calculations in small enough 
% pieces if need be; the upper limit, of 100000, is well below what it
% has to be, but the resulting time penalty for this undershot is
% negligible compared to the cost of this calculation:

lefttodo = lx*size(centers,2);
segments = ceil(lefttodo/100000);
llx = round(linspace(0,lx,segments+1));

for j=1:segments 
   values(:,llx(j)+1:llx(j+1)) = ...
        coefs*stcol(centers, x(:,llx(j)+1:llx(j+1)), 'tr', st.form(4:end)); 
end

if d>1||length(nx)==1, nx = [d nx]; end
values = reshape(values,nx);

function obj = sethandles(libname,obj)
% SETHANDLES set up the function handle components of a library function.
% OBJ_OUT = SETHANDLES(FUNNAME, OBJ) set the fields of OBJ that
% contain function handles, and is normally done by LIBLOOKUP
% during object creation or after the object is loaded from a file.
%
% Note: .expr, .derexpr, .intexpr functions may assume X is a column vector.

% Syntax for functions that function handles point to:
% Function evaluation, which is called via fittype/feval (with or
% without optimization):
%   function [F,J] = eqn(coeff1,coeff2,...,probparam1,probparam2,...
%                probconstant1,probconstant2,...,X)
%   (probparams and probconstants are optional. probconstants are
%   "inserted" into the call during fittype/feval method rather
%   than explicitly passed in.)
%
% Function evaluation, which is called via fittype/feval (with or
% separable optimization):
%   function [F,J,allcoeffs] = eqn(nonlinearcoeff1,nonlinearcoeff2, ...
%     probparam1,probparam2,...Y,'separable',probconstant1,probconstant2,X)
%   (probparams and probconstants are optional.
%   Note: probconstants are "inserted" into the call during fittype/feval
%   method rather than explicitly passed in.)
%
% Function start point calculation (called from FIT and
% cftoolgui/private/getstartpoint):
%   function start =
%   eqnstart(probparam1,probparam2,...,X,Y,probconstants)
%   (probparams and probconstants are optional.)
%
% Function derivaties (called from cfit/derivative):
%   function [deriv1,deriv2]  = eqnder(coeff1,coeff2,...,probparam1,probparam2,...
%                probconstant1,probconstant2,...,X)
%   (probparams and probconstants are optional)
%
% Function integration (called from cfit/integrate):
%   function int = eqnint(coeff1,coeff2,...,probparam1,probparam2,...
%                probconstant1,probconstant2,...,X)
%   (probparams and probconstants are optional)

%   Copyright 2001-2017 The MathWorks, Inc.

switch libname(1:3)
case 'exp'
    n = str2double(libname(end));
    if n == 1
        obj.expr = @exp1;
        obj.derexpr = @exp1der;
        obj.intexpr = @exp1int;
        obj.fStartpt = @exp1start;
    else
        obj.expr = @exp2;
        obj.derexpr = @exp2der;
        obj.intexpr = @exp2int;
        obj.fStartpt = @exp2start;
    end
case 'pow'
    n = str2double(libname(end));
    if n == 1
        obj.expr = @power1;
        obj.derexpr = @power1der;
        obj.intexpr = @power1int;
        obj.fStartpt = @power1start;
    else
        obj.expr = @power2;
        obj.derexpr = @power2der;
        obj.intexpr = @power2int;
        obj.fStartpt = @power2start;
    end
case 'gau'
    obj.expr = @gaussn;
    obj.derexpr = @gaussnder;
    obj.intexpr = @gaussnint;
    obj.fStartpt = @gaussnstart;
case 'sin'
    obj.expr = @sinn;
    obj.derexpr = @sinnder;
    obj.intexpr = @sinnint;
    obj.fStartpt = @sinnstart;
case 'rat'
    obj.expr = @ratn;
    obj.derexpr = @ratnder;
    m = str2double(libname(end));
    if m <= 2
        obj.intexpr = @ratnint;
    end
case 'wei'
    obj.expr = @weibull;
    obj.derexpr = @weibullder;
    obj.intexpr = @weibullint;
case 'fou'
    obj.expr = @fouriern;
    obj.derexpr = @fouriernder;
    obj.intexpr = @fouriernint;
    obj.fStartpt = @fouriernstart;
case 'pol'
    digits = isstrprop( libname, 'digit' );
    if digits(end) && ~digits(end-1)
        % Polynomial Curve
        % Y = P(1)*X^N + P(2)*X^(N-1) + ... + P(N)*X + P(N+1)
        obj.expr = @polyn;
        obj.derexpr = @polynder;
        obj.intexpr = @polynint;
        obj.fStartpt = [];
    elseif digits(end) && digits(end-1)
        % Polynomial Surface
        obj.expr = @polySurface;
        obj.derexpr = @polySurfaceDerivative;
        obj.intexpr = [];
        obj.fStartpt = [];
    else
        error(message('curvefit:fittype:sethandles:LibNameNotFound', libname));
    end
case {'smo','cub','nea','spl','lin','pch','bih','thi'}
    if size( obj.indep, 1 ) == 1 % curve
        obj.expr = @ppval;
        obj.derexpr = @ppder;
        obj.intexpr = @ppint;
    else % assume surface
        obj.expr = @evaluate;
        obj.derexpr = [];
        obj.intexpr = [];
    end
case {'low', 'loe'}
    obj.expr = @iLowess;
    obj.derexpr = [];
    obj.intexpr = [];
otherwise
    error(message('curvefit:fittype:sethandles:LibNameNotFound', libname));
end
end  % sethandles

%---------------------------------------------------------
%  EXP1
%---------------------------------------------------------
function [f,J,p] = exp1(varargin)
% EXP1 library function a*exp(b*x).
% F = EXP1(A,B,X) returns function value F at A,B,X.
%
% [F,J] = exp1(A,B,X) returns function and Jacobian values, F and J,
% at A,B,X.
%
% [F,Jnonlinear] = exp1(B,Y,wts,'separable',X) is used with separable
% least squares to compute F and "reduced" J (J with respect
% to only the nonlinear coefficients).
%
% [F,J,p] = exp1(B,Y,wts,'separable',X) is the syntax when optimizing using
% separable least squares to get all the coefficients p, linear and nonlinear,
% as well as F and the "full" Jacobian J with respect to all the coefficients.

separable = isequal(varargin{end-1},'separable');
if separable
    [b,y,wts,~,x] = deal(varargin{:});
    sqrtwts = sqrt(wts);
    ws = warning('off', 'all');
    a = sqrtwts.*(exp(b*x))\(sqrtwts.*y);
    warning(ws);
else
    [a,b,x] = deal(varargin{:});
end
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
f = iSimpleExp1( a, b, x );

if nargout > 1
    if separable && isequal(nargout,2)
        J = f.*x;
    else % ~separable or (separable and nargout > 2)
        J = [exp(b*x) f.*x];
        if nargout > 2
            p = [a;b];
        end
    end
end
end  % exp1

function f = iSimpleExp1( a, b, x )
% iSimpleExp1   Simple evaluation of an 'exp1' model.
if a == 0
    f = zeros( size( x ) );
else
    f = a*exp( b*x );
end
end  % iSimpleExp1

%---------------------------------------------------------
function [deriv1,deriv2] = exp1der(a,b,x)
% EXP1DER derivative function for EXP1 library function.
% DERIV1 = EXP1DER(A,B,X) returns the derivative DERIV1 with
% respect to x at the points X.
%
% [DERIV1,DERIV2] = EXP1DER(A,B,X) also returns the second
% derivative DERIV2.

f = iSimpleExp1( a, b, x );

deriv1 = b*f;
deriv2 = b*deriv1;
end  % exp1der

%---------------------------------------------------------
function int = exp1int(a,b,x)
% EXP1INT integral function for EXP1 library function.
% INT = EXP1INT(A,B,X) returns the integral function with
% respect to x at the points X.

if b==0
    int = a*x;
else
    int = iSimpleExp1( a, b, x )/b;
end
end  % exp1int

%---------------------------------------------------------
function start  = exp1start(x,y)
% EXP1START start point for EXP1 library function.
% START = EXP1START(X,Y) computes a start point START based on X.
% START is a column vector, e.g. [a0; b0].

% The idea in the starting point computation is to use geometric
% sequence. If the xdata is uniformly distributed, then the y data
% should form a geometric sequence. Using the summation formula for
% geometric sequence and the know y data, we can get an equation of the
% unknown parameter and solve them. In the case where x is not uniformly
% distributed, we use the given (x,y) data to generate uniformly
% distributed data, and start from there. The interpolation is done
% using the exponential function at the two ends.
%
% Reference: "Initial Values for the Exponential Sum Least Squares
% Fitting Problem"  by Joran Petersson and Kenneth Holmstrom
% http://www.ima.mdh.se/tom

x = x(:); y = y(:);
if any(diff(x)<0) % sort x
    [x,idx] = sort(x);
    y = y(idx);
end
n = length(x);
q = floor(n/2);
if q < 1
    iTwoDataPointsRequiredError()
end

if any(diff(diff(x))>1/n^2) % non-uniform x so create uniform x1
    % since we are going to use x as bin boundaries, we will not need
    % repeated entries.
    idx = (diff(x) < eps^0.7);
    x(idx) = [];
    y(idx) = []; % ideally, we should take average of y's on identical x.
    n = length(x);
    if n < 2 % can't do anything, return rand;
      start = rand(2,1);
      return;
    end
    q = floor(n/2);
    sid = sign(y);
    x1 = linspace( min( x ), max( x ), n )'; % n > 1
    x1(end) = x1(end) - eps(x1(end));
    [~,id]=histc(x1,x);
    id(id==n) = n-1;
    y = log(abs(y)+eps);
    b = (y(id+1)-y(id))./(x(id+1)-x(id));
    a = y(id)-b.*x(id);
    y = sid.*exp(a+b.*x1);
    x = x1;
end

S1 = sum(y(1:q));
% This should happen very rarely. If it happens, i.e. S1 =
% 0, then, we reduce q by 1 and recompute S1. If q can't be
% reduced any more, it means we have many zeros in y, a natural
% starting point would be [0 0], thus we return that.
while (S1 == 0)
    q = q-1;
    if q < 1
        start = [0 0]; return;
    end
    S1 = sum(y(1:q));
end
S2 = sum(y(q+1:2*q));
mx = mean(diff(x));
if mx <= 0
    % For constant x, we can't make any decent guess at the coefficient. Therefore we
    % make an arbitrary choice.
    b = 1;
else
    b = log((S2/S1)^(1/q))/mx; % q > 0, x sorted.
end
a = sum(y)/sum(exp(b*x));

% If we have estimated a non-finite value for 'a' then the most likely cause is
% that exp(b*x) is zero. In that case, a*exp(b*x) is zero for all choices of 'a'
% and we may as well as choose 'a=1' as anything else.
if ~isfinite( a )
    a = 1;
end

start = [a b];
end  % exp1start

%---------------------------------------------------------
%  EXP2
%---------------------------------------------------------
function [f,J,p] = exp2(varargin)
% EXP2 library function a*exp(b*x)+c*exp(d*x).
% F = EXP2(A,B,C,D,X) returns function value F at A,B,C,D,X.
%
% [F,J] = EXP2(A,B,C,D,X) returns function and Jacobian values, F and
% J, at A,B,C,D,X.
%
% [F,Jnonlinear] = exp2(B,D,Y,wts,'separable',X) is used with separable
% least squares to compute F and "reduced" J (J with respect
% to only the nonlinear coefficients).
%
% [F,J,p] = exp2(B,D,Y,wts,'separable',X) is the syntax when optimizing using
% separable least squares to get all the coefficients p, linear and nonlinear,
% as well as F and the "full" Jacobian J with respect to all the coefficients.

[separable, a, b, c, d, x] = iParseExp2Arguments( varargin{:} );

if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end

% The 'exp2' model is made up of two terms that are each an 'exp1' model.
term1 = iSimpleExp1( a, b, x );
term2 = iSimpleExp1( c, d, x );
f = term1 + term2;

if nargout > 1
    if separable && isequal(nargout,2) % reduced J
        J = [term1.*x term2.*x];
    else % ~separable or (separable and nargout > 2)
        J = [exp(b*x), term1.*x, exp(d*x), term2.*x];
        if nargout > 2
            p = [a; b; c; d];
        end
    end
end
end  % exp2

function [separable, a, b, c, d, x] = iParseExp2Arguments( varargin )
separable = isequal(varargin{end-1},'separable');
if separable
    [b,d,y,wts,~,x] = deal(varargin{:});
    sqrtwts = sqrt(wts);
    D = repmat(sqrtwts,1,2);
    ws = warning('off', 'all');
    lincoeffs = D.*[exp(b*x) exp(d*x)]\(sqrtwts.*y);
    warning(ws);
    a = lincoeffs(1);
    c = lincoeffs(2);
else
    [a,b,c,d,x] = deal(varargin{:});
end
end  % iParseExp2Arguments

%---------------------------------------------------------
function [deriv1,deriv2] = exp2der(a,b,c,d,x)
% EXP2DER derivative function for EXP2 library function.
% DERIV1 = EXP2DER(A,B,X) returns the derivative DERIV1 with
% respect to x at the points X.
%
% [DERIV1,DERIV2] = EXP2DER(A,B,X) also returns the second
% derivative DERIV2.

% First term: derivatives one and two
[t1d1, t1d2] = exp1der( a, b, x );
% Second term: derivatives one and two
[t2d1, t2d2] = exp1der( c, d, x );

% First derivative: sum from terms one and two
deriv1 = t1d1 + t2d1;
% Second derivative: sum from terms one and two
deriv2 = t1d2 + t2d2;
end  % exp2der

%---------------------------------------------------------
function int = exp2int(a,b,c,d,x)
% EXP2INT integral function for EXP2 library function.
% INT = EXP2INT(A,B,C,D,X) returns the integral function with
% respect to x at the points X.

int = exp1int( a, b, x ) + exp1int( c, d, x );
end  % exp2int

%---------------------------------------------------------
function start  = exp2start(x,y)
% EXP2START start point for EXP2 library function.
% START = EXP2START(X) computes a start point START based on X.
% START is a column vector, e.g. [a0; b0].

% The starting point computation use the same idea as in
% exp1start(). The difference here is that the resulting equation is a
% quadratic instead of linear equation. Also, since there are 4
% unknowns, we need to partition the data into 4 parts instead of 2
% parts. See exp1start() for reference.

x = x(:); y = y(:);
if any(diff(x)<0) % sort x
    [x,idx] = sort(x);
    y = y(idx);
end
n = length(x);
q = floor(n/4);

if q < 1
    error(message('curvefit:fittype:sethandles:fourDataPointsRequired'));
end

if any(diff(diff(x))>1/n^2) % non-uniform x so create uniform x1
    % since we are going to use x as bin boundaries, we will not need
    % repeated entries.
    idx = (diff(x) < eps^0.7);
    x(idx) = [];
    y(idx) = []; % ideally, we should take average of y's on identical x.
    n = length(x);
    if n < 2 % can't do anything, return rand;
      start = rand(2,1);
      return;
    end
    q = floor(n/4);
    sid = sign(y);
    x1 = linspace( min( x ), max( x ), n )'; % n > 1
    x1(end) = x1(end) - eps(x1(end));
    [~,id]=histc(x1,x);
    id(id==n) = n-1;
    y = log(abs(y)+eps);
    b = (y(id+1)-y(id))./(x(id+1)-x(id)); % x unique, can't be 0
    a = y(id)-b.*x(id);
    y = sid.*exp(a+b.*x1);
    x = x1;
end

s = zeros(4,1);
for i=1:4
    s(i) = sum(y((i-1)*q+1:i*q));
end

tmp2 = 2*(s(2)^2-s(1)*s(3));
% This should happen very rarely. If it happens, i.e. S1 =
% 0, then, we reduce q by 1 and recompute S1. If q can't be
% reduced any more, it means we have many zeros in y, a natural
% starting point would be [0 0], thus we return that.
while (tmp2 == 0)
    q = q-1;
    if q < 1
        start = [0 0 0 0]; return;
    end
    for i=1:4
        s(i) = sum(y((i-1)*q+1:i*q));
    end
    tmp2 = 2*(s(2)^2-s(1)*s(3));
end

tmp = sqrt((s(1)^2)*(s(4)^2)-6*prod(s)-3*(s(2)^2)*(s(3)^2)+...
    4*s(1)*s(3)^3+4*(s(2)^3)*s(4));
tmp1 = s(1)*s(4)-s(2)*s(3);
tmp2 = 2*(s(2)^2-s(1)*s(3));
z1 = (tmp-tmp1)/tmp2;    % tmp2 ~= 0
z2 = (tmp+tmp1)/tmp2;
mx = mean(diff(x));
if mx <= 0
    s(2) = 1;
    s(4) = 1;
else
    s(2) = real(log((z1)^(1/q)))/mx; % x sorted, mx > 0
    s(4) = real(log((z2)^(1/q)))/mx;
end
ws = warning('off', 'all');
s([1 3]) = [exp(s(2)*x) exp(s(4)*x)]\y;

if ~all(isfinite(s([1 3])))
    s([1 3]) = 0;
end

warning(ws);
start = s;
end  % exp2start

%---------------------------------------------------------
%  POWER1
%---------------------------------------------------------
function [f, J, p] = power1(varargin)
% POWER1 library function a*x^b.
% F = POWER1(A,B,X) returns function value F at A,B,X.
%
% [F,J] = power1(A,B,X) returns function and Jacobian values, F and J, at A,B,X.
%
% [F,Jnonlinear] = power1(B,Y,wts,'separable',X) is used with separable
% least squares to compute F and "reduced" J (J with respect
% to only the nonlinear coefficients).
%
% [F,J,p] = power1(B,Y,wts,'separable',X) is the syntax when optimizing using
% separable least squares to get all the coefficients p, linear and nonlinear,
% as well as F and the "full" Jacobian J with respect to all the coefficients.

separable = isequal(varargin{end-1},'separable');
if separable
    [b,y,wts,~,x] = deal(varargin{:});
    sqrtwts = sqrt(wts);
else
    [a,b,x] = deal(varargin{:});
end
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
f = zeros(size(x));
iposx = (x > 0);
posx = x(iposx);
if any(~iposx)
    warning(message('curvefit:fittype:sethandles:xMustBePositive'));
end
if separable
    % compute linear coefficients
    ws = warning('off', 'all');
    a = (sqrtwts.*x.^b) \ (sqrtwts.*y);
    warning(ws);
end
f(iposx) = a*posx.^b;
f(~iposx) = NaN;

if nargout > 1
    if separable && isequal(nargout,2) % reduced J
        J = zeros(size(x,1),1);
        J(iposx,:) = a*log(posx).*posx.^b;
        J(~iposx,:) = NaN;
    else % ~separable or (separable and nargout > 2)
        J = zeros(size(x,1),2);
        J(iposx,:) = [posx.^b a*log(posx).*posx.^b];
        J(~iposx,:) = NaN;
        if nargout > 2
            p = [a; b];
        end
    end
end
end  % power1

%---------------------------------------------------------
function [deriv1,deriv2]  = power1der(a,b,x)
% POWER1DER derivative function for POWER1 library function.
% DERIV1 = POWER1DER(A,B,X) returns the derivative DERIV1 with
% respect to x at the points X.
%
% [DERIV1,DERIV2] = POWER1DER(A,B,X) also returns the second
% derivative DERIV2.

idx = (x>0);
if any(~idx)
    warning(message('curvefit:fittype:sethandles:xMustBePositive'));
end
xi = x(idx);

deriv1 = zeros(size(x));
deriv1(idx) = a*b*xi.^(b-1);
deriv1(~idx) = NaN;
deriv2 = zeros(size(x));
deriv2(idx) = a*b*(b-1)*xi.^(b-2);
deriv2(~idx) = NaN;
end  % power1der

%---------------------------------------------------------
function int = power1int(a,b,x)
% POWER1INT integral function for POWER1 library function.
% INT = POWER1INT(A,B,X) returns the integral function with
% respect to x at the points X.

idx = (x>0);
if any(~idx)
    warning(message('curvefit:fittype:sethandles:xMustBePositive'));
end
xi = x(idx);

int = zeros(size(x));

if b==-1
    int(idx) = a*log(xi);
else
    int(idx) = a*xi.^(b+1)/(b+1);
end
int(~idx) = NaN;
end  % power1int

%---------------------------------------------------------
function start = power1start( x, y )
%POWER1START   Start point for POWER1 library function.
%
%   START = POWER1START(X, Y) computes a start point START based on data X,
%   Y. START is a column vector, i.e., [a0; b0].

% To get the initial estimate for the power1 model we use the initial
% estimate for the power2 model and then ignore the constant (third
% coefficient).
start = power2start( x, y );
start = start(1:2);
end  % power1start

%---------------------------------------------------------
%  POWER2
%---------------------------------------------------------
function [f, J, p] = power2(varargin)
% POWER2 library function c+a*x^b.
% F = POWER2(A,B,C,X) returns function value F at A,B,C,X.
%
% [F,J] = power2(A,B,C,X) returns function and Jacobian values, F and
% J, at A,B,C,X.
%
% [F,Jnonlinear] = power2(B,Y,wts,'separable',X) is used with separable
% least squares to compute F and "reduced" J (J with respect
% to only the nonlinear coefficients).
%
% [F,J,p] = power2(B,Y,wts,'separable',X) is the syntax when optimizing using
% separable least squares to get all the coefficients p, linear and nonlinear,
% as well as F and the "full" Jacobian J with respect to all the coefficients.

separable = isequal(varargin{end-1},'separable');

if separable
    [b,y,wts,~,x] = deal(varargin{:});
    sqrtwts = sqrt(wts);
else
    [a,b,c,x] = deal(varargin{:});
end
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
f = zeros(size(x));
iposx = (x > 0);
posx = x(iposx);
if any(~iposx)
    warning(message('curvefit:fittype:sethandles:xMustBePositive'));
end
if separable
    % compute linear coefficients
    D = repmat(sqrtwts,1,2);
    ws = warning('off', 'all');
    lincoeffs = D.*[x.^b ones(size(x))]\(sqrtwts.*y);
    warning(ws);
    a = lincoeffs(1);
    c = lincoeffs(2);
end
f(iposx) = a*posx.^b + c;
f(~iposx) = NaN;
if nargout > 1
    if separable && isequal(nargout,2) % reduced J
        J = zeros(size(x,1),1);
        J(iposx,:) = a*log(posx).*posx.^b;
        J(~iposx,:) = NaN;
    else  % ~separable or (separable and nargout > 2)
        J = zeros(size(x,1),3);
        J(iposx,:) = [posx.^b, a*log(posx).*posx.^b, ones(size(posx))];
        J(~iposx,:) = NaN;
        if nargout > 2
            p = [a; b; c];
        end
    end
end
end  % power2

%---------------------------------------------------------
function [deriv1,deriv2]  = power2der(a,b,~,x)
% POWER2DER derivative function for POWER2 library function.
% DERIV1 = POWER2DER(A,B,C,X) returns the derivative DERIV1 with
% respect to x at the points X.
%
% [DERIV1,DERIV2] = POWER2DER(A,B,C,X) also returns the second
% derivative DERIV2.

idx = (x>0);
if any(~idx)
    warning(message('curvefit:fittype:sethandles:xMustBePositive'));
end
xi = x(idx);

deriv1 = zeros(size(x));
deriv1(idx) = a*b*xi.^(b-1);
deriv1(~idx) = NaN;
deriv2 = zeros(size(x));
deriv2(idx) = a*b*(b-1)*xi.^(b-2);
deriv2(~idx) = NaN;
end  % power2der

%--------------------------------------------------------
function int = power2int(a,b,c,x)
% POWER2INT integral function for POWER2 library function.
% INT = POWER2INT(A,B,X) returns the integral function with
% respect to x at the points X.

idx = (x>0);
if any(~idx)
    warning(message('curvefit:fittype:sethandles:xMustBePositive'));
end
xi = x(idx);

int = zeros(size(x));
if b==-1
    int(idx) = a*log(xi)+c*xi;
else
    int(idx) = a*xi.^(b+1)/(b+1)+c*xi;
end
int(~idx) = NaN;
end  % power2int

%---------------------------------------------------------
function start  = power2start(x,y)
% POWER2START start point for POWER2 library function.
% START = POWER2START(X) computes a start point START based on X.
% START is a column vector, e.g. [a0; b0;c0].

% The idea here is to assume every data point is exactly from a power
% function and compute the coefficient |b| at each point. Then compute the
% mean of these estimates of |b| to get an estimate of |b| for all the data.
% Use this |b| to compute |a|. The question is, whether we should use
% arithmetic mean or geometric mean. For some data, arithmetic mean works
% well, for others, geometric means works well. We choose arithmetic mean.

% Ensure that we have column vectors
x = x(:);
y = y(:);

% Ensure that the x-data is positive
[x, y] = iEnsurePositiveData( x, y, ...
    message( 'curvefit:fittype:sethandles:xMustBePositive' ) );

% Ensure that the y-data is positive 
[y, x] = iEnsurePositiveData( y, x, '' );

% Make the first element the one with minimal x-value.
[x, y] = iMakeMinXFirst( x, y );

% If there are fewer than two data points
if numel( x ) < 2
    % ... then we cannot compute start points so we use random values
    a = rand( 1 );
    b = rand( 1 );
    c = rand( 1 );
else
    % Compute the value of |b| by assuming all data is from the same power
    % function.
    b = mean( log( y(1)./y(2:end) )./log( x(1)./x(2:end) ) );
    % Given a value for |b|, compute the value of |a| by assuming all the
    % data is from the same power function.
    a = mean( y./x.^b );
    % Given values for |a| and |b| we can estimate a initial guess for |c|
    % by subtracting the mean residual for the 'power1' model from the
    % data.
    c = mean( y - power1( a, b, x ) );
end

% Concatenate the coefficients and return the answer.
start = [a; b; c];
end  % power2start

%---------------------------------------------------------
function [u, v] = iEnsurePositiveData( u, v, warningString )
% iEnsurePositiveData   Ensure that curve data contains positive elements.
%
% Given vectors of curve data, U and V, the u-data is checked for any
% non-positive data. If such data is found, those points are removed from U
% and V and a warning is thrown using the given string. That string maybe
% empty, in which case no warning is thrown.

% If any of the u-data is non-positive ...
idx = (u <= 0);
if any( idx )
    % ... then throw a warning ...
    warning( warningString );
    % ... and remove those data points.
    u(idx) = [];
    v(idx) = [];
end
end  % iEnsurePositiveData

%---------------------------------------------------------
function [x, y] = iMakeMinXFirst( x, y )
% iMakeMinXFirst   Reorder curve data so that the point with the minimum
% x-value is first in the vectors. If there are duplicate points with
% minimal x-value then these points are coalesced into a single point by
% taking the mean of the corresponding y-data.
%
% Note that if the inputs x and y are empty then the outputs will be x is
% empty and y = NaN.

% We want to use the left most (minimal x) data point as a special point.
minX = min( x );
% However, we need to there to be a unique special point. 
% Hence we find all the x-data that matches the minimal x-value...
idx = find( minX == x );
% ... then replace the left most y-data point with the mean of the y-data
% corresponding to the left most x-data...
minY = mean( y(idx) );
% ... and then remove these minimal x data points.
x(idx) = [];
y(idx) = [];
% Insert the left most data point back into the data vectors, ensuring that
% it is the first point in the list.
x = [minX; x];
y = [minY; y];
end  % iMakeMinXFirst

%---------------------------------------------------------
%  Weibull function
%---------------------------------------------------------
function [f,J] = weibull(a,b,x)
% WEIBULL library function a*b*x^(b-1)*exp(-a*x^b)
% F = WEIBULL(A,B,X) returns function value F at A,B,X.
%
% [F,J] = WEIBULL(A,B,X) returns function and Jacobian values, F and
% J, at A,B,X.

if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
idx = (x>0);
if any(~idx)
    warning(message('curvefit:fittype:sethandles:WeibullxMustBePositive'));
end
xi = x(idx);
f = zeros(size(x));

f(idx) = a*b*xi.^(b-1).*exp(-a*xi.^b);
f(~idx) = NaN;
if nargout > 1
    J = zeros(size(x,1),2);
    if a == 0
        J(idx,:) = [b*xi.^(b-1) 0*xi];
    elseif b == 0
        J(idx,:) = [0*xi a*exp(-a)./xi];
    else
        J(idx,:) = [(1/a-xi.^b).*f(idx) (1/b+(1-a*xi.^b).*log(xi)).*f(idx)];
    end
    J(~idx,:) = NaN;
end
end  % weibull

%---------------------------------------------------------
function [deriv1,deriv2]  = weibullder(a,b,x)
% WEIBULLDER derivative function for WEIBULL library function.
% DERIV1 = WEIBULLDER(A,B,X) returns the derivative DERIV1 with
% respect to x at the points X.
%
% [DERIV1,DERIV2] = WEIBULLDER(A,B,X) also returns the second
% derivative DERIV2.

idx = (x>0);
if any(~idx)
    warning(message('curvefit:fittype:sethandles:WeibullxMustBePositive'));
end
xi = x(idx);
deriv1 = zeros(size(x));
deriv2 = zeros(size(x));

f = a*b*xi.^(b-3).*exp(-a*xi.^b);
deriv1(idx) = f.*xi.*(b-1-a*b*xi.^b);
deriv2(idx) = f.*((b-1-a*b*xi.^b).^2-(b-1)-a*b*(b-1)*xi.^b);
deriv1(~idx) = NaN;
deriv2(~idx) = NaN;
end  % weibullder

%---------------------------------------------------------
function int = weibullint(a,b,x)
% WEIBULLINT integral function for WEIBULL library function.
% INT = WEIBULLINT(A,B,C,D,X) returns the integral function with
% respect to x at the points X.

idx = (x>0);
if any(~idx)
    warning(message('curvefit:fittype:sethandles:WeibullxMustBePositive'));
end
xi = x(idx);

int = zeros(size(x));
int(idx) = -exp(-a*xi.^b);
int(~idx) = NaN;
end  % weibullint

%---------------------------------------------------------
%  POLYN
%---------------------------------------------------------
function [f, J] = polyn(varargin)
% POLYN library function for P1*X^N + P2*X^(N-1) + ... + PN+1.
% F = POLYN(P1,P2,...,PN+1,X) returns function value F at
% P1,P2,...,PN+1,X.
%
% [F,J] = POLYN(P1,P2,...,PN+1,X) returns function and Jacobian values, F and
% J, at P1,P2,...,PN+1,X.

if (nargin < 2)
    error(message('curvefit:fittype:sethandles:tooFewImports'));
end
n = nargin - 1;
p = [varargin{1:end-1}];
x = varargin{end};
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
f = polyval( p, x );
if nargout > 1
    J = [zeros(length(x),n-1) ones(length(x),1)];
    % Horner's rule
    for i = n-1 : -1 : 1
        J(:,i) = x .* J(:,i+1);
    end
end
end  % polyn

%---------------------------------------------------------
function [deriv1,deriv2] = polynder(varargin)
% POLYNDER derivative function for POLYN library function.
% DERIV1 = POLYNDER(P1,P2,...PN+1,X) returns the derivative DERIV1 with
% respect to X at the points X for an Nth degree polynomial. DERIV1
% is a vector the same length as X.
%
% [DERIV1,DERIV2] = POLYNDER(P1,P2,...PN+1,X) also returns the second
% derivative DERIV2, also a vector the length of X.

if (nargin < 3)
    error(message('curvefit:fittype:sethandles:tooFewImports'));
end
n = nargin - 1;
p = [varargin{1:n}];
x = varargin{end};
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end

p = p(1:end-1).*((n-1):-1:1);
deriv1 = polyval( p, x );
if nargout > 1
    if n < 3
        deriv2 = zeros(size(x));
    else
        p = p(1:end-1).*((n-2):-1:1);
        deriv2 = polyval( p, x );
    end
end
end  % polynder

%---------------------------------------------------------
function int = polynint(varargin)
% POLYNINT integral function for POLYN library function.
% INT = POLYNINT(P1,P2,...PN+1,X) returns the integral INT with
% respect to X at the points X for an Nth degree polynomial. INT
% is a vector the same length as X.

if (nargin < 3)
    error(message('curvefit:fittype:sethandles:tooFewImports'));
end
n = nargin - 1;
p = [varargin{1:n}];
x = varargin{end};
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:InputXMustBeColVector'));
end

p = p./(n:-1:1);
int = polyval( [p 0], x );
end  % polynint

%---------------------------------------------------------
%  Polynomial Surface
%---------------------------------------------------------
function [f, J] = polySurface( varargin )
% POLYSURFACE   Library function for polynomial surface.
%
%   F = POLYSURFACE( P1, ..., Pxnym, M, N, X, Y ) returns the valus of the
%   polynomial of degree M in X and degree N in Y with the given coefficients
%   evaluated at the given X and Y.

[coeffs, m, n, x, y] = parsePolySurfaceInputs( varargin{:} );
maxDegree = max( m, n );

% Start with the constant: 
f = repmat( coeffs(1), size( x ) );
% The counter k will move along the coefficients
k = 1;
for i = 1:maxDegree
    for j = i:-1:0
        if j <= m && (i-j) <=n
            k = k + 1;
            % The k-th term is x^j * y^(i-j)
            f = f + coeffs(k) * x.^j .* y.^(i-j);
        end
    end
end

% Jacobian
% J(i,k) = df/db(k)(x(i),y(i))
if nargout > 1
    J = zeros( numel( x ), length( coeffs ) );
    % Constant
    J(:,1) = 1;
    % The counter k will move along the coefficients
    k = 1;
    for i = 1:maxDegree
        for j = i:-1:0
            if j <= m && (i-j) <=n
                k = k + 1;
                % The k-th term is x^j * y^(i-j)
                J(:,k) = x.^j .* y.^(i-j);
            end
        end
    end
end
end  % polySurface

%---------------------------------------------------------
function [fx, fy, fxx, fxy, fyy] = polySurfaceDerivative( varargin )
% POLYSURFACEDERIVATIVE  Library function for polynomial surface derivatives
%
%   [...] = POLYSURFACEDERIVATIVE( P1, ..., Pxnym, M, N, X, Y ) returns the
%   valus of the derivatives of the polynomial of degree M in X and degree N in
%   Y with the given coefficients evaluated at the given X and Y.
%
%   This code assumes that X and Y are columns.
[coeffs, m, n, x, y] = parsePolySurfaceInputs( varargin{:} );

[fx, fy] = polySurfaceFirstDerivatives(coeffs, m, n, x, y);

% Do we need to compute second derivatives?
doSecondDerivatives = (nargout >= 3);

if doSecondDerivatives
    [fxx, fxy, fyy] = polySurfaceSecondDerivatives(coeffs, m, n, x, y);
end
end

function [fx, fy] = polySurfaceFirstDerivatives(coeffs, m, n, x, y)
% Ignore the constant and start with zero
fx  = zeros( size( x ) );
fy  = zeros( size( x ) );
maxDegree = max( m, n );
% The counter k will move along the coefficients
k = 1;
for i = 1:maxDegree
    for j = i:-1:0
        if j <= m && (i-j) <=n
            k = k + 1;
            % The k-th term is x^j * y^(i-j)
            fx = fx + iKTermFirstDerivativeInX(coeffs(k), x, y, j, i);
            fy = fy + iKTermFirstDerivativeInY(coeffs(k), x, y, j, i);
        end
    end
end
end

function [fxx, fxy, fyy] = polySurfaceSecondDerivatives(coeffs, m, n, x, y)
maxDegree = max( m, n );
% Ignore the constant and start with zero
fxx = zeros( size( x ) );
fxy = zeros( size( x ) );
fyy = zeros( size( x ) );
% The counter k will move along the coefficients
k = 1;
for i = 1:maxDegree
    for j = i:-1:0
        if j <= m && (i-j) <=n
            k = k + 1;
            % The k-th term is x^j * y^(i-j)
            fxx = fxx + iKTermSecondDerivativeInX(coeffs(k), x, y, j, i);
            fyy = fyy + iKTermSecondDerivativeInY(coeffs(k), x, y, j, i);
            fxy = fxy + iKTermMixedDerivative(coeffs(k), x, y, j, i);
        end
    end
end 
end

function fx = iKTermFirstDerivativeInX(coeff, x, y, j, i)
% The derivative of the k-th term wrt to x is j * x^(j-1) * y^(i-j)
if j>0 
    fx = coeff * j * x.^(j-1) .* y.^(i-j);
else
    % The derivative is 0, so don't compute it
    fx = zeros( size( x ) );
end
end

function fy = iKTermFirstDerivativeInY(coeff, x, y, j, i)
% The derivative of the k-th term wrt to y is (i-j) * x^(j) * y^(i-j-1)
if i-j>0
    fy = coeff * (i-j) * x.^(j) .* y.^(i-j-1);
else
    % The derivative is 0, so don't compute it
    fy = zeros( size( x ) );
end
end

function fxx = iKTermSecondDerivativeInX(coeff, x, y, j, i)
% The 2nd derivative of the k-th term wrt to x is (j-1)*j * x^(j-2) * y^(i-j)
if j>1
    fxx = coeff * j * (j-1) * x.^(j-2) .* y.^(i-j);
else
    % The derivative is 0, so don't compute it
    fxx = zeros( size( x ) );
end
end

function fyy = iKTermSecondDerivativeInY(coeff, x, y, j, i)
% The 2nd derivative of the k-th term wrt to y is (i-j) *(i-j-1) * x^(j) * y^(i-j-2)
if i-j>1
    fyy = coeff * (i-j) * (i-j-1) * x.^(j) .* y.^(i-j-2);
else
    % The derivative is 0, so don't compute it
    fyy = zeros( size( x ) );
end
end

function fxy = iKTermMixedDerivative(coeff, x, y, j, i)
% The mixed 2nd derivative of the k-th term is j * (i-j) * x^(j-1) * y^(i-j-1)
if j>0 && i-j>0
    fxy = coeff * j * (i-j) * x.^(j-1) .* y.^(i-j-1);
else
    % The derivative is 0, so don't compute it
    fxy = zeros( size( x ) );
end
end

%---------------------------------------------------------
function [coeffs, m, n, x, y] = parsePolySurfaceInputs( varargin )
% PARSEPOLYSURFACEINPUTS  Parse argument list for polynomial surface functions.
%
% [COEFFS, M, N, X, Y] = PARSEPOLYSURFACEINPUTS( P1, ..., Pxnym, M, N, X, Y )
%
% This function pulls out the coefficients, COEFFS = {P1, ..., Pxnym}, and
% essentially lets the other arguments fall through.

% We parse the arguments by looking at the last few things and assuming that all
% else are coefficients
y = varargin{end};
x = varargin{end-1};
n = varargin{end-2};
m = varargin{end-3};
coeffs = [varargin{1:end-4}];
end  % parsePolySurfaceInputs

%---------------------------------------------------------
%  FOURIERN
%---------------------------------------------------------
function [f, J, p] = fouriern(varargin)
% FOURIERN library function for fourier sequence:
% a0+sum(ai*cos(i*x*w)+bi*sin(i*x*w), i=1,...,n).
% F = FOURIERN(A0,A1,B1,...,AN,BN,W,N,X) returns function
% value F at (A0, A1, B1, ... ,AN, BN, W, N, X).
%
% [F,J] = FOURIERN(...,X) returns function and Jacobian values, F and
% J, at (...,X).
%
% [F,Jnonlinear] = fouriern(w,Y,wts,'separable',n,X) is used with
% separable least squares to compute F and "reduced" J (J with respect
% to only the nonlinear coefficients).
%
% [F,J,p] = fouriern(w,Y,wts,'separable',n,X) is the syntax when
% optimizing using separable least squares to get all the coefficients
% p, linear and nonlinear, as well as F and the "full" Jacobian J with
% respect to all the coefficients.

% Note: the problem constant "n" is added by fittype/feval and is not
% passed in directly when calling FOURIEN via feval.

separable = isequal(varargin{end-2},'separable');
if separable
  [w,y,wts,~,n,x] = deal(varargin{:});
  sqrtwts = sqrt(wts);
  extra = 5;  % extra is y, wts, 'separable', n, x
else
  x = varargin{end};
  n = varargin{end-1};
  w = varargin{end-2};
  extra = 2; % extra is n, x
end
if n < 1 || n > 9
  error(message('curvefit:fittype:sethandles:libFunctionNotFound'));
end

if nargin ~= ~separable*(2*n+1) + 1 + extra
  error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end

if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end

xw = x*w;
% get lincoeffs;
if separable
  A = zeros(length(x),2*n+1);
  A(:,1) = sqrtwts;
  for i=1:n
    ix = i*xw;
    A(:,2*i) = cos(ix).*sqrtwts;
    A(:,2*i+1) = sin(ix).*sqrtwts;
  end
  ws = warning('off', 'all');
  lincoeffs = A\(sqrtwts.*y);
  warning(ws);
  a0 = lincoeffs(1);
  a = lincoeffs(2:2:end)';
  b = lincoeffs(3:2:end)';
else
  a0 = varargin{1};
  a = [varargin{2:2:end-extra-1}];
  b = [varargin{3:2:end-extra-1}];
end

% compute the function value
f = a0;
for i = 1:n
    ix = i*xw;
    f = f + a(i)*cos(ix)+b(i)*sin(ix);
end

% get Jacobian.
if nargout > 1
  Jw = zeros(size(x));
  for i = 1:n
    ix = i*xw;
    Jw = Jw - i*x.*(a(i)*sin(ix) - b(i)*cos(ix));
  end
  if nargout < 3 && separable
    J = Jw;
  else
    J = zeros(length(x),2*n+2);
    J(:,1) = 1;
    J(:,end) = Jw;
    for i = 1:n
      ix = i*xw;
      J(:,2*i) = cos(ix);
      J(:,2*i+1) = sin(ix);
    end
    p = [a0; reshape([a; b],2*n,1); w];
  end
end
end  % fouriern

%---------------------------------------------------------
function [deriv1,deriv2] = fouriernder(varargin)
% FOURIERNDER derivative function for FOURIERN library function.
% DERIV1 = FOURIERNDER(A0,A1,B1,...,AN,BN,W,N,X) returns the derivative
% DERIV1 with respect to X at the points X for FOURIERN. DERIV1 is a
% vector with the same length as X.
%
% [DERIV1,DERIV2] = FOURIERNDER(A0,A1,B1,...,AN,BN,W,N,X) also returns
% the second derivative DERIV2, also a vector with the length of X.

if (nargin < 6)
    error(message('curvefit:fittype:sethandles:tooFewImports'));
end
n = varargin{end-1};
if nargin ~= 2*n+4
    error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end

a = [varargin{2:2:end-3}];
b = [varargin{3:2:end-3}];
w = varargin{end-2};
x = varargin{end};
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end

xw = x*w;

deriv1 = 0;
for i = 1:n
  ix = i*xw;
  deriv1 = deriv1 + i*w*(b(i)*cos(ix) - a(i)*sin(ix));
end

if nargout > 1
  deriv2 = 0;
  for i = 1:n
    ix = i*xw;
    deriv2 = deriv2 - i*i*w*w*(a(i)*cos(ix) + b(i)*sin(ix));
  end
end
end  % fouriernder

%---------------------------------------------------------
function int = fouriernint(varargin)
% FOURIERNINT integral function for FOURIERN library function.
% INT = FOURIERNINT(A0,A1,B1,...,AN,BN,W,N,X) returns the integral INT with
% respect to X at the points X FOURIERN. INT is a vector the same length as X.

if (nargin < 6)
    error(message('curvefit:fittype:sethandles:tooFewImports'));
end
n = varargin{end-1};
if nargin ~= 2*n+4
    error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end

a0 = varargin{1};
a = [varargin{2:2:end-3}];
b = [varargin{3:2:end-3}];
w = varargin{end-2};
x = varargin{end};
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end

int = a0*x;

xw = x*w;
for i = 1:n
    ix = i*xw;
    int = int + (a(i)*sin(ix) - b(i)*cos(ix))/(i*w);
end
end  % fouriernint

%---------------------------------------------------------
function start  = fouriernstart(x,y,n)
% FOURIERSTART start point for FOURIER library function.
% START = FOURIERSTART(X,Y,N) computes a start point START based on X.
% START is a scalar w; (other parameters are treated linearly).

% Create a lattice so we can use fft
[x,y] = getxygrid(x,y);

% Data size too small, cannot find starting values
if length(x) < 2
    start = rand(2*n+2,1);
    return;
end

% Apply fast fourier transform to the data points
fy = fft(y-mean(y));  % subtract mean to get rid of constant effect

% Find the peak frequency
[~,maxloc] = max(fy(1:floor(length(x)/2)));
wpeak = 2*pi*(max(0.5,maxloc-1))/(x(end)-x(1));

% We have an n term Fourier series with a fundamental frequency w
% and its harmonics.  Try all fundamental frequencies that include
% the peak frequency wpeak among the harmonics.
normr = Inf;
wbest = wpeak;
for k=1:n
    w = wpeak/k;
    X = fourierterms(x,w,n);
    [Q,R,perm_ignore] = qr(X,0); %#ok<NASGU>
    p = rank(R);
    Q = Q(:,1:p);
    yfit = Q * (Q' * y);
    newnorm = norm(y - yfit);
    if newnorm<normr
        normr = newnorm;
        wbest = w;
    end
end

start = zeros(2*n+2,1); % only the last element matters
start(end) = wbest;
end  % fouriernstart

% ------------ compute Fourier terms for fixed frequency
function X = fourierterms(x,w,n)
X = ones(length(x),1+2*n);
for j=1:n
    angle = j*x*w;
    base = 2*j - 1;
    X(:,base+1) = cos(angle);
    X(:,base+2) = sin(angle);
end
end  % fourierterms

%---------------------------------------------------------
%  gaussn
%---------------------------------------------------------
function [f,J,p] = gaussn(varargin)
% GAUSSN library function for sum of gaussians: sum(ai*exp(-((x-bi)/ci)^2))
% F = gaussn(A1,B1,C1,...An,Bn,Cn,n,X) returns function value F at (...,X).
%
% [F,J] = gaussn(...,X) returns function and Jacobian values, F and
% J, at (...,X)
%
% [F,Jnonlinear] = gaussn(b1,c1,...,bn,cn,Y,wts,'separable',n,X) is
% used with separable least squares to compute F and "reduced" J (J
% with respect to only the nonlinear coefficients).
%
% [F,J,p] = gaussn(b1,c1,...,bn,cn,Y,wts,'separable',n,X) is the
% syntax when optimizing using separable least squares to get all the
% coefficients p, linear and nonlinear, as well as F and the "full"
% Jacobian J with respect to all the coefficients.

% Note: the problem constant "n" is added by fittype/feval and is not
% passed in directly when calling GAUSSN via feval.

separable = isequal(varargin{end-2},'separable');
if separable
    extra = 5;  % extra is y, wts, 'separable', n, x
    y = varargin{end-4};
    wts = varargin{end-3};
    coeffcnt = 2; % bi, ci
else
    extra = 2; % extra is n, x
    coeffcnt = 3; % ai, bi, ci
end
n = varargin{end-1};
if n < 1 || n > 9
  error(message('curvefit:fittype:sethandles:libFunctionNotFound'));
end

count = (nargin-extra)/coeffcnt; % subtract n, x
if nargin < extra + coeffcnt || count ~= n
  error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end
x = varargin{end};
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
if separable
    b = [varargin{1:2:end-extra}];
    c = [varargin{2:2:end-extra}];
    sqrtwts = sqrt(wts);
    A = zeros(length(x),n);
    for i=1:n
        if c(i) == 0
            A(:,i) = ones(length(x),1); % a's can be anything due to singularity
        else
            A(:,i) = exp(-((x-b(i))/c(i)).^2);
        end
    end
    D = repmat(sqrtwts,1,size(A,2));
    ws = warning('off', 'all');
    lincoeffs = (D.*A)\(sqrtwts.*y);
    warning(ws);
    a = lincoeffs';
else
    a = [varargin{1:3:end-extra}];
    b = [varargin{2:3:end-extra}];
    c = [varargin{3:3:end-extra}];
end

f = 0;
for i=1:n
    if c(i) == 0
        df = zeros(length(x),1);
    else
        df = a(i)*exp(-((x-b(i))/c(i)).^2);
    end
    f = f + df;
end

if nargout > 1
    if isequal(nargout,3) % only nonlinear coeff coming in, but want full J
        Jcoeffcnt = coeffcnt + 1;
    else % J wrt number of coefficients coming in
        Jcoeffcnt = coeffcnt;
    end
    J = zeros(length(x),Jcoeffcnt*n);
    for i = 1:n
        if c(i) ~= 0
            tf = exp(-((x-b(i))/c(i)).^2);
            start = i*Jcoeffcnt - Jcoeffcnt + 1;
            if separable && isequal(nargout,2) % reduced J
                J(:,start:start+Jcoeffcnt-1) = [2*a(i)*(x-b(i)).*tf/c(i)^2 2*a(i)*tf.*(x-b(i)).^2/c(i)^3];
            else % ~separable or (separable and nargout > 2)
                J(:,start:start+Jcoeffcnt-1) = [tf 2*a(i)*(x-b(i)).*tf/c(i)^2 2*a(i)*tf.*(x-b(i)).^2/c(i)^3];
            end
        end
    end
    if nargout > 2
        p = reshape([a; b; c],3*n,1);
    end
end
end  % gaussn

%---------------------------------------------------------
function [deriv1,deriv2]  = gaussnder(varargin)
% GAUSSNDER derivative function for GAUSSN library function.
% DERIV1 = GAUSSNDER(A1,B1,C1,...,N,X) returns the derivative DERIV1 with
% respect to x at the points A1,B1,C1,...,X.
%
% [DERIV1,DERIV2] = GAUSSNDER(A1,B1,C1,...,N,X) also returns the second
% derivative DERIV2.

if nargin < 4 || rem(nargin,3) ~= 2
  error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end

a = [varargin{1:3:end-2}];
b = [varargin{2:3:end-2}];
c = [varargin{3:3:end-2}];
n = varargin{end-1};
x = varargin{end};

deriv1 = 0;
for i = 1:n
    if c(i) ~= 0 % when c(i) = 0, the increment will be 0.
        deriv1 = deriv1 + 2*a(i)*exp(-((x-b(i))/c(i)).^2).*(b(i)-x)/c(i)^2;
    end
end

if nargout > 1
    deriv2 = 0;
    for i = 1:n
        if c(i) ~= 0 % when c(i) = 0, the increment will be 0.
            deriv2 = deriv2 + 2*a(i)*exp(-((x-b(i))/c(i)).^2).*...
                (2*(x-b(i)).^2/c(i)^2-1)/c(i)^2;
        end
    end
end
end  % gaussnder

%---------------------------------------------------------
function int = gaussnint(varargin)
% GAUSSNINT integral function for GAUSSN library function.
% INT = GAUSSNINT(...,N,X) returns the integral function with
% respect to x at the points X.

if nargin < 4 || rem(nargin,3) ~= 2
  error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end

n = varargin{end-1};
a = [varargin{1:3:end-2}];
b = [varargin{2:3:end-2}];
c = [varargin{3:3:end-2}];
x = varargin{end};

int = 0;
for i = 1:n
    if c(i) ~= 0
        int = int + a(i)*c(i)*0.5*erf((x-b(i))/c(i));
    end
end
int = int*sqrt(pi);
end  % gaussnint

%---------------------------------------------------------
function start  = gaussnstart(x,y,n)
% GAUSSNSTART start point for GAUSSN library function.
% START = GAUSSNSTART(X,Y,N) computes a start point START based on X.
% START is a column vector, e.g. [p1, p2, ... pn+1,q1,...,qm];

% The main idea in this computation is to compute one peak at a
% time. Assuming all data is coming from one gaussian model, find out
% the estimated corresponding coefficients for this gaussian, use them as
% the coefficient for the first peak. Then, subtract this peak
% (evaluated at all x) from y data, repeat the procedure for the second
% peak. When we cannot continue for some reason (such as not enough
% significant data, we break, and assign random numbers for the rest of
% the starting point.

x = x(:); y = y(:);
if any(diff(x)<0) % sort x
    [x,idx] = sort(x);
    y = y(idx);
end
p = []; 
q = []; 
r = [];
while length(p) < n
    k = find(y == max(y),1,'last');
    a = y(k);
    b = x(k);
    id = (y>0)&(y<a);
    if ~any(id)
        break
    end
    c = mean(abs(x(id)-b)./sqrt(log(a./y(id))))/(2*n-length(p));
    % 0<y(id)<a , length(p) < 2n ==> c > 0.
    y = y - a*exp(-((x-b)/c).^2);
    p = [p b]; %#ok<AGROW>
    q = [q a]; %#ok<AGROW>
    r = [r c]; %#ok<AGROW>
end
if length(p) < n
    % Unable to find a full set of starting points.
    
    % The number of values found is
    numFound = length( p );
    % The number of points to append is
    numToAdd = n - numFound;
    
    % Choose centers by equally spacing over the domain of the data
    b = linspace( min( x ), max( x ), numToAdd+2 );
    p((numFound+1):n) = b(2:(end-1)); 
    
    % Choose the heights to be the maximum of the data
    q((numFound+1):n) = max( y );  
    
    % Choose to spreads to be the same as the spacing between the centers.
    r((numFound+1):n) = (b(2)-b(1)); 
end
start = zeros(3*n,1);
start(1:3:3*n) = q;
start(2:3:3*n) = p;
start(3:3:3*n) = r;
end  % gaussnstart

%---------------------------------------------------------
%  sinn
%---------------------------------------------------------
function [f,J,p] = sinn(varargin)
% SINN library function for sum of sines: sum(ai*sin(bi*x+ci))
% F = sinn(A1,B1,C1,...,An,Bn,Cn,n,X) returns function value F at (...,X).
%
% [F,J] = sinn(...,n,X) returns function and Jacobian values, F and
% J, at (...,X)
%
% [F,Jnonlinear] = sinn(b1,c1,...,bn,cn,Y,wts,'separable',n,X) is used with separable
% least squares to compute F and "reduced" J (J with respect
% to only the nonlinear coefficients).
%
% [F,J,p] = sinn(b1,c1,...,bn,cn,Y,wts,'separable',n,X) is the syntax when optimizing using
% separable least squares to get all the coefficients p, linear and nonlinear,
% as well as F and the "full" Jacobian J with respect to all the coefficients.

% Note: the problem constant "n" is added by fittype/feval and is not
% passed in directly when calling SINN via feval.

separable = isequal(varargin{end-2},'separable');
if separable
    extra = 5;  % extra is y, wts,'separable', n, x
    y = varargin{end-4};
    wts = varargin{end-3};
    coeffcnt = 2; % bi, ci
else
    extra = 2; % extra is n, x
    coeffcnt = 3; % ai, bi, ci
end
n = varargin{end-1};
if n < 1 || n > 9
  error(message('curvefit:fittype:sethandles:libFunctionNotFound'));
end
count = (nargin-extra)/coeffcnt; % subtract n, x
if nargin < extra + coeffcnt || count ~= n
  error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end
x = varargin{end};
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
if separable
    b = [varargin{1:2:end-extra}];
    c = [varargin{2:2:end-extra}];
    sqrtwts = sqrt(wts);
    A = zeros(length(x),n);
    for i=1:n
        A(:,i) = sin(b(i)*x+c(i));
    end
    D = repmat(sqrtwts,1,size(A,2));
    ws = warning('off', 'all');
    lincoeffs = (D.*A)\(sqrtwts.*y);
    warning(ws);
    a = lincoeffs';
else
    a = [varargin{1:3:end-extra}];
    b = [varargin{2:3:end-extra}];
    c = [varargin{3:3:end-extra}];
end

f = 0;
for i=1:n
    f = f + a(i)*sin(b(i)*x+c(i));
end

if nargout > 1
    if isequal(nargout,3) % only nonlinear coeff coming in, but want full J
        Jcoeffcnt = coeffcnt + 1;
    else % J wrt number of coefficients coming in
        Jcoeffcnt = coeffcnt;
    end
    J = zeros(length(x),Jcoeffcnt*n);
    for i = 1:n
        xi = b(i)*x+c(i);
        start = i*Jcoeffcnt - Jcoeffcnt + 1;
        if separable && isequal(nargout,2) % reduced J
            J(:,start:start+Jcoeffcnt-1) = [a(i)*x.*cos(xi) a(i)*cos(xi)];
        else % ~separable or (separable and nargout > 2)
            J(:,start:start+Jcoeffcnt-1) = [sin(xi) a(i)*x.*cos(xi) a(i)*cos(xi)];
        end
    end
    if nargout > 2
        p = reshape([a; b; c],3*n,1);
    end
end
end  % sinn

%---------------------------------------------------------
function [deriv1,deriv2]  = sinnder(varargin)
% SINNDER derivative function for SINN library function.
% DERIV1 = SINNDER(A1,B1,C1,...,N,X) returns the derivative DERIV1 with
% respect to x at the points A1,B1,C1,...,X.
%
% [DERIV1,DERIV2] = SINNDER(A1,B1,C1,...N,,X) also returns the second
% derivative DERIV2.

if nargin < 4 || rem(nargin,3) ~= 2
  error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end

n = varargin{end-1};
a = [varargin{1:3:end-2}];
b = [varargin{2:3:end-2}];
c = [varargin{3:3:end-2}];
x = varargin{end};

deriv1 = 0;
for i = 1:n
    deriv1 = deriv1 + a(i)*b(i)*cos(b(i)*x+c(i));
end

if nargout > 1
    deriv2 = 0;
    for i = 1:n
        deriv2 = deriv2 - a(i)*b(i)*b(i)*sin(b(i)*x+c(i));
    end
end
end  % sinnder

%---------------------------------------------------------
function int = sinnint(varargin)
% SINNINT integral function for SINN library function.
% INT = SINNINT(...,N,X) returns the integral function with
% respect to x at the points X.

if nargin < 4 || rem(nargin,3) ~= 2
  error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end

n = varargin{end-1};
a = [varargin{1:3:end-2}];
b = [varargin{2:3:end-2}];
c = [varargin{3:3:end-2}];
x = varargin{end};

int = 0;
for i = 1:n
    if b(i) ~= 0
        int = int - a(i)*cos(b(i)*x+c(i))/b(i);
    end
end
end  % sinnint

%---------------------------------------------------------
%  SINNSTART
%---------------------------------------------------------
function start = sinnstart(x,y,n)

% SINNSTART start point for SINN library function.
% START = SINNSTART(X,Y,N) computes a start point START based on X.
% START is a column vector, e.g. [p1, p2, ... pn+1,q1,...,qm];
 
% By running the y data through a Fast Fourier transform and then locating
% peak(s) in results, we can find the starting value fo the frequency
% variable 'b'. Because a phase-shifed sine function is separable and can
% be converted to a sum of sine and cosine functions, starting values for
% amplitude 'a' and phase shift 'c' can also be found.

% Get x and y values on a lattice, so we can use fft to find a frequency
[x,y] = getxygrid(x,y);

% Data size too small, cannot find starting values
if length(x) < 2
    start = rand(3*n,1);
    return;
end

% Loop for sum of sines functions
start = zeros(3*n,1);
oldpeaks = [];
lengthx = length(x);
freqs = zeros(n,1);
res = y;   % residuals from fit so far
for j=1:n
    % Apply fast fourier transform to the current residuals
    fy = fft(res);     % don't subtract mean, no constant term
    fy(oldpeaks) = 0;  % omit frequencies already used

    % Get starting value for frequency using fft peak
    [~,maxloc] = max(fy(1:floor(lengthx/2)));
    oldpeaks(end+1) = maxloc; %#ok<AGROW>
    w = 2*pi*(max(0.5,maxloc-1))/(x(end)-x(1));
    freqs(j) = w;
 
    % Compute Fourier terms using all frequencies we have so far
    X = zeros(lengthx,2*j);
    for k=1:j
        X(:,2*k-1) = sin(freqs(k)*x);
        X(:,2*k)   = cos(freqs(k)*x);
    end
    
    % Fit these terms to get the non-frequency starting values
    ab = X \ y(:);
    
    if j<n
        res = y - X*ab;    % remove these components to get next frequency
    end
end

% All frequencies found, now compute starting values from all frequencies
% and the corresponding coefficients
for k=1:n
    start(3*k-2) = sqrt(ab(2*k-1)^2 + ab(2*k)^2);
    start(3*k-1) = freqs(k);
    start(3*k)   = atan2(ab(2*k),ab(2*k-1));
end
end  % sinnstart

%---------------------------------------------------------
%  RATN
%---------------------------------------------------------
function [f,J,allcoeffs] = ratn(varargin)
% RATN library function for
%     (P1*X^N + P2*X^(N-1) + ... + PN+1)/(X^M + Q1*X^(M-1) + ... + QM).
% F = RATN(P1,P2,...,PN+1,Q1,Q2,...,QM,N,M,X) returns function value F
% at P1,P2,...,PN+1,Q1,Q2,...,QM,X. N describe the order of the numerator.
%
% [F,J] = RATN(P1,P2,...,PN+1,Q1,Q2,...,QM,N,M,X) returns function and
% Jacobian values, F and J, at P1,P2,...,PN+1,Q1,Q2,...,QM+1,X,N,M.
%

% [F,Jnonlinear] = ratn(Q1,Q2,...,QM,Y,wts,'separable',N,M,X) is used with
% separable least squares to compute F and "reduced" J (J with respect to only
% the nonlinear coefficients).
%
% [F,J,p] = ratn(Q1,Q2,...,QM,Y,wts,'separable',N,M,X) is the syntax when
% optimizing using separable least squares to get all the coefficients p, linear
% and nonlinear, as well as F and the "full" Jacobian J with respect to all the
% coefficients.

% Note: we force the first coefficient of the denominator to
% be 1, otherwise, it will be an under-determined system. It also forces
% the denominator to be at least first degree (can't be a constant).

separable = isequal(varargin{end-3},'separable');
x = varargin{end};
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
lenx = length(x);
n = varargin{end-2};
m = varargin{end-1};
if separable
    extra = 6; % extra is y, wts, 'separable', n, m, x
else
    extra = 3; % extra is n, m, x
end
if separable
    if ( nargin ~= (m  + extra) )
        error(message('curvefit:fittype:sethandles:wrongNumArgs'));
    end
elseif nargin ~= (m + (n+1) + extra)
    error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end

if separable
    wts = varargin{end-4};
    y = varargin{end-5};
    q = [1 varargin{1:m}];
    fq = polyval( q, x );
    % compute linear coefficients
    A = zeros(lenx,n+1);
    for i=1:n+1
        A = [zeros(lenx,n) 1./fq];
        % Horner's rule
        for j = n : -1 : 1
            A(:,j) = x .* A(:,j+1);
        end
    end
    sqrtwts = sqrt(wts);
    D = repmat(sqrtwts,1,size(A,2));
    ws = warning('off', 'all');
    lincoeffs = (D.*A)\(sqrtwts.*y);
    warning(ws);
    p = lincoeffs';
else
    p = [varargin{1:n+1}];
    q = [1 varargin{n+2:n+1+m}];
end

ws = warning('off', 'all');
[lw,lwid] = lastwarn;
try
    fp = polyval( p, x );
    fq = polyval( q, x );
    f = fp./fq;

    if nargout > 1
        fdivfq = f./fq;
        if separable && isequal(nargout,2) % reduced J: only wrt q's
            J = [zeros(lenx,m-1) -fdivfq];
            for i = m-1 : -1 : 1
                J(:,i) = x .* J(:,i+1);
            end
        else % ~separable or (separable and nargout > 2)
            J1 = [zeros(lenx,n) 1./fq]; % J wrt p's
            % Horner's rule
            for i = n : -1 : 1
                J1(:,i) = x .* J1(:,i+1);
            end
            J2 = [zeros(lenx,m-1) -fdivfq]; % J wrt q's
            for i = m-1 : -1 : 1
                J2(:,i) = x .* J2(:,i+1);
            end
            J = [J1 J2];

            if nargout > 2
                qshort = q(2:end);
                allcoeffs = [p(:); qshort(:)]; % Leave off q(1) since it is fixed
            end
        end
    end

catch e
    warning(ws);
    rethrow( e );
end
lastwarn(lw,lwid);
warning(ws);
end  % ratn

%---------------------------------------------------------
function [deriv1,deriv2] = ratnder(varargin)
% RATNDER derivative function for RATN library function.
% DERIV1 = RATNDER(P1,P2,...PN+1,Q1,Q2,...,QM,N,M,X) returns the
% derivative DERIV1 with respect to X at the points X for the rational
% function. DERIV1 is a vector the same length as X.
%
% [DERIV1,DERIV2] = RATNDER(P1,P2,...PN+1,Q1,Q2,...,QM,N,M,X) also
% returns the second derivative DERIV2, also a vector the length of X.

if (nargin < 5)
    error(message('curvefit:fittype:sethandles:tooFewImports'));
end
n = varargin{end-2};
m = varargin{end-1};
if nargin ~= m+n+4
    error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end
p = [varargin{1:n+1}];
q = [1 varargin{n+2:n+1+m}];
x = varargin{end};
[~,nx] = size(x);
if (nx ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
fn = polyval( p, x );
fm = polyval( q, x );
ws = warning('off', 'all');
[lw,lwid] = lastwarn;
try
    p = p(1:end-1).*(n:-1:1);
    q = q(1:end-1).*(m:-1:1);
    pp = polyval( p, x );
    qp = polyval( q, x );
    deriv1 = pp./fm-fn.*qp./fm.^2;
    if nargout > 1
        p = p(1:end-1).*((n-1):-1:1);
        q = q(1:end-1).*((m-1):-1:1);
        deriv2 = polyval( p, x )./fm-polyval( q, x ).*fn./fm.^2 - ...
            2*deriv1.*qp./fm;
    end
catch e
    warning(ws);
    rethrow( e );
end
lastwarn(lw,lwid);
warning(ws);
end  % ratnder

%----------------------------------------------------------------------
function int = ratnint(varargin)
% RATNINT integral function for RATN library function.
% INT = RATNINT(P1,P2,...PN+1,Q1,Q2,...,QM,N,M,X) returns the integral INT
% with respect to X at the points X for the corresponding rational
% function. INT is a vector the same length as X.

% Generally speaking, there's no closed form for the integral of a
% rational form if the denominator is of order 3 or higher. However, for
% linear and quadratic denominator, we can work out a closed form. We
% only get in here if m < 3;

if (nargin < 5)
    error(message('curvefit:fittype:sethandles:tooFewImports'));
end
n = varargin{end-2};
m = varargin{end-1};
if nargin ~= m+n+4
  error(message('curvefit:fittype:sethandles:wrongNumArgs'));
end
p = [varargin{1:n+1}];
q = [varargin{n+2:n+1+m}];
x = varargin{end};
[~,nx] = size(x);
if (nx ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end

ws = warning('off', 'all');
[lw,lwid] = lastwarn;
try
    int = 0;
    if m == 1 % linear case
        % do long division first
        if n > 0
            for i = 2:n+1
                p(i) = p(i)-p(i-1)*q(1);
            end
            p(1:n) = p(1:n)./(n:-1:1);
            int = int + polyval( [p(1:n) 0], x );
        end
        int = int + p(n+1)*log(abs(x+q(1))).*double(x>=-q(1));
    elseif m == 2 % quadratic
        if n > 0
            if n > 1
                for i = 2:n
                    p(i) = p(i)-p(i-1)*q(1);
                    p(i+1) = p(i+1)-p(i-1)*q(2);
                end
                p(1:n-1) = p(1:n-1)./(n-1:-1:1);
                int = int + polyval( [p(1:n-1) 0], x );
            end
            if n > 0
                int = int + log(x.^2+q(1)*x+q(2))*p(n)/2;
                p(n+1) = p(n+1) - p(n)*q(1)/2;
            end
        end
        q(1)=q(1)/2;
        r = q(1)^2-q(2);
        if r == 0 % multiple root
            int = int - 1./(x+q(1));
        elseif r > 0  % two real solutions
            r = sqrt(r);
            r1 = -q(1)+r;
            r2 = -q(1)-r;
            int = int + log((x-r1)./(x-r2))*p(n+1)/(2*r);
        else % no singular point
            r = sqrt(-r);
            int = int + p(n+1)*atan((x+q(1))/r)/r;
        end
    else
        error(message('curvefit:fittype:sethandles:noClosedFormIntegral'));
    end
catch e 
    warning(ws);
    rethrow( e );
end
lastwarn(lw,lwid);
warning(ws);
end  % ratnint

%---------------------------------------------------------
%  PP (splines and interpolants)
%---------------------------------------------------------
% ppval is in toolbox/matlab/polyfun
%---------------------------------------------------------
function [deriv1,deriv2]  = ppder(p,x)
% PPDER derivative function for ppform functions.
% DERIV1 = PPDER(P,X) returns the derivative DERIV1 with
% respect to x at the points X of the ppform P.
%
% [DERIV1,DERIV2] = PPDER(P,X) also returns the second
% derivative DERIV2.

coefs = p.coefs;
p.order = p.order-1;
m = p.pieces;
% this will only work for single column y's.
coefs = coefs(:,1:end-1).*repmat(p.order:-1:1,m,1);
if (size(x,2) ~= 1)
    error(message('curvefit:fittype:sethandles:LastXMustBeColVector'));
end
if size(coefs,2) == 0
    deriv1 = zeros(size(x));
    deriv2 = zeros(size(x));
    return;
end
p.coefs = coefs;
deriv1 = ppval(p,x);
if nargout > 1
    if p.order > 1
        p.order = p.order-1;
        p.coefs = coefs(:,1:end-1).*repmat(p.order:-1:1, m,1);
        deriv2 = ppval(p,x);
    else
        deriv2 = zeros(size(x));
    end
end
end  % ppder

%---------------------------------------------------------
function int = ppint(p,x)
% PPINT integral function for ppform functions.
% INT = PPINT(P,X) returns the integral with
% respect to x at the points X of the ppform P.

coefs = p.coefs; breaks = p.breaks; m = p.pieces;
% this will only work for single column y's.
p.coefs = [coefs ./repmat(p.order:-1:1, m,1) zeros(m,1)];
p.order = p.order+1;

% This next line can be made more accurate but will be less efficient
breps = max(eps(breaks(1)),eps(breaks(end)));
yt = cumsum(ppval(p,breaks(2:end-1)-breps));
p.coefs(:,end) = [0 yt];
int = ppval(p,x);
end  % ppint

%---------------------------------------------------------
%  Lowess Smoothing Fit
%---------------------------------------------------------
function f = iLowess( pp, x, y )

f = evaluate( pp, [x(:), y(:)] );
f = reshape( f, size( x ) );
end  % iLowess

%---------------------------------------------------------
%  Utility Functions
%---------------------------------------------------------
function [x,y] = getxygrid(x,y)
% Determining the range of x values.
lengthx = length(x);

% Checking number of data points to be > 2
if lengthx < 2
    iTwoDataPointsRequiredError();
end

% Sorting data points to be in order of increasing x.
diffx = diff(x);
if any(diffx < 0)
    [x,idx] = sort(x);
    y = y(idx);
    diffx = diff(x);
end

% To avoid dividing by zero, we will get rid of repeated x entries.
tol = eps^0.7;
idx = [(diffx < tol); false];
idx2 = [false ; idx(1:end-1)];
x(idx) = (x(idx) + x(idx2)) / 2;
x(idx2) = [];
y(idx) = (y(idx) + y(idx2)) / 2;
y(idx2) = [];
lengthx = length(x);

% Data size too small, cannot find fit
if lengthx > 2
    % Checking to see whether the set of data points [x, y] are equally spaced

    % If idx has contains non-zero elements, then data points are scattered
    % Applying interpolation on the data points
    % if (sum(idx) > 0.0001)
    if all(abs(diffx-diffx(1)) < tol*max(diffx))
        % [newx, newy] = interpolate1(x, y);
        newx = linspace(min(x), max(x), numel(x));
        newy = interp1(x, y, newx);
        x = newx(:);
        y = newy(:);
    end
end
end  % getxygrid

%---------------------------------------------------------
function iTwoDataPointsRequiredError()
error(message('curvefit:fittype:sethandles:twoDataPointsRequired'));
end  % iTwoDataPointsRequiredError

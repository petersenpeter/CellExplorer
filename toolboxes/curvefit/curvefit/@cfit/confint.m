function ci = confint(fun,level)
%CONFINT  Confidence intervals for the coefficients of a fit result object.
%   CI = CONFINT(FITRESULT) returns 95% confidence intervals for the
%   coefficient estimates.
%
%   CI = CONFINT(FITRESULT,LEVEL) specifies the confidence level.
%   LEVEL must be between 0 and 1, and has a default value of 0.95.

%   Copyright 2001-2008 The MathWorks, Inc.

% Covariance matrix of fitted parameters is
%    V = inv(X'*X) * (sse/dfe)
% and the confidence intervals are
%    b +/- sqrt(diag(V)) * tinv(1-(1-level)/2, dfe)

ftype = category(fun);
if strcmpi(ftype,'spline') || strcmpi(ftype,'interpolant')
   error(message('curvefit:confint:cannotComputeConfInt', ftype));
end
activebounds = fun.activebounds;
if isempty(fun.sse) || isempty(fun.dfe) || ...
   (isempty(fun.rinv) && ~all(activebounds))
   error(message('curvefit:confint:missingInfo'));
end

if nargin<2, level = 0.95; end
if length(level)~=1 || ~isnumeric(level) || level<=0 || level>=1
   error(message('curvefit:confint:invalidConfLevel'));
end

sse = fun.sse;
dfe = fun.dfe;
Rinv = fun.rinv;

if dfe<=0
   error(message('curvefit:confint:needMoreObservations'));
end

% X=Q*R, so X'*X = R'*Q'*Q*R = R'*R.
% The inverse is Rinv*Rinv' and the diagonals of that can be
% computed using the sum expression on the following line.
v = sum(Rinv.^2,2) * (sse / dfe);
b = cat(1,fun.coeffValues{:})';
alpha = (1-level)/2;
t = -cftinv(alpha,dfe);
db = NaN*zeros(1,length(activebounds));
db(~activebounds) = t * sqrt(v');
ci = [b-db; b+db];

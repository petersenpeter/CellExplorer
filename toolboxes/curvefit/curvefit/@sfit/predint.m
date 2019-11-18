function [ci, ypred] = predint( obj, xyi, varargin )
%PREDINT  Prediction intervals for a fit result object or new observations.
%
%   CI = PREDINT(FITRESULT,[X,Y],LEVEL) returns prediction intervals for new Z
%   values at the specified X, Y values.  LEVEL is the confidence level and has
%   a default value of 0.95.
%
%   CI = PREDINT(FITRESULT,[X,Y],LEVEL,'INTOPT','SIMOPT') specifies the type of
%   interval to compute.  'INTOPT' can be either 'observation' (the default) to
%   compute bounds for a new observation, or 'functional' to compute bounds for
%   the surface evaluated at X, Y. 'SIMOPT' can be 'on' to compute simultaneous
%   confidence bounds or 'off' to compute non-simultaneous bounds.
%
%   If 'INTOPT' is 'functional', the bounds measure the uncertainty in
%   estimating the curve.  If 'INTOPT' is 'observation', the bounds are wider to
%   represent the addition uncertainty in predicting a new Z value (the curve
%   plus random noise).
%
%   Suppose the confidence level is 95% and 'INTOPT' is 'functional'. If
%   'SIMOPT' is 'off' (the default), then given a single pre-determined X, Y
%   value you have 95% confidence that the true surface lies between the
%   confidence bounds.  If 'SIMOPT' is 'on', then you have 95% confidence that
%   the entire surface (at all X, Y values) lies between the bounds.
%
%   [CI, YI] = PREDINT( ... ) also returns predictions YI.
%
%   See also: SFIT, SFIT/FEVAL.

%   The Level, Interval and Simultaneous options can also be passed in as
%   part of a PredictionIntervalOptions object, e.g.,
%
%     OPTS = curvefit.PredictionIntervalOptions( 'Level', LEVEL, 'Simultaneous', SIMOPT )
%     CI = PREDINT( SF, OPTS )

%   Copyright 2001-2011 The MathWorks, Inc.

% Check validity of Fit Object
ftype = category( obj );
if strcmpi( ftype, 'spline' ) || strcmpi( ftype, 'interpolant' ) || strcmpi( ftype, 'lowess' )
    error(message('curvefit:predint:cannotComputePredInts', ftype));
end
if isempty( obj.sse ) || isempty( obj.dfe ) || isempty( obj.rinv )
    error(message('curvefit:predint:missingInfo'));
end

% Check size of eval points
if size( xyi, 2 ) ~= 2
    error(message('curvefit:sfit:predint:XWrongSize'));
end
if isempty( xyi )
    ypred = zeros( 0, 1 );
    ci = zeros( 0, 2 );
    return
end
xi = xyi(:,1);
yi = xyi(:,2);

% Parse options
if nargin == 3 && isa( varargin{1}, 'curvefit.PredictionIntervalOptions' );
    opts = varargin{1};
else
    opts = curvefit.PredictionIntervalOptions;
    if nargin >= 3
        opts.Level = varargin{1};
    end
    if nargin >= 4
        opts.Interval = varargin{2};
    end
    if nargin >= 5
        opts.Simultaneous = varargin{3};
    end
end
level  = opts.Level;
intopt = opts.Interval;
simopt = opts.Simultaneous;



%
% Compute stuff
%
sse = obj.sse;
dfe = obj.dfe;
Rinv = obj.rinv;
activebounds = obj.activebounds;

if dfe==0
   error(message('curvefit:predint:cannotComputeConfInts'));
end

% Get the predicted value, and if possible compute the derivative
% w.r.t. parameters at the current parameter values and at x
jac = [];
ypred = [];
if isequal( category(obj), 'library' )
    try
        [ypred, jac] = feval( obj, xi, yi );
    catch ignore %#ok<NASGU>
    end
end
if isempty(ypred)
    ypred = feval( obj, xi, yi );
end

% Compute the Jacobian numerically if necessary
beta = cat( 1, obj.fCoeffValues{:} )';
p = length(beta);
if isempty(jac)
    fun2 = obj;
    jac = zeros(length(xi),p);
    seps = sqrt(eps);
    for i = 1:p
        bi = beta(i);
        if (bi == 0)
            nb = sqrt(norm(beta));
            change = seps * (nb + (nb==0));
        else
            change = seps * bi;
        end
        fun2.fCoeffValues{i} = bi + change;
        predplus = feval(fun2, xi, yi);
        fun2.fCoeffValues{i} = bi - change;
        predminus = feval(fun2, xi, yi);
        jac(:,i) = (predplus - predminus)/(2*change);
        fun2.fCoeffValues{i} = bi;
    end
end

jac = jac(:,~activebounds);
E = jac*Rinv;
    
switch intopt
    case curvefit.PredictionIntervalOptions.OBSERVATION 
        delta = sqrt(1 + sum(E.*E,2));
        
    case curvefit.PredictionIntervalOptions.FUNCTIONAL
        delta = sqrt(sum(E.*E,2));
        
    otherwise
        error(message('curvefit:predint:InvalidIntervalOption', curvefit.PredictionIntervalOptions.OBSERVATION, curvefit.PredictionIntervalOptions.FUNCTIONAL));
end

rmse = sqrt(sse/dfe);

% Calculate confidence interval
if isequal(simopt,'on')
    crit = sqrt(p * cffinv(level, p, dfe));
else
    crit = -cftinv((1-level)/2,dfe);
end

delta = delta .* rmse * crit;
ci = [ypred-delta ypred+delta];

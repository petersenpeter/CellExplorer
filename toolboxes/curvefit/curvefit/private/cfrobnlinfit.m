function [p,resnorm,res,exitflag,optoutput,activebounds,jacob,convmsg] = ...
    cfrobnlinfit(model,p0,xdata,wtdy,lowerbnd,upperbnd,...
    options,probparams,separargs,wts,resin,jacob,robtype,...
    lsiter,lsfunevals)
%CFROBNLINFIT Do robust nonlinear fitting for curve fitting toolbox.
%
%   RESIN is a vector of residuals from the non-robust fit.  JACOB is
%   the Jacobian for that fit.  LSITER and LSFUNEVALS are the number of
%   iterations and the number of function evaluations used in the initial
%   least squares fit.  See cflsqcurvefit for a description of the
%   other arguments.

%   Copyright 2001-2014 The MathWorks, Inc.

iteroutput = isequal(lower(options.Display),'iter');

p = p0(:);
P = numcoeffs(model);
N = length(wtdy);

% Need the real Jacobian if things are separable
if ~isempty(separargs)
    separargs{2} = wts;
    [~,jacob,pfull] = ...
        feval(model,p,xdata,probparams{:},separargs{:},wts,'optimweight');
end

% The Jacobian should be full, but if it is sparse it will slow down the QR
% factorization
jacob = full( jacob );

% Adjust residuals using leverage, as advised by DuMouchel & O'Brien
[Q, ~] = qr( jacob, 0 ); % Two output form of QR
h = min(.9999, sum(Q.*Q,2));
adjfactor = 1 ./ sqrt(1-h);

dfe = N-P;
ols_s = norm(resin) / sqrt(dfe);

% If we get a perfect or near perfect fit, the whole idea of finding
% outliers by comparing them to the residual standard deviation becomes
% difficult.  We'll deal with that by never allowing our estimate of the
% standard deviation of the error term to get below a value that is a small
% fraction of the standard deviation of the raw response values.
tiny_s = 1e-6 * std(wtdy) / sum(wts);
if tiny_s==0
    tiny_s = 1;
end

% Perform iteratively re-weighted least squares to get coefficient estimates
D = 1e-6;
robiter = 0;

% Account for iterations and function evaluations already used
origMaxIter = options.MaxIter;
origMaxFunEvals = options.MaxFunEvals;
iterlim = options.MaxIter - lsiter;
maxfunevals = options.MaxFunEvals - lsfunevals;
totaliter = lsiter;
totalfunevals = lsfunevals;

res = resin;
% This is the main computational loop. It has to be executed at least once
% for each call into this function so it is implemented as a DO-WHILE loop,
% i.e., the exit condition is at the end.
while true
    robiter = robiter + 1;
    
    % After 1st iteration for lar, don't use adjusted residuals
    if (robiter > 1) && isequal( robtype, 'lar' )
        adjfactor = 1;
    end
    
    if iteroutput
        robustFittingHeader = getString(message('curvefit:curvefit:RobustFittingHeader', robiter));
        fprintf( '\n%s\n---------------------------', robustFittingHeader );
    end
    
    % Compute residuals from previous fit, then compute scale estimate
    radj = res .* adjfactor;
    rs = sort(abs(radj));
    sigma = median(rs(P:end)) / 0.6745;
    
    % Compute new weights from these residuals, then re-fit
    tune = 4.685;
    bw = cfrobwts(robtype,radj/(max(tiny_s,sigma)*tune));
    p0 = p;
    if ~isempty(separargs)
        separargs{2} = wts.*bw;
    end
    options.MaxIter = max( 0, iterlim );
    options.MaxFunEvals = max( 0, maxfunevals );
    [p,resnorm,~,exitflag,optoutput,~,convmsg] = ...
        cflsqcurvefit(model,p0,xdata,wtdy.*sqrt(bw),...
        lowerbnd,upperbnd,...
        options,probparams{:},separargs{:},wts.*bw,'optimweight');
    
    % Reduce the iteration limit by the number of nonlinear fit iterations
    % used for this set of robust weights.  Also keep track of the total
    % number of iterations, as we would like to report that total.
    iterlim = iterlim - optoutput.iterations;
    maxfunevals = maxfunevals - optoutput.funcCount;
    totaliter = totaliter + optoutput.iterations;
    totalfunevals = totalfunevals + optoutput.funcCount;
    
    if ~isempty(separargs)
        [~,~,pfull] = ...
            feval(model,p,xdata,probparams{:},separargs{:},wts.*bw,'optimweight');
    else
        pfull = p;
    end
    activebounds = isActiveBounds(p,lowerbnd,upperbnd);
    res = wtdy - feval(model,pfull,xdata,probparams{:},wts,'optimweight');
    
    % Check WHILE loop exit conditions
    if cfInterrupt( 'get' )
        % Fitting stopped by user.
        exitflag = -1;
        break
    elseif (exitflag == 0) || (iterlim <= 0) || (maxfunevals <= 0)
        % Number of iterations or function evaluations exceeded
        %
        % Set Exit Flag to zero as the limit on number of iterations or
        % function evaluations may have been exceeded without the flag
        % already been set to zero.
        exitflag = 0;
        break
    elseif all( abs( p-p0 ) <= D*max( abs( p ), abs( p0 ) ) )
        % Convergence
        break
    end
end

optoutput.iterations = totaliter;
optoutput.funcCount = totalfunevals;

% Restore original values (this is a handle object so it may affect others)
options.MaxIter = origMaxIter;
options.MaxFunEvals = origMaxFunEvals;

% To compute the res, jacob include the weights but not robust weights.
% Resnorm is computed special below.

% Note separargs is omitted in the following two feval calls; we can't
% treat the model as separable if we are omitting the robust weights,
% because solving the linear part of the model requires them.
p = pfull;
if isequal(category(model),'library') % library and not separable
    [f,jacob] = feval(model,p,xdata,probparams{:},wts,'optimweight');
else % custom
    % Finite-difference to get Jacobian without robust weights, and recompute res with weights
    f = feval(model,p,xdata,probparams{:},wts,'optimweight');
    jacob = curvefit.numericalJacobian( model, p, xdata, [], [], probparams{:}, wts, 'optimweight' );
end
res = wtdy - f;

if (nargout>1)
    % Compute a robust estimate of s
    if all(bw<D | bw>1-D)
        % All weights 0 or 1, this amounts to ols using a subset of the data
        included = (bw>1-D);
        robust_s = norm(res(included)) / sqrt(sum(included) - P);
    else
        % Compute robust mse according to DuMouchel & O'Brien (1989)
        radj = res .* adjfactor;
        robust_s = cfrobsigma(max(tiny_s,sigma),robtype,radj, P, tune, h);
    end
    
    % Shrink robust value toward ols value if appropriate
    sigma = max(robust_s, sqrt((ols_s^2 * P^2 + robust_s^2 * N) / (P^2 + N)));
    resnorm = dfe * sigma^2; % new resnorm based on sigma
end

end

function [fitobj,goodness,output,warnstr,errstr,convmsg] = fit(xdatain,ydatain,fittypeobj,varargin)
%FIT   Fit a curve or surface to data.
%
%   FO = FIT(X, Y, FT) creates a fit object, FO, that encapsulates the
%   result of fitting the model specified by the fittype FT to the data X,
%   Y.
%
%   -- X must be a matrix with either one (curve fitting) or two (surface
%   fitting) columns. For surface fitting, if your data is in separate
%   vectors, then you can use the following syntax:
%
%       fo = fit( [x, y], z, ft )
%
%   -- Y must be a column vector with the same number of rows as X.
%
%   -- FT is a string or a FITTYPE specifying the model to fit.
%
%   If FT is a string, then it may be:
%
%       FITTYPE           DESCRIPTION
%       'poly1'           Linear polynomial curve
%       'poly11'          Linear polynomial surface
%       'poly2'           Quadratic polynomial curve
%       'linearinterp'    Piecewise linear interpolation
%       'cubicinterp'     Piecewise cubic interpolation
%       'smoothingspline' Smoothing spline (curve)
%       'lowess'          Local linear regression (surface)
%
%   or any of the names of library models described in "List of Library Models
%   for Curve and Surface Fitting" in the documentation.
%
%   To fit custom models, create a FITTYPE and use this as the FT argument.
%
%   FO = FIT(X, Y, FT,...,PROP1,VAL1,PROP2,VAL2,...) fits the data X and Y
%   using the problem and algorithm options specified in the property-value
%   pairs PROP1, VAL1, etc, returning the fitted model FO. For FITOPTIONS
%   properties and default values type FITOPTIONS(FT), for example,
%
%      fitoptions( 'cubicinterp' )
%      fitoptions( 'poly1' )
%
%   FO = FIT(X, Y, FT, ..., 'Weight', WEIGHTS) creates a weighted fit using
%   the given WEIGHTS. WEIGHTS must be a vector the same size as Y.
%
%   FO = FIT(X, Y, FT, OPTIONS) creates a fit using the algorithm options
%   specified in the FITOPTIONS object OPTIONS. This is an alternative
%   syntax to specifying the property-value pairs. For help on constructing
%   OPTIONS, see FITOPTIONS.
%
%   FO = FIT(X, Y, FT, ..., 'problem', VALUES) assigns VALUES to the problem
%   dependent constants. VALUES is a cell array with one element per problem
%   dependent constant. See FITTYPE for more information on problem dependent
%   constants.
%
%   [FO, G] = FIT(X, Y, ...) returns appropriate goodness-of-fit measures, for
%   the given inputs, in the structure G. G includes the fields:
%       -- SSE         sum of squares due to error
%       -- R2          coefficient of determination or R^2
%       -- adjustedR2  degree of freedom adjusted R^2
%       -- stdError    fit standard error or root mean square error
%
%   [FO, G, O] = FIT(X, Y, ...) returns a structure, O, with output values
%   appropriate for the given inputs. For example, for nonlinear fitting, O
%   contains the number of iterations, number of model evaluations, an
%   exitflag denoting convergence, the residuals, and the Jacobian.
%
%   Examples:
%
%   To fit a cubic interpolating spline through x and y:
%
%      [curve, goodness] = fit( x, y, 'pchipinterp' );
%
%   To fit a polynomial surface of degree 2 in x and degree 3 in y using
%   the least absolute residual robust (LAR) method:
%
%      sf = fit( [x, y], z, 'poly23', 'Robust', 'LAR' );
%
%   To fit the 1st equation in the curve fitting library of exponential
%   models (a single-term exponential), overriding the starting point to be
%   p0:
%
%      curve = fit( x, y, 'exp1', 'StartPoint', p0 );
%
%   Remarks on starting points:
%
%   For rational and Weibull models, and all custom nonlinear models, the
%   toolbox selects default initial values for coefficients uniformly at
%   random from the interval (0,1). As a result, multiple fits using the
%   same data and model may lead to different fitted coefficients. To avoid
%   this, specify initial values for coefficients with FITOPTIONS or a
%   vector value for the StartPoint property.
%
%   See also FITTYPE, FITOPTIONS, CFIT, SFIT.

%   Copyright 1999-2014 The MathWorks, Inc.

% Choice of error functions depends on whether an error string (5th output) is
% asked for.
errorFcn = iCreateErrorFunction( nargout > 4 );
% Choice of warning functions depends on whether a warning string (4th output) is
% asked for.
warningFcn = iCreateWarningFunction( nargout > 3 );

% Parse optional arguments
[useroptions, useroptargs, probparams] = iParseOptionalArgs( varargin{:} );

% Call FIT with pre-processed inputs and restricted set of outputs
[fitobj, goodness, output, convmsg] = iFit( xdatain, ydatain, fittypeobj, ...
    useroptions, useroptargs, probparams, errorFcn, warningFcn );

% Get any warning or error messages as strings
warnstr = warningFcn.String;
errstr = errorFcn.String;
end

function [fitobj,goodness,output, convmsg] = iFit( xdatain, ydatain, fittypeobj, ...
    useroptions, useroptargs, probparams, errorFcn, warningFcn )
% iFit   Fit a curve or surface to data
%   See also: FIT
fitobj = cfit;
goodness = [];
output = [];
convmsg = '';

% column vectors are assumed throughout rest of code.
if size(xdatain,2) ~= 1 && size(xdatain,2) ~= 2
    errorFcn.throw( message( 'curvefit:fit:xDataMustBeColumnVector' ) );
    return;
end
if size(ydatain,2) ~= 1
    errorFcn.throw( message( 'curvefit:fit:yDataMustBeColumnVector' ) );
    return;
end
if size( xdatain, 1 ) ~= size( ydatain, 1 )
    errorFcn.throw( message( 'curvefit:fit:yxMustBeSameLength' ) );
    return;
end

% The fitting code is going to assume that the inputs are double and full (not
% sparse) -- only warn if not-double. Silent conversion of sparse to full.
if ~isa( xdatain, 'double' )
    warningFcn.throw( message( 'curvefit:fit:nonDoubleXData' ) );
end
if ~isa( ydatain, 'double' )
    warningFcn.throw( message( 'curvefit:fit:nonDoubleYData' ) );
end
xdatain = double( full( xdatain ) );
ydatain = double( full( ydatain ) );

% If fittypeobj is-a fittype,
if isa( fittypeobj, 'fittype' )
    % ... then make it an instance of fittype
    model = fittype( fittypeobj );
else
    % convert it to a fittype with the correct number of independent
    % variables
    model = fittype( fittypeobj, 'numindep', size( xdatain, 2 ) );
end
% Check that we don't have an empty fittype as we can't fit one of those
if isempty( model )
    errorFcn.throw( message( 'curvefit:fit:EmptyFittype' ) );
    return
end
% Ensure that the number of input arguments specified by the data agrees
% with the number of independent variables in the fittype.
iAssertNumIndepEqualsNumDataColumns( model, xdatain );

ftype = type(model);
fcategory = category(model);
options = iGetFitOptions( model, useroptions, useroptargs, warningFcn );

% Update .fitoptions field in model to be the fitoptions used in the fit.
model = setoptions(model,options);
weightsin = get(options,'weights');
exclude = get(options,'exclude');

% Check to see whether the array is comprised of logical or subscript
% indexes.  If the values are not logicals then convert.
try
    exclude = curvefit.ensureLogical( exclude, length( ydatain ) );
catch exception
    errorFcn.throw( exception )
end

% Check that we have the correct number of values for the problem
% parameters
iAssertNumProblemParameters( probparams, probnames( model ) );

% Ensure that we have a valid set of weights.
if isempty(weightsin)
    weightsin = ones( size( ydatain ) );
elseif any(weightsin < 0)
    errorFcn.throw( message( 'curvefit:fit:weightsMustBePositive' ) );
    return;
else
    weightsin = weightsin(:);
end
if size( ydatain, 1 ) ~= size( weightsin, 1 )
    errorFcn.throw( message( 'curvefit:fit:yDataAndWeightsMustBeSameLength' ) );
    return;
end


if ~isempty(exclude)
    exclude = exclude(:);
    nXDatain = size( xdatain, 1 );
    if length(exclude) < nXDatain
        exclude(end+1:nXDatain) = false;
    elseif length(exclude) > nXDatain
        errorFcn.throw( message( 'curvefit:fit:excludedataLengthTooLong' ) );
        return;
    end
    xdata=xdatain(~exclude,:);
    ydata=ydatain(~exclude);
    weights=weightsin(~exclude);
else
    xdata=xdatain;
    ydata=ydatain;
    weights=weightsin;
end

% After data is excluded, check for NaN, Inf, or complex
if any( isnan( xdata(:) ) ) || any(isnan(ydata)) || any(isnan(weights))
    errorFcn.throw( message( 'curvefit:fit:nansNotAllowed' ) );
    return;
end
if any( isinf( xdata(:) ) ) || any(isinf(ydata)) || any(isinf(weights))
    errorFcn.throw( message( 'curvefit:fit:infsNotAllowed' ) );
    return;
end

if any( ~isreal( xdata(:) ) )
    xdata = real(xdata);
    warningFcn.throw( message( 'curvefit:fit:complexXusingOnlyReal' ) );
end
if any(~isreal(ydata))
    ydata = real(ydata);
    warningFcn.throw( message( 'curvefit:fit:complexYusingOnlyReal' ) );
end
if any(~isreal(weights))
    weights = real(weights);
    warningFcn.throw( message( 'curvefit:fit:complexWeightsUsingOnlyReal' ) );
end


% Check if normalize is on and then center and scale
xlim = [min(xdata) max(xdata)];
if isequal(options.normalize, 'on')
    [xdata, meanx, stdx] = curvefit.normalize(xdata);
else
    meanx = zeros( 1, size( xdata, 2 ) );
    stdx  =  ones( 1, size( xdata, 2 ) );
end

switch fcategory
    case {'custom','library'}
        numcoeff = numcoeffs( model );
        n = length(xdata);
        dfe = n - numcoeff;
        if dfe < 0
            errorFcn.throw( message( 'curvefit:fit:InsufficientData', numcoeff ) );
            return;
        end
        lowerbnd = get(options,'lower');
        upperbnd = get(options,'upper');
        % Make sure bounds are valid and same length as number of coefficients.
        [lowerbnd, upperbnd, anError, aWarning] = checkbounds( lowerbnd, upperbnd, numcoeff );
        if ~isempty(anError)
            errorFcn.throw( anError );
            return;
        end
        warningFcn.throw( aWarning )
        
        switch ftype(1:3)
            case {'wei'}
                if any(xdata <= 0)
                    errorFcn.throw( message( 'curvefit:fit:weibullRequiresPositiveData' ) );
                    return;
                end
            case {'pow'}
                if any(xdata <= 0)
                    errorFcn.throw( message( 'curvefit:fit:powerFcnsRequirePositiveData' ) );
                    return;
                end
            case {'fou'}
                if isequal(std(xdata),0)
                    errorFcn.throw( message( 'curvefit:fit:fourierFcnsIdenticalDataError' ) );
                    return;
                end
        end
        
        if ~islinear(model) % nonlinear custom or library equation
            [start, anError, aWarning] = iCheckStartPoint( options.startpoint, ...
                model, probparams, xdata, ydata );
            if ~isempty( anError )
                errorFcn.throw( anError );
                return
            end
            warningFcn.throw( aWarning );
            
            if all(weights==1)
                wtdydata = ydata;
                optimargs = {'optim'};
            else
                wtdydata = sqrt(weights).*ydata;
                optimargs = {weights,'optimweight'};
            end
            
            separargs = {};
            nonlcoeffindex = nonlinearcoeffs(model);
            if ~isempty(nonlcoeffindex)
                % If any of the linear coefficients of the separable problem are
                % bounded, then treat as if not separable so the bounds on the
                % linear coefficients will be used.
                lincoeffindex = (1:numcoeffs(model))';
                lincoeffindex(nonlcoeffindex) = [];
                if ~any(isfinite([lowerbnd(lincoeffindex); upperbnd(lincoeffindex)]))
                    start = start(nonlcoeffindex);
                    lowerbnd = lowerbnd(nonlcoeffindex);
                    upperbnd = upperbnd(nonlcoeffindex);
                    separargs = {ydata,weights,'separable'};
                    
                    % We don't have the Jacobian with respect to the nonlinear
                    % parameters only, so use a numerical approximation instead
                    set(options,'Jacobian','off');
                end
            end
            
            [model, options] = iCheckAlgorithmAndBounds( model, options, ...
                lowerbnd, upperbnd, warningFcn );
            
            try
                [xout,resnorm,res,exitflag,optoutput,activebounds,convmsg,J] = iNonLinearFit(...
                    model, start,xdata,wtdydata,lowerbnd,upperbnd, options,probparams, ...
                    separargs,weights, optimargs, nonlcoeffindex);
            catch es
                % Note: we can't use the ID from the exception as this comes from LSQNCOMMON;
                % only the error message includes the Inf/NaN/complex strings. Therefore we need
                % to look into the cause.
                errorFcn.throw( iHandleFevalError( es ) );
                return;
            end
            
            coeffcell = num2cell(xout);
            output = iOutputStructure(n,numcoeff,res,J,exitflag,optoutput);
            sse = resnorm;
            dfe = dfe + nnz( activebounds );
            goodness = iGoodnessStructure(ydata,weights,res,dfe,output,sse);
            if size( xdatain, 2 ) == 1
                % construct a curve fit object
                fitobj = cfit(model, coeffcell{:},probparams{:},...
                    'sse',goodness.sse,'dfe',goodness.dfe, ...
                    'Jacobian',J,'activebounds',activebounds,...
                    'meanx',meanx,'stdx',stdx,'xlim',xlim);
            else % size( xdatain, 2 ) == 2
                % construct a surface fit object
                fitobj = sfit(model, coeffcell{:},probparams{:},...
                    'sse',goodness.sse,'dfe',goodness.dfe, ...
                    'Jacobian',J,'activebounds', activebounds(:),...
                    'meanx', meanx(1), 'stdx', stdx(1), 'xlim', xlim([1,3]), ...
                    'meany', meanx(2), 'stdy', stdx(2), 'ylim', xlim([2,4]));
            end
            
        else % linear custom or linear library equation
            xdatacell = num2cell( xdata, 1 );
            
            if isequal(fcategory,'custom')
                A = getcoeffmatrix(model,probparams{:}, xdatacell{:} );
            else
                % Generate some arbitrary coefficients to use. Anything from
                % the interval (0,1) should be all right
                k = numcoeffs( model );
                coefftemp = num2cell( (1:k)/(k+1) );
                % Calculate the Jacobian analytically at the coefficients
                [~, A] = feval(model,coefftemp{:},probparams{:},xdatacell{:});
            end
            
            % Prior weights are done here, robust weights inside cfroblinfit
            sqrtwts = sqrt(weights);
            Awtd = A .* repmat(sqrtwts,1,size(A,2));
            wtdydata = ydata .* sqrtwts;
            [p,s,J,optoutput,convmsg,res,leverage ] = ...
                iLinearFit(Awtd,wtdydata,[],lowerbnd,upperbnd,options,errorFcn, warningFcn);
            exitflag = 1;
            
            robustflag = lower(options.robust);
            dorobust = ~isequal(robustflag,'off');
            if dorobust
                try
                    [p,s,optoutput,convmsg, exitflag] = iRobustLinearFit( ...
                        Awtd,wtdydata,p,s,robustflag,lowerbnd,upperbnd,options,...
                        errorFcn,warningFcn,leverage,res,optoutput);
                catch es
                    errorFcn.throw( es );
                    return;
                end
            end
            
            pcell = num2cell(p);
            res = sqrtwts.*(ydata-feval(model,pcell{:},probparams{:},xdatacell{:}));
            
            output = iOutputStructure(n,numcoeff,res,J,exitflag,optoutput);
            sse = s.normr^2;
            
            activebounds = isActiveBounds(p,lowerbnd,upperbnd);
            dfe = dfe + nnz( activebounds );
            
            goodness = iGoodnessStructure(ydata,weights,res,dfe,output,sse);
            
            if size( xdata, 2 ) == 1
                % Create a curve fit object
                fitobj = cfit(model, pcell{:},probparams{:},...
                    'sse',goodness.sse,'dfe',dfe,...
                    'Jacobian',J,'activebounds',activebounds,...
                    'meanx',meanx,'stdx',stdx,'xlim',xlim);
            else % size( xdata, 2 ) == 2
                % Create a surface fit object
                fitobj = sfit(model, pcell{:},probparams{:},...
                    'sse',goodness.sse,'dfe',goodness.dfe, ...
                    'Jacobian',J,'activebounds', activebounds,...
                    'meanx', meanx(1), 'stdx', stdx(1), 'xlim', xlim([1,3]), ...
                    'meany', meanx(2), 'stdy', stdx(2), 'ylim', xlim([2,4]));
            end
        end
        
    case {'spline'}
        switch ftype
            case 'cubicspline'
                if ~all(weights==1)
                    warningFcn.throw( message( 'curvefit:fit:cubicSplineIgnoresWeights' ) );
                end
                try
                    pp = spline(xdata,ydata);
                catch es
                    % Special case a common error
                    
                    if strcmp(es.identifier,'MATLAB:chckxy:RepeatedSites')
                        errorFcn.throw( message( 'curvefit:fit:xDataMustBeDistinct' ) );
                        return;
                    else
                        errorFcn.throw( es );
                        return;
                    end
                end
                df = length(xdata);
                splineoutput = [];
            case 'smoothingspline'
                try
                    [pp,pout,df] = cfsmthspl(xdata,ydata,options.smoothingparam,weights);
                catch es
                    errorFcn.throw( es );
                    return;
                end
                splineoutput.p = pout;
            otherwise
                errorFcn.throw( message( 'curvefit:fit:unknownSplineType' ) );
                return;
        end % switch ftype
        res = ydata - ppval(pp,xdata);
        jacob = [];
        n = length(xdata);
        if df >= n
            dfe = 0;
        else
            dfe = n-df;
        end
        exitflag = 1;
        output = iOutputStructure(n,df,res,jacob,exitflag,splineoutput);
        goodness = iGoodnessStructure(ydata,weights,res,dfe,output);
        
        fitobj = cfit(model,pp,'sse',goodness.sse,'dfe',goodness.dfe, ...
            'Jacobian',jacob,'meanx',meanx,'stdx',stdx,'xlim',xlim);
        
    case 'interpolant'
        n = size( xdata, 1 );
        if n < 2
            errorFcn.throw( message( 'curvefit:fit:InsufficientData', 2) );
            return;
        end
        if ~all(weights==1)
            warningFcn.throw( message( 'curvefit:fit:interpolationIgnoresWeights' ) );
        end
        switch length( indepnames( model ) ) % number of independent variables
            case 1 % curve
                [fitobj, goodness, output] = iCurveInterpolation( ...
                    model, xdata, ydata, ftype, meanx, stdx, xlim, ...
                    errorFcn );
            case 2 % surface
                [fitobj, goodness, output] = iSurfaceInterpolation( ...
                    model, xdata, ydata, ftype, meanx, stdx, xlim, ...
                    errorFcn, warningFcn );
            otherwise
                errorFcn.throw( message( 'curvefit:fit:InvalidNIndepForInterp' ) );
                return;
        end
        
    case 'lowess'
        pp = curvefit.LowessFit;
        pp.Degree = iDegreeFromLowessType( ftype );
        pp.Span = options.Span;
        pp.Robust = options.Robust;
        
        try
            pp = fit( pp, xdata, ydata, weights );
        catch ME
            errorFcn.throw( ME );
            return
        end
        
        res = ydata - evaluate( pp, xdata );
        
        numparams = pp.Lambda;
        dfe = size( xdata, 1 ) - numparams;
        
        jacob = [];
        exitflag = 1;
        
        output = iOutputStructure(length(xdata),numparams,res,jacob,exitflag,[]);
        goodness = iGoodnessStructure(ydata, [], res,dfe,output);
        
        fitobj = sfit( model, pp, 'sse', 0, 'dfe' ,0, 'Jacobian',jacob,...
            'meanx', meanx(1), 'stdx', stdx(1), 'xlim', xlim([1,3]), ...
            'meany', meanx(2), 'stdy', stdx(2), 'ylim', xlim([2,4]) );
    otherwise
        errorFcn.throw( message( 'curvefit:fit:unrecognizedFittype' ) );
        return;
end

end

function output = iOutputStructure(numobs,numparam,resids,J,exitflag,oldoutput)
% OUTPUTSTRUCT Construct an output structure.
%
% OUTPUT = OUTPUTSTRUCT(NUMOBS,NUMPARAM,RESIDS,JACOB) creates
% structure OUTPUT with fields number of observations, number of
% parameters, residuals, and Jacobian matrix.

output.numobs = numobs;
output.numparam = numparam;
output.residuals = resids;
output.Jacobian = J;
output.exitflag = exitflag;

if ~isempty(oldoutput)
    fnames = fieldnames(oldoutput);
    for i=1:length(fnames)
        output.(fnames{i}) = oldoutput.(fnames{i});
    end
end

end

function goodness = iGoodnessStructure(ydata,weights,res,dfe,output,sse)
% GOODSTRUCT Construct a structure of goodness of fit values.
%
% GOODNESS = GOODSTRUCT(NUMOBS,NUMPARAM,RESIDS,JACOB) creates
% structure GOODNESS with fields sse, rsquare, adjrsquare and rmse
% from YDATA, WEIGHTS, YBAR, RES, DFE, and values of OUTPUT structure.

if isempty( weights )
    % If there are no weights, then they are assumed to be all ones.
    ybar = mean( ydata );
    sst = sum( (ydata - ybar).^2 );
else
    ybar = sum(ydata.*weights)/sum(weights);
    sst = sum(weights.*(ydata - ybar).^2);
end

% Compute SSE if not given
if nargin < 6
    sse = norm(res)^2;
end

% Compute R-squared, but avoid divide by zero warning
if ~isequal(sst,0)
    rsquare = 1 - sse/sst;
elseif isequal(sst,0) && isequal( sse, 0 )
    rsquare = NaN;
else % sst==0 && sse ~== 0
    % This is unusual, so try to determine if sse is just round-off error
    if sqrt(abs(sse))<sqrt(eps)*mean(abs(ydata))
        rsquare = NaN;
    else
        rsquare = -Inf;
    end
end

% Compute adjusted R-squared and RMSE
if dfe > 0
    adjrsquare = 1 - (1-rsquare)*(output.numobs-1)/dfe;
    mse = sse/dfe;
    rmse = sqrt( mse );
else
    dfe = 0;
    adjrsquare = NaN;
    rmse = NaN;
end

% Set up GOF structure
goodness = struct( ...
    'sse', sse, ...
    'rsquare', rsquare, ...
    'dfe', dfe, ...
    'adjrsquare', adjrsquare, ...
    'rmse', rmse );
end

function warningFcn = iCreateWarningFunction( supressWarning )
% iCreateErrorFunction   Create functions required to throw a warning
if supressWarning
    warningFcn = curvefit.attention.SuppressedWarning();
else
    warningFcn = curvefit.attention.Warning();
end

end

function errorFcn = iCreateErrorFunction( suppressError )
% iCreateErrorFunction   Create functions required to throw an error
if suppressError
    errorFcn = curvefit.attention.SuppressedError();
else
    errorFcn = curvefit.attention.Error();
end
end

function [p,S,J,optoutput,convmsg,residual,leverage] = ...
    iLinearFit(A,y,w,lowerbnd,upperbnd,fitopt,errorFcn, warningFcn )
% LINEARFIT   Solve linear least squares y = A*x, possibly with weights w.
%   See also: FIT

optoutput = [];
convmsg = '';
residual = [];
leverage = [];

lowerbnd = lowerbnd(:);
upperbnd = upperbnd(:);
boundsexist = false;
if ( ~isempty(lowerbnd) && any(~(lowerbnd==-inf)) ) ...
        || ( ~isempty(upperbnd) && any(~(upperbnd==inf)) )
    boundsexist = true;
end
n = size(A,2);
if ~isempty(w)
    w = w(:);
    sqrtw = sqrt(w);
    J = repmat(sqrtw,1,n).*A;
    Dy = sqrtw.*y;
else
    J = A;
    Dy = y;
end

if boundsexist
    try
        [p,residual,optoutput]=cflsqlin(J,Dy,lowerbnd,upperbnd,fitopt);
    catch es
        errorFcn.throw( es );
        return;
    end
    [Q,R] = qr(J,0);
else
    %  Solve least squares problem, and save the Cholesky factor.
    [Q,R] = qr(J,0);
    ws = warning('off', 'all');
    p = full(R\(Q'*Dy));    % Same as p = D*A\(D*y);
    warning(ws);
    if size(R,2) > size(R,1)
        warningFcn.throw( message( 'curvefit:fit:coeffsNotUnique' ) );
    elseif condest(R) > 1.0e10
        warningFcn.throw( message( 'curvefit:fit:equationBadlyConditioned' ) );
    end
    
    residual = Dy - J*p;
    optoutput.algorithm = 'QR factorization and solve';
    optoutput.iterations = 1;
end

% S is a structure containing three elements: the Cholesky factor of the
% A matrix, the degrees of freedom and the norm of the residuals.
S.R = R;
S.df = length(y) - n;
S.normr = norm(residual);

% Compute leverage if requested
if nargout >= 7
    leverage = sum(Q.*Q,2);
end

end

function [p,s,optoutput,convmsg,exitflag] = ...
    iRobustLinearFit(X,y,p0,s,robtype,lowerbnd,upperbnd,fitopt,errorFcn,warningFcn,leverage,res,optoutput)
% CFROBLINFIT  Robust linear fitting
%   See also: FIT

%   [P,S,WSTR] = CFROBLINFIT(X,Y,W,P,S) takes as input an x data
%   matrix X, a response vector Y, a weight vector W, a vector P of
%   starting estimates (usually from ordinary least squares), and a
%   stats structure S compatible with polyfit output.  Outputs are
%   a vector P of coefficient estimates, an updated stats structure
%   S, and a string WSTR that may contain warning messages.

% Note: y is unweighted intentionally

if nargin<4 || isempty(p0)
    p0 = ones(size(X,2),1);
end
p = p0(:);
p0 = zeros(size(p));
P = length(p0);
N = length(y);

% Adjust residuals using leverage, as advised by DuMouchel & O'Brien
h = min(.9999, leverage);
adjfactor = 1 ./ sqrt(1-h);

dfe = N-P;
ols_s = s.normr / sqrt(dfe);

% If we get a perfect or near perfect fit, the whole idea of finding
% outliers by comparing them to the residual standard deviation becomes
% difficult.  We'll deal with that by never allowing our estimate of the
% standard deviation of the error term to get below a value that is a small
% fraction of the standard deviation of the raw response values.
tiny_s = 1e-6 * std(y);
if tiny_s==0
    tiny_s = 1;
end

% Perform iteratively re-weighted least squares to get coefficient estimates
D = 1e-6;
iter = 0;
iterlim = 50;

% Find out number of iterations used up so far (will be absent,
% meaning 1, if the fit is unbounded and linear)
if isfield(optoutput,'iterations')
    totaliter = optoutput.iterations;
else
    totaliter = 1;
end

% While not converged, estimate weights from residuals and fit again.
while true % DO-WHILE loop. Exit condition is at the end.
    iter = iter+1;
    
    % Adjust residuals from previous fit, then compute scale estimate
    radj = res .* adjfactor;
    rs = sort(abs(radj));
    sigma = median(rs(P:end)) / 0.6745;
    
    % Compute new weights from these residuals, then re-fit
    tune = 4.685;
    bw = cfrobwts(robtype,radj/(max(tiny_s,sigma)*tune));
    p0 = p;
    [p,~,~,optoutput,convmsg] = ...
        iLinearFit(X,y,bw,lowerbnd,upperbnd,fitopt,errorFcn, warningFcn);
    totaliter = totaliter + optoutput.iterations;
    res = y - X*p;
    
    % After 1st iteration for LAR, don't use adjusted residuals
    if iter==1 && isequal(robtype,'lar')
        adjfactor = 1;
    end
    
    % DO-WHILE loop -- Exit conditions
    %
    % Check for convergence
    if all( abs( p-p0 ) <= D*max( abs( p ), abs( p0 ) ) )
        exitflag = 1;
        break
    end
    % Check if the iteration limit has been exceeded
    if (iter > iterlim)
        exitflag = 0;
        warningFcn.throw( message( 'curvefit:fit:iterationLimitReached' ) );
        break
    end
    % Check for user interruption
    if cfInterrupt( 'get' )
        exitflag = -1;
        break
    end
end % DO-WHILE loop

if (nargout>1)
    % Return the total number of iterations
    optoutput.iterations = totaliter;
    
    % Compute robust mse
    radj = res .* adjfactor;
    if all(bw<D | bw>1-D)
        % All weights 0 or 1, this amounts to ols using a subset of the data
        included = (bw>1-D);
        robust_s = norm(res(included)) / sqrt(sum(included) - P);
    else
        % Use method of DuMouchel & O'Brien (1989)
        robust_s = cfrobsigma(max(tiny_s,sigma),robtype,radj, P, tune, h);
    end
    
    % Shrink robust value toward ols value if appropriate
    sigma = max(robust_s, sqrt((ols_s^2 * P^2 + robust_s^2 * N) / (P^2 + N)));
    s.normr = sigma * sqrt(dfe);
end

end

function theError = iHandleFevalError( theException )
% iHandleFevalError( ME ) looks at the MException, ME, and tries to determine
% the correct error message. If the cause of the problem is not an Inf, NaN or
% complex value in the call to FEVAL, then iHandleFevalError will just return
% the MException ME.

switch theException.identifier
    case {  'curvefit:fittype:feval:modelComputedNaN', ...
            'curvefit:fittype:feval:JacobianComputedNaN'}
        theError = message( 'curvefit:fit:nanComputed' );
        
    case {  'curvefit:fittype:feval:modelComputedInf', ...
            'curvefit:fittype:feval:JacobianComputedInf', ...
            'MATLAB:eig:matrixWithNaNInf', ...
            'optimlib:snls:DerivUndefAtX0'}
        theError = message( 'curvefit:fit:infComputed' );
        
    case {  'curvefit:fittype:feval:modelComputedComplex', ...
            'curvefit:fittype:feval:JacobianComputedComplex'}
        theError = message( 'curvefit:fit:complexValueComputed' );
        
    otherwise
        % The problem was something we don't know about.
        theError = theException;
end

end

function [fitobj, goodness, output] = iCurveInterpolation( ...
    model, xdata, ydata, ftype, meanx, stdx, xlim, errorFcn )
% iCurveInterpolation   Fit a curve by interpolation
%   See also: FIT

% Set up return arguments as we will return early if we encounter an error

fitobj = cfit;
goodness = [];
output = [];

% Swap 'cubicinterp' for 'splineinterp'
if isequal( ftype, 'cubicinterp' )
    ftype = 'splineinterp';
end
% Check that the given fittype name is one that we know how to handle
if ~ismember( ftype, {'linearinterp','pchipinterp','splineinterp','nearestinterp'} )
    errorFcn.throw( message( 'curvefit:fit:unknownInterpType' ) );
    return
end

% Use PPINTERP to perform the interpolation
try
    % ppinterp sorts xdata and ydata if needed
    pp = ppinterp(xdata,ydata,ftype(1));
catch es
    errorFcn.throw( message( es.identifier ) );
    return;
end

% Compute goodness-of-fit information
res = ydata - ppval(pp,xdata);
dfe = 0;
jacob = [];
numparams = length(ydata);   % each obs. is a parameter
exitflag = 1;

% Construct fit-object, goodness-of-fit struct and output struct.
output = iOutputStructure(length(xdata),numparams,res,jacob,exitflag,[]);
goodness = iGoodnessStructure(ydata, [], res,dfe,output);

fitobj = cfit(model,pp,'sse',0,'dfe',0,'Jacobian',jacob,...
    'meanx',meanx,'stdx',stdx,'xlim',xlim);
end

function [fitobj, goodness, output] = iSurfaceInterpolation( ...
    model, xdata, ydata, ftype, meanx, stdx, xlim, errorFcn, warningFcn )
% iSurfaceInterpolation   Fit a surface by interpolation
%   See also: FIT

% Set up return arguments as we will return early if we encounter an error
fitobj = cfit;
goodness = [];
output = [];

% Store all the info to evaluate the surface
aFactory = curvefit.model.SurfaceInterpolantFactory( 'ErrorThrower', errorFcn, 'WarningThrower', warningFcn );
pp = aFactory.create( ftype, xdata, ydata );

if isempty( pp )
    % Must have thrown error
    return
end


% Evaluate the model to work out the residual
res = ydata - evaluate( pp, xdata );

dfe = 0;
jacob = [];
numparams = length(ydata);   % each obs. is a parameter
exitflag = 1;

output = iOutputStructure(length(xdata),numparams,res,jacob,exitflag,[]);
goodness = iGoodnessStructure(ydata, [], res,dfe,output);

fitobj = sfit(model,pp,'sse',0,'dfe',0,'Jacobian',jacob,...
    'meanx', meanx(1), 'stdx', stdx(1), 'xlim', xlim([1,3]), ...
    'meany', meanx(2), 'stdy', stdx(2), 'ylim', xlim([2,4]) );
end

function degree = iDegreeFromLowessType( ftype )

switch ftype
    case 'lowess' % linear
        degree = 1;
    case 'loess' % quadratic
        degree = 2;
end
end

function [useroptions, useroptargs, probparams] = iParseOptionalArgs( varargin )
probparams = {};
useroptions = [];
useroptargs = {};
switch nargin
    case 0
        % do nothing
        
    case 1 % fit( X, Y, FT, opts )
        if isfitoptions(varargin{1}) % fitoptions object
            useroptions = varargin{1};
        else
            error(message('curvefit:fit:InvalidFitOptions'));
        end
        
    case 3 % fit options and problem parameter
        if isfitoptions(varargin{1}) % fit( X, Y, FT, opts, 'problem', p )
            useroptions = varargin{1};
            paramname = varargin{2};
            probparams = varargin{3};
        elseif isfitoptions(varargin{3}) % fit( X, Y, FT, 'problem', p, opts )
            useroptions = varargin{3};
            probparams = varargin{2};
            paramname = varargin{1};
        else
            error(message('curvefit:fit:unknownCallingSequence'))
        end
        if  ~isequal( paramname, 'problem' )
            error(message('curvefit:fit:invalidOptionsCallingSequence', paramname));
        end
        
    otherwise % p-v pairs
        if mod( length( varargin ), 2 ) ~= 0
            error(message('curvefit:fit:invalidPVPairs'));
        end
        if ~iscellstr( varargin(1:2:end) )
            error(message('curvefit:fit:paramNameMustBeString'));
        end
        % Check for problem parameters by looking through the params.
        % Only param that start with p is problem.
        ind = find( strncmp( 'p', varargin(1:2:end), 1 ) );
        ind = ind*2-1; % we skipped every other one when computing index
        if length(ind) > 1
            error(message('curvefit:fit:tooManyProblemParams'))
        elseif length(ind) == 1
            probparams = varargin{ind+1};
            varargin(ind:ind+1) = [];
        end
        % Param-value pairs
        useroptargs = varargin;
end

% The problem parameters need to be in a cell array.
if ~iscell(probparams)
    probparams = {probparams};
end

end

function iAssertNumIndepEqualsNumDataColumns( theFittype, xData )
% iAssertNumIndepEqualsNumDataColumns -- Check to see if the number of
% input arguments specified by the data agrees with the number of independent
% variables in the fittype. If not, then throw an error
numIndep = length( indepnames( theFittype ) );
numDataColumns = size( xData, 2 );
if numIndep ~= numDataColumns
    if numIndep == 1
        % Then the fittype is for a curve but the data is for a surface.
        error( message( 'curvefit:fit:CurveFittypeSurfaceData' ) );
        
    else % assume numIndep == 2
        % Then the fittype is for a surface but the data is for a curve.
        error( message( 'curvefit:fit:SurfaceFittypeCurveData' ) );
        
    end
end
end

function iAssertNumProblemParameters( values, names )
% iAssertNumProblemParameters -- check that the number of problem
% parameter values given matches the number required by the fittype.
%
% VALUES is the cell array of problem values specified to the FIT command.
% NAMES is a cell array of problem parameter names extracted from the
%   FITTYPE, i.e., NAMES = probnames( FITTYPE ).
if isempty( values ) && ~isempty( names )
    error( message( 'curvefit:fit:missingProblemValues' ) );
elseif length( values ) ~= length( names )
    error( message( 'curvefit:fit:wrongNumProblemValues' ) );
end
end

function [model, options] = iCheckAlgorithmAndBounds( model, options, ...
    lowerbnd, upperbnd, warningFcn )
% iCheckAlgorithmAndBounds   Check that the requested algorithm can handle
% the given bounds.
%
% If Levenberg-Marquardt is chosen as the non-linear fitting algorithm but there
% are finite bounds on the coefficients then the algorithm should be changed to
% trust-region and a warning should be thrown.

% If the bounds are infinite ...
if all( isinf( lowerbnd ) ) && all( isinf( upperbnd ) )
    % ... then nothing needs to be done
    
    % But if the bounds are finite and the algorithm is Levenberg-Marquardt
elseif strcmpi( options.Algorithm, 'Levenberg-Marquardt' )
    % ... then we need to warn ...
    warningFcn.throw( message( 'curvefit:fit:usingTrustRegion', options.Algorithm ) );
    % ... and swap algorithm
    options.Algorithm = 'trust-region';
    model = setoptions(model,options);
end

end

function [xout,resnorm,res,exitflag,optoutput,activebounds,convmsg,J] = iNonLinearFit(...
    model, start,xdata,wtdydata,lowerbnd,upperbnd, options,probparams, ...
    separargs,weights, optimargs, nonlcoeffindex)

robustflag = lower(options.robust);
dorobust = ~isequal(robustflag,'off');

% resnorm, res and jacob all include weights after cflsqcurvefit
if dorobust && isequal(lower(options.Display),'iter')
    initialFittingHeader = getString(message('curvefit:curvefit:InitialFittingHeader'));
    fprintf( '\n%s\n----------------', initialFittingHeader );
    optimoptions = options;
elseif dorobust && ( isequal(lower(options.Display),'notify') || isequal(lower(options.Display),'final') )
    % If 'notify' or 'final', only want to print final convmsg, so turn Display 'off'.
    optimoptions = fitoptions(options, 'Display', 'off');
else
    optimoptions = options;
end

[ xout,resnorm,res,exitflag,optoutput,jacob,convmsg] = ...
    cflsqcurvefit(model,start,xdata,wtdydata,lowerbnd,upperbnd,...
    optimoptions,probparams{:},separargs{:},optimargs{:});

% Trust region method may return a sparse Jacobian
J = full(jacob);

activebounds = isActiveBounds(xout,lowerbnd,upperbnd);

if dorobust && exitflag~=0
    % res, jacob from cfrobnlinfit have user weights but not the robust weights
    % resnorm has special calculation involving both: see cfrobnlinfit
    [xout,resnorm,res,exitflag,optoutput,activebounds,jacob,convmsg] = ...
        cfrobnlinfit(model,xout,xdata,wtdydata,lowerbnd,upperbnd,...
        optimoptions,probparams,separargs,weights,res, J, ...
        robustflag,optoutput.iterations,optoutput.funcCount);
    J = full(jacob); % Trust region method may return a sparse Jacobian
    
elseif ~isempty(separargs)
    % If separable and not robust (because cfrobnlinfit will get all coefficients)
    %  calculate Jacobian J at the solution, with weights, but not robust weights.
    % Note only library equations can be separable, so J always computable analytically.
    [~,J,xout] = feval(model,xout,xdata,probparams{:},separargs{:},optimargs{:});
end

if ~isempty(separargs)
    activebounds = iAdjustActiveBoundsForSeparable( activebounds, nonlcoeffindex, numcoeffs(model) );
end

% If robust and original options Display is Notify or Final, need to display convmsg
if dorobust
    if ( isequal(lower(options.Display),'notify') && exitflag <= 0 )
        disp(convmsg);
    elseif ( isequal(lower(options.Display),'final') )
        disp(convmsg);
    end
end
end

function [start, anError, aWarning] = iCheckStartPoint( start, model, probparams, xdata, ydata )
% iCheckStartPoint   Ensure that the start point is valid. Throw errors or
% warnings if it is not valid.
anError = '';
aWarning = '';
numcoeff = numcoeffs( model );

% If the start point is empty, then use the model to estimate a start point
if isempty( start )
    startPointFcn = startpt( model );
    
    % If there is no function to estimate the start point, then we need to use a
    % random start point.
    if isempty( startPointFcn )
        aWarning = message( 'curvefit:fit:noStartPoint' );
        start = rand( numcoeff, 1 );
    else
        % Get constants for library functions
        someConstants = constants( model );
        try
            start = startPointFcn( probparams{:}, xdata, ydata, someConstants{:} );
        catch es
            anError = es;
            return
        end
    end
end

% Start points must be finite and real.
if ~all(isfinite(start)) || ~isreal(start)
    aWarning = message( 'curvefit:fit:invalidStartPoint' );
    start = rand(size(start));
end

% There has to be exactly one start point per coefficient
if numel( start ) < numcoeff
    anError = message( 'curvefit:fit:tooFewStartPoints', int2str( numcoeff ) );
    return
end
if numel( start ) > numcoeff
    anError = message( 'curvefit:fit:tooManyStartPoints', int2str( numcoeff ) );
    return
end
end

function options = iGetFitOptions(model, useroptions, useroptargs, warningFcn)
% iGetFitOptions   Get fit options from model and combine with the optional
% arguments
options = fitoptions( model );
if ~isempty( useroptions )
    if iAreIncompatibleOptions(useroptions,options);
        warningFcn.throw( message( 'curvefit:fit:mismatchedOptions', useroptions.Method, options.Method  ) );
    end
    % merge model and user provided options
    options = fitoptions( options, useroptions );
end
if ~isempty(useroptargs)
    options = fitoptions(options, useroptargs{:});
end
end

function incompatible = iAreIncompatibleOptions(useroptions,options)
% areIncompatibleOptions   True if two sets of options are incompatible in
% the sense that they cannot be merged
compatible = isa( useroptions, class( options ) ) ...
    ||       isa( options,     class( useroptions ) );
incompatible = ~compatible;
end

function activebounds = iAdjustActiveBoundsForSeparable( nonlactive, nonlcoeffindex, numcoeffs )
% iAdjustActiveBoundsForSeparable   Adjust a vector of active bounds
% indicators to account for separable coefficents.
%
% The active bounds are the "non-linear" bounds that are active
%
% Arguments:
%
% nonlactive -- logical vector true where a bound on a non-linear
% coefficient is active
%
% nonlcoeffindex -- indices of non-linear coefficients within a vector of
% all coefficients
%
% numcoeffs -- number of linear and non-linear coefficients
%
% activebounds -- logical vector true where a bound on any coefficient
% (both linear and non-linear) is active
activebounds = false( 1, numcoeffs );
activebounds(nonlcoeffindex) = nonlactive;
end

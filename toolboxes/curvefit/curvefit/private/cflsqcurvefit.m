function [x, Resnorm, residuals, EXITFLAG, OUTPUT, JACOB, msg] = cflsqcurvefit( ...
    FUN, x, XDATA, YDATA, LB, UB, fitopt, varargin)
%CFLSQCURVEFIT   Solves non-linear least squares problems.
%
%   [x, Resnorm, residuals, EXITFLAG, OUTPUT, LAMBDA, JACOB, msg] = CFLSQCURVEFIT( ...
%       FUN, X, XDATA, YDATA, LB, UB, FITOPT, ...)
%
%   See also FIT, LSQCURVEFIT.

%   Copyright 2001-2014 The MathWorks, Inc.

% Convert FITOPTIONS to OPTIMOPTIONS
options = optimset( rmfield( getallfields( fitopt ), 'Algorithm' ) );

% Set the options related to the different optimization algorithms
switch lower(fitopt.Algorithm)
    case 'trust-region'
        options.Algorithm = 'trust-region-reflective';
        Jrows = length( XDATA );
        Jcols = length( x );
        options.JacobPattern = ones( Jrows, Jcols );
        options.PrecondBandWidth = Inf;
        iterDisplayFcn = @iIterDispOutFcnTRR;
        
    case 'levenberg-marquardt'
        options.Algorithm = 'levenberg-marquardt';
        iterDisplayFcn = @iIterDispOutFcnLM;
        
    case 'gauss-newton'
        error(message('curvefit:fitoptions:GaussNewtonRemoved'));

    otherwise
        error(message('curvefit:cflsqcurvefit:invalidAlgorithm'));
end

% Set the interrupt function
options.OutputFcn = @iFittingInterrupt;

% Turn off the display of messages that are built in
options.Display = 'off';
% But turn on our own iterative display if requested
if strcmpi( fitopt.Display, 'iter' )
    options.OutputFcn = {options.OutputFcn, iterDisplayFcn};
end

% Call LSCFTSH
[x,Resnorm,~,EXITFLAG,OUTPUT,~,JACOB] = cflscftsh(FUN,x,XDATA,YDATA,LB,UB,options,varargin{:});

JACOB = iJacobian(FUN,x,XDATA,JACOB,LB,UB,varargin{:});

% Manually calculate residuals
YFIT = feval( FUN, x, XDATA, varargin{:} );
residuals = YDATA - YFIT;

% Generate and display exit message
msg = iExitMessageFromExitFlag( EXITFLAG );
OUTPUT.message = msg;

isDisplayExitMsg = strcmpi( fitopt.Display, 'iter' ) || strcmpi( fitopt.Display, 'final' );
if isDisplayExitMsg 
    disp( msg )
end
end

function stop = iFittingInterrupt(~, ~, ~, varargin)
% iOutputFcn(x,optimValues,state)
stop = cfInterrupt( 'get' );
end

function stop = iIterDispOutFcnTRR(~, optimValues, state, varargin)
% iIterDispOutFcnTrr Output function that produces iterative display.
%
% Helper function that produces iterative display for the trust-region-reflective
% algorithm in lsqcurvefit.

% This output function only displays iterative output; it never stops the run
stop = false;

header = sprintf(['\n                                         Norm of      First-order \n',...
    ' Iteration  Func-count     f(x)          step          optimality   CG-iterations']);
% Format for 0th iteration
formatstrFirstIter = ' %5.0f      %5.0f   %13.6g                  %12.3g';
% Format for iterations >= 1
formatstr = ' %5.0f      %5.0f   %13.6g  %13.6g   %12.3g      %7.0f';

if strcmpi(state,'init')
    % Iterative display header
    disp(header);
elseif strcmpi(state,'iter')
    % Iterative display
    if optimValues.iteration == 0
        % Only a subset of the displayed quantities are available at iteration zero
        fprintf([formatstrFirstIter '\n'], ...
            optimValues.iteration, ...
            optimValues.funccount, ...
            optimValues.resnorm, ...
            norm(optimValues.firstorderopt,Inf));
    else
        fprintf([formatstr '\n'], ...
            optimValues.iteration, ...
            optimValues.funccount, ...
            optimValues.resnorm, ...
            optimValues.stepsize, ...
            norm(optimValues.firstorderopt,Inf), ...
            optimValues.cgiterations);
    end
end
end

function stop = iIterDispOutFcnLM(~, optimValues, state, varargin)
% iIterDispOutFcnLm Output function that produces iterative display.
%
% Helper function that produces iterative display for the levenberg-marquardt
% algorithm in lsqcurvefit.

% This output function only displays iterative output; it never stops the run
stop = false;

if strcmpi(state,'init')
    % Iterative display header
    fprintf( ...
        ['\n                                        First-Order                    Norm of \n', ...
        ' Iteration  Func-count    Residual       optimality      Lambda           step\n']);
elseif strcmpi(state,'iter')
    % Iterative display
    fprintf(' %5.0f       %5.0f   %13.6g    %12.3g %12.6g   %12.6g\n',optimValues.iteration, ...
        optimValues.funccount,optimValues.resnorm,norm(optimValues.gradient,Inf),optimValues.lambda, ...
        norm(optimValues.searchdirection));
end
end

function jacobian = iJacobian( aFittype, coefficients, xData, jacobian, lower, upper, varargin )
% iJacobian   Compute the Jacobian of a fittype

if ~isempty( jacobian )
    % Nothing to do, we already have the Jacobian
elseif strcmpi( 'customnonlinear', type( aFittype ) )
    % Custom non-linear requires numerical computation of Jacobian
    jacobian = curvefit.numericalJacobian( aFittype, coefficients, xData, lower, upper, varargin{:} );
else
    % Other fittypes support direct computation of Jacobian
    [~, jacobian] = feval( aFittype, coefficients, xData, varargin{:} );
end
end

function msg = iExitMessageFromExitFlag( flag )
% iExitMessageFromExitFlag   Generate an exit message from an exit flag

idFromFlag = iExitFlagToIdentifierMap();
msg = getString( message( idFromFlag.get( flag ) ) );
end

function map = iExitFlagToIdentifierMap()
% iExitFlagToIdentifierMap   A map that gives a message ID for a given exit flag.

map = curvefit.MapDefault.fromCellArray( {
    1,  'curvefit:curvefit:FittingConvergedToASolution'
    2,  'curvefit:curvefit:FittingStoppedBecauseChangeInCoefficientsLessThanTolX'
    3,  'curvefit:curvefit:FittingStoppedBecauseChangeInResidualsLessThanTolFun'
    4,  'curvefit:curvefit:FittingStoppedBecauseMagnitudeOfSearchDirection'
    0,  'curvefit:curvefit:FittingStoppedBecauseMaxIterOrMaxFunEvalExceeded'
    -1, 'curvefit:curvefit:FittingStoppedByUser'
    -2, 'curvefit:curvefit:FitNotComputedBecauseLowerBoundsAreGreaterThanUpperBounds'
    -4, 'curvefit:curvefit:FittingCouldNotMakeFurtherProgress'
    }, ...
    'DefaultValue', 'curvefit:curvefit:FittingStoppedForUnknownReason', ...
    'WarningID', 'curvefit:curvefit:FittingStoppedForUnknownReason' );
end

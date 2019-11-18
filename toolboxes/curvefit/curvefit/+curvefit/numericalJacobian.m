function jacobian = numericalJacobian( aFittype, coefficients, xData, lowerBounds, upperBounds, varargin )
% numericalJacobian   Numerically compute Jacobian
%
% Syntax:
%   J = curvefit.numericalJacobian( ft, c, x, lb, ub, <extra arguments> )
%
% Inputs:
%   ft --  function or fittype to compute Jacobian for
%       Curves:   ft: (c, x)      --> y
%       Surfaces: ft: (c, [x, y]) --> z
%   c -- coefficients should be nCoefficients-by-1
%   x -- evaluation points should be nPoints-by-nDim
%   lb -- lower bounds
%   ub -- upper bounds
%   <extra arguments> -- any extra arguments (varargin) to pass to the function ft.

%   Copyright 2012 The MathWorks, Inc.

% Ensure that coefficients & bounds are in columns
coefficients = coefficients(:);
lowerBounds = lowerBounds(:);
upperBounds = upperBounds(:);

% Evaluate a model including passing in any optional arguments
    function yi = evaluate( xData, coefficients )
        yi = aFittype( coefficients, xData, varargin{:} );
    end

% The threshold is (proportional to) the minimum magnitude of the perturbation
lowerBounds = iAssureLowerBounds( coefficients, lowerBounds );
upperBounds = iAssureUpperBounds( coefficients, upperBounds );
threshold = arrayfun( @iThreshold, lowerBounds, upperBounds );

% Compute Jacobian via numjac
yHat = evaluate( xData, coefficients );
jacobian = numjac( @evaluate, xData, coefficients, yHat, threshold, [] );
end

function threshold = iThreshold( lower, upper )
% iThreshold   Compute threshold for lower and upper bound
if 0 < lower && upper < 1e-6
    % Both bounds are "small" and same sign ==> use smallest
    threshold = lower;

elseif -1e-6 < lower  && upper < 0 
    % Both bounds are "small" and same sign ==> use smallest
    threshold = -upper;

elseif -1e6 < lower && lower < 0 && 0 < upper && upper < 1e-6
    % Both bounds are "small" but different sign ==> use something smaller than the
    % smallest
    threshold = 1e-6 * min( -lower, upper );

elseif lower == 0 && upper < 1e-6
    % One bound is "small", the other is zero ==> use something smaller than the
    % smallest
    threshold = 1e-6*upper;

elseif -1e-6  < lower && upper == 0 
    % One bound is "small", the other is zero ==> use something smaller than the
    % smallest
    threshold = -1e-6*lower;

else
    % "Large" case
    threshold = 1e-6;
end
end

function lowerBounds = iAssureLowerBounds( coefficients, lowerBounds )
if isempty( lowerBounds )
    lowerBounds = -Inf( size( coefficients ) );
end
end

function upperBounds = iAssureUpperBounds( coefficients, upperBounds )
if isempty( upperBounds )
    upperBounds = Inf( size( coefficients ) );
end
end

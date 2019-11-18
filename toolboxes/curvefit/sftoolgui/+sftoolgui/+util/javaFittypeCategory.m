function [ ft ] = javaFittypeCategory( fittype, customEquation )
% javaFittypeCategory gets the fittype category from the "type" for java.

%   Copyright 2010-2012 The MathWorks, Inc.

theType = type(fittype);
ft = iTranslateType(theType, customEquation);
end

function ft = iTranslateType(theType, customEquation)
if strncmpi( theType, 'exp', 3 )
    % Exponential
    ft = 'Exponential';
    
elseif strncmpi( theType, 'fourier', 7 ) 
    % Fourier
    ft = 'Fourier';
    
elseif strncmpi( theType, 'gauss', 5 )
    % Gaussian
    ft = 'Gaussian';
    
elseif ~isempty( strfind( theType, 'interp' ) )
    % Interpolant
    ft = 'Interpolant'; 
    
elseif strcmpi( theType, 'lowess' ) || strcmpi( theType, 'loess' )
    % Lowess
    ft = 'Lowess';
    
elseif strncmpi( theType, 'poly', 4 )
    % Polynomial
    ft = 'Polynomial';

elseif strncmpi( theType, 'power', 5 )
    % Power
    ft = 'Power';
    
elseif strncmpi( theType, 'rat', 3 )
    % Rational
    ft = 'Rational';

elseif strcmpi ( theType, 'smoothingspline')
    % Smoothing spline
    ft = 'SmoothingSpline';
    
elseif strncmpi ( theType, 'sin', 3 )
    % SumOfSine
    ft = 'SumOfSine';

elseif strcmpi (theType, 'weibull' )
    % Weibull
    ft = 'Weibull';

elseif strcmpi (theType, 'customlinear' )
    % Weibull
    ft = 'CustomLinear';

else
    % Custom Equation
    ft = customEquation;
end
end

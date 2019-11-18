function specification = createNewCurveSpecification( fitTypeName, qualifier, optionNameValuePairs, coefficientOptions, ind, dep, linearCoefficients, linearTerms)
% createNewCurveSpecification creates a curve fittype and options.
%
%   Example
%       coefficientOpts = sftoolgui.MutableCoefficientCache
%       specification = sftoolgui.util.createNewCurveSpecification('Gaussian', '1', {}, coefficientOpts)

%   Copyright 2010-2013 The MathWorks, Inc.

% First create the specification
switch fitTypeName
    case 'Exponential'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification('exp', qualifier, optionNameValuePairs, coefficientOptions);
    case 'Fourier'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification('fourier', qualifier, optionNameValuePairs, coefficientOptions);
    case 'Gaussian'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification('gauss', qualifier, optionNameValuePairs, coefficientOptions);
    case 'Interpolant'
        specification = sftoolgui.fittypespec.InterpolantCurveSpecification(qualifier, optionNameValuePairs);
    case 'Polynomial'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification('poly', qualifier, optionNameValuePairs, coefficientOptions);
    case 'Power'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification('power', qualifier, optionNameValuePairs, coefficientOptions);
    case 'Rational'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification('rat', qualifier, optionNameValuePairs, coefficientOptions);
    case 'SmoothingSpline'
        specification = sftoolgui.fittypespec.SmoothingSplineCurveSpecification(optionNameValuePairs);
    case 'SumOfSine'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification('sin', qualifier, optionNameValuePairs, coefficientOptions);
    case 'Weibull'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification('weibull', qualifier, optionNameValuePairs, coefficientOptions);
    case 'CustomLinear'
        specification = sftoolgui.fittypespec.CustomLinearCurveSpecification(linearCoefficients, linearTerms, coefficientOptions, ind, dep);
    otherwise
        % Should be a custom equation
        specification = sftoolgui.fittypespec.CustomNonLinearCurveSpecification(fitTypeName, optionNameValuePairs, coefficientOptions, ind, dep);
end

end
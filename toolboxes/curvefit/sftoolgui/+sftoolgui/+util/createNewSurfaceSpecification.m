function specification = createNewSurfaceSpecification( fitTypeName, qualifier, args, coefficientOptions, ind, dep )
% createNewSurfaceSpecification creates a surface specification
%   Example
%       coefficientOpts = sftoolgui.MutableCoefficientCache
%       sftoolgui.util.createNewSurfaceSpecification('Polynomial', '13', {}, coefficientOpts)
       
%   Copyright 2010-2013 The MathWorks, Inc.

% create the specification
switch fitTypeName
    case 'Interpolant'
        specification = sftoolgui.fittypespec.InterpolantSurfaceSpecification(qualifier, args);
    case 'Polynomial'
        specification = sftoolgui.fittypespec.PolynomialSurfaceSpecification(qualifier, args, coefficientOptions);
    case 'Lowess'
        specification = sftoolgui.fittypespec.LowessSurfaceSpecification(qualifier, args);
    otherwise
        % Should be a custom equation
        specification = sftoolgui.fittypespec.CustomNonLinearSurfaceSpecification(fitTypeName, args, coefficientOptions, ind, dep);
end
end

classdef DefinitionConverter < curvefit.Handle
% DefinitionConverter is a helper class which allows us to convert
% FitDefinitions to FittypeSpecifications.  This has been made into a class
% because it requires access to a hidden function in FittypeSpecification

%   Copyright 2013 The MathWorks, Inc.

    methods(Static)
        function specification = convertDefinitionToSpecification(definition)
            % convertDefinitionToSpecification converts the old style FitDefinition to
            % the new style FittypeSpecification
            
            ft = definition.Type;
            fopts = definition.Options;
            
            if (isempty(ft))
                specification = iGetDefaultSpecification();
                return
            end
            
            if iIsCurve(ft)
                specification = iGenerateCurveSpecification(ft);
            else
                specification = iGenerateSurfaceSpecification(ft);
            end
            
            % Overwrite the fittype because the specification will create a
            % new fit automatically
            specification.overwriteFittypeAndOptions( ft, fopts );
        end
    end
end



function specification = iGenerateCurveSpecification(ft)

switch(type(ft))
    case 'customnonlinear'
        specification = sftoolgui.fittypespec.CustomNonLinearCurveSpecification(...
            formula(ft), {}, sftoolgui.ImmutableCoefficientCache, indepnames(ft), iDependentVariables(ft) ...
            );
    case 'smoothingspline'
        specification = sftoolgui.fittypespec.SmoothingSplineCurveSpecification({});
    case 'linearinterp'
        specification = sftoolgui.fittypespec.InterpolantCurveSpecification('linear', {});
    case 'pchipinterp'
        specification = sftoolgui.fittypespec.InterpolantCurveSpecification('PCHIP', {});
    case 'splineinterp'
        specification = sftoolgui.fittypespec.InterpolantCurveSpecification('cubic', {});
    case 'nearestinterp'
        specification = sftoolgui.fittypespec.InterpolantCurveSpecification('nearest', {});
    otherwise
        specification = iGenerateLibraryCurveSpecification(ft);
end

end

function specification = iGenerateSurfaceSpecification(ft)

switch(type(ft))
    case 'customnonlinear'
        specification = sftoolgui.fittypespec.CustomNonLinearSurfaceSpecification(...
            formula(ft), {}, sftoolgui.ImmutableCoefficientCache, indepnames(ft), iDependentVariables(ft) ...
            );
    case 'lowess'
        specification = sftoolgui.fittypespec.LowessSurfaceSpecification('linear', {});
    case 'loess'
        specification = sftoolgui.fittypespec.LowessSurfaceSpecification('quadratic', {});
    case 'linearinterp'
        specification = sftoolgui.fittypespec.InterpolantSurfaceSpecification('linear', {});
    case 'biharmonicinterp'
        specification = sftoolgui.fittypespec.InterpolantSurfaceSpecification('v4', {});
    case 'cubicinterp'
        specification = sftoolgui.fittypespec.InterpolantSurfaceSpecification('cubic', {});
    case 'nearestinterp'
        specification = sftoolgui.fittypespec.InterpolantSurfaceSpecification('nearest', {});
    case 'thinplateinterp'
        specification = sftoolgui.fittypespec.InterpolantSurfaceSpecification('thinplate', {});
    otherwise
        specification = iGeneratePolynomialSurfaceSpecification(ft);
end

end

function variables = iDependentVariables(ft)
variables = char(dependnames(ft));
end

function specification = iGeneratePolynomialSurfaceSpecification(ft)
fullName = type(ft);
qualifier = fullName(5:6);

specification = sftoolgui.fittypespec.PolynomialSurfaceSpecification(qualifier, {}, sftoolgui.ImmutableCoefficientCache);
end

function specification = iGenerateLibraryCurveSpecification(ft)
fullName = type(ft);
[~,~,~, nameMatches] = regexp(fullName, '[A-Za-z]+');
libraryModelName = nameMatches{1};

[~,~,~, nameMatches] = regexp(fullName, '[0-9]+');

switch(libraryModelName)
    case 'weibull'
        specification = sftoolgui.fittypespec.LibraryCurveSpecification(libraryModelName, '', {}, sftoolgui.ImmutableCoefficientCache);
    otherwise
        qualifier = nameMatches{1};
        specification = sftoolgui.fittypespec.LibraryCurveSpecification(libraryModelName, qualifier, {}, sftoolgui.ImmutableCoefficientCache);
end
end

function specification = iGetDefaultSpecification()
specification = sftoolgui.fittypespec.LibraryCurveSpecification('poly', '1', {}, sftoolgui.ImmutableCoefficientCache);
end

function isCurve = iIsCurve(ft)
isCurve = (length(indepnames(ft)) == 1);
end

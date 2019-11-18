classdef UpdateOptionsVisitor <  curvefit.Handle & sftoolgui.fittypespec.FittypeSpecificationVisitor
    % UpdateOptionsVisitor This Visitor takes care of updating the fit
    % options correctly for a specification.  This requires knowing the
    % Java ID which is used to pick the correct fit and then passing the
    % fit option information to the Java FittypeModel
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(Access = private)
        TwoDFittypeModel
        ThreeDFittypeModel
    end
    
    methods
        function this = UpdateOptionsVisitor(twoDFittypeModel, threeDFittypeModel)
            this.TwoDFittypeModel = twoDFittypeModel;
            this.ThreeDFittypeModel = threeDFittypeModel;
        end
        
        function visitCustomNonLinearCurveSpecification(this, specification)
            iSetFitOptions( ...
                this.TwoDFittypeModel, ...
                specification, ...
                specification.Equation ...
                );
        end
        
        function visitLibrarySpecification(this, libraryCurveSpecification)
            iSetFitOptions(...
                this.TwoDFittypeModel, ...
                libraryCurveSpecification, ...
                iTranslateType(type(libraryCurveSpecification.Fittype)) ...
                );
        end
        
        function visitSmoothingSplineCurveSpecification(this, smoothingSplineCurveSpecification)
            iSetFitOptions(...
                this.TwoDFittypeModel, ...
                smoothingSplineCurveSpecification, ...
                'SmoothingSpline' ...
                );
        end
        
        function visitCustomLinearCurveSpecification(this, customLinearCurveSpecification)
            iSetFitOptions(...
                this.TwoDFittypeModel,  ...
                customLinearCurveSpecification, ...
                'CustomLinear' ...
                );
        end
        
        function visitInterpolantCurveSpecification(this, interpolantCurveSpecification)
            iSetFitOptions(...
                this.TwoDFittypeModel,  ...
                interpolantCurveSpecification, ...
                'Interpolant' ...
                );
        end
        
        function visitPolynomialSurfaceSpecification(this, polynomialSurfaceSpecification)
            iSetFitOptions(...
                this.ThreeDFittypeModel,  ...
                polynomialSurfaceSpecification, ...
                'Polynomial' ...
                );
        end
        
        function visitLowessSurfaceSpecification(this, lowessSurfaceSpecification)
            iSetFitOptions(...
                this.ThreeDFittypeModel,  ...
                lowessSurfaceSpecification, ...
                'Lowess' ...
                );
        end
        
        function visitCustomNonLinearSurfaceSpecification(this, specification)
            iSetFitOptions( ...
                this.ThreeDFittypeModel, ...
                specification, ...
                specification.Equation ...
                );
        end
        
        function visitInterpolantSurfaceSpecification(this, interpolantSurfaceSpecification)
            iSetFitOptions(...
                this.ThreeDFittypeModel,  ...
                interpolantSurfaceSpecification, ...
                'Interpolant' ...
                );
        end
    end
end


function iSetFitOptions(javaFittypeModel, specification, category)
% This function performs the update on the Java side
type = specification.Fittype;
options = specification.FitOptions;

if isprop(options, 'StartPoint')
    startpoint = options.StartPoint;
else
    startpoint = [];
end
if isprop(options, 'Lower')
    lower = options.Lower;
else
    lower = [];
end
if isprop(options, 'Upper')
    upper = options.Upper;
else
    upper = [];
end
javaMethodEDT('setCoefficientsTable', ...
    javaFittypeModel, ...
    category, ...
    iJavaStringArray(coeffnames(type)), ...
    startpoint, ...
    lower, ...
    upper ...
    );
end

function ft = iTranslateType(theType)

% Remove numbers from the string e.g. poly1 -> poly
theType = regexprep(theType, '[0-9]','');

map = curvefit.MapDefault.fromCellArray( {
    'exp',  'Exponential'
    'fourier',  'Fourier'
    'gauss',  'Gaussian'
    'poly',  'Polynomial'
    'power',  'Power'
    'rat', 'Rational'
    'sin', 'SumOfSine'
    'weibull', 'Weibull'
    }, ...
    'DefaultValue', '' ...
    );

ft = map.get(theType) ;
end

function aJavaArray = iJavaStringArray(matlabCellArray)
% Returns a java Array of Strings, this is necessary so that nulls are not
% passed to Java accidentally.  This method requires a cell array of
% strings as input

if isempty(matlabCellArray)
    aJavaArray = iEmptyJavaArray();
else
    aJavaArray = javaArray('java.lang.String', length(matlabCellArray));
    for ii = 1:length(aJavaArray)
        aJavaArray(ii) = java.lang.String(matlabCellArray{ii});
    end
end
end

function anEmptyJavaArray = iEmptyJavaArray()
arr = javaArray('java.lang.String', 1);
anEmptyJavaArray = java.util.Arrays.copyOf(arr, 0);
end
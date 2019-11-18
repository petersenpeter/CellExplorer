classdef UpdateGUIVisitor <  curvefit.Handle & sftoolgui.fittypespec.FittypeSpecificationVisitor
    % UpdateGUIVisitor is a visitor which is used to update a Swing
    % component.  Each FittypeSpecification implements an
    % accept(fittypeSpecificationVisitor) method and agrees to pass itself
    % to the appropriate method.  e.g. an SmoothingSplineCurveSpecification
    % will call visitSmoothingSplineCurveSpecification, by passing itself
    % as an argument.
    %
    % It is from this class that the Swing component may be updated.
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(Access = private)
        TwoDFittypeModel
        ThreeDFittypeModel
    end
    
    methods
        function this = UpdateGUIVisitor(twoDFittypeModel, threeDFittypeModel)
            this.TwoDFittypeModel = twoDFittypeModel;
            this.ThreeDFittypeModel = threeDFittypeModel;
        end
        
        function visitCustomNonLinearCurveSpecification(this, specification)
            % visitCustomNonLinearCurveSpecification   Visit a sftoolgui.fittypespec.CustomNonLinearCurveSpecification
            %
            % Update 2-d Fittype model based on custom non-linear specification.
            iSetCustomNonLinearCurveFittype( this.TwoDFittypeModel, specification );
        end
        
        function visitLibrarySpecification(this, libraryCurveSpecification)
            iSetFittype(...
                this.TwoDFittypeModel, ...
                libraryCurveSpecification ...
                );
        end
        
        function visitSmoothingSplineCurveSpecification(this, smoothingSplineCurveSpecification)
            iSetFittype(...
                this.TwoDFittypeModel, ...
                smoothingSplineCurveSpecification ...
                );
        end
        
        function visitCustomLinearCurveSpecification(this, customLinearCurveSpecification)
            iSetCustomLinearCurveFittype(...
                this.TwoDFittypeModel,  ...
                customLinearCurveSpecification ...
                );
        end
        
        function visitInterpolantCurveSpecification(this, interpolantCurveSpecification)
            iSetFittype(...
                this.TwoDFittypeModel,  ...
                interpolantCurveSpecification ...
                );
        end
        
        function visitPolynomialSurfaceSpecification(this, polynomialSurfaceSpecification)
            iSetFittype(...
                this.ThreeDFittypeModel,  ...
                polynomialSurfaceSpecification ...
                );
        end
        
        function visitLowessSurfaceSpecification(this, lowessSurfaceSpecification)
            iSetFittype(...
                this.ThreeDFittypeModel,  ...
                lowessSurfaceSpecification ...
                );
        end
        
        function visitCustomNonLinearSurfaceSpecification(this, specification)
            % visitCustomNonLinearSurfaceSpecification   Visit a sftoolgui.fittypespec.CustomNonLinearSurfaceSpecification
            %
            % Update 3-d Fittype model based on custom non-linear specification.
            iSetCustomNonLinearSurfaceFittype( this.ThreeDFittypeModel, specification );
        end
        
        function visitInterpolantSurfaceSpecification(this, interpolantSurfaceSpecification)
            iSetFittype(...
                this.ThreeDFittypeModel,  ...
                interpolantSurfaceSpecification ...
                );
        end
    end
end

function iSetCustomLinearCurveFittype(javaFittypeModel, specification)
% iSetCustomLinearCurveFittype calls the java FittypeModel setFittype
% method with all information that might need updating.
type = specification.Fittype;
options = specification.FitOptions;
linearTerms = specification.Terms;
linearCoefficients = specification.Coefficients;
dependentVariable = specification.DependentVariable;
independentVariable = specification.IndependentVariable;

javaMethodEDT('setFittype', javaFittypeModel, ...
    'CustomLinear', ...
    '', ...
    sftoolgui.util.javaNameValuePairs(type, options), ...
    iJavaStringArray(coeffnames(type)), ...
    iGetStartpoint(options), ...
    iGetLower(options), ...
    iGetUpper(options), ...
    iJavaString(dependentVariable), ...
    iJavaStringArray({independentVariable}), ...
    iJavaStringArray(linearCoefficients), ...
    iJavaStringArray(linearTerms));
end

function iSetCustomNonLinearCurveFittype(javaFittypeModel, specification)
% iSetCustomNonLinearCurveFittype calls the java FittypeModel setFittype
% method with all information that might need updating.
type = specification.Fittype;
options = specification.FitOptions;
customEquation = specification.Equation;
independentVariable = specification.IndependentVariable;
dependentVariable = specification.DependentVariable;

fittypeStr = sftoolgui.util.javaFittypeCategory(type, customEquation);
javaMethodEDT('setFittype', javaFittypeModel, ...
    fittypeStr, ...
    sftoolgui.util.getQualifier(type), ...
    sftoolgui.util.javaNameValuePairs(type, options), ...
    iJavaStringArray(coeffnames(type)), ...
    iGetStartpoint(options), ...
    iGetLower(options), ...
    iGetUpper(options), ...
    iJavaString(dependentVariable), ...
    iJavaStringArray({independentVariable}), ...
    iEmptyJavaArray(), ...
    iEmptyJavaArray());
end

function iSetCustomNonLinearSurfaceFittype(javaFittypeModel, specification)
% iSetCustomNonLinearSurfaceFittype calls the java FittypeModel setFittype
% method with all information that might need updating.
type = specification.Fittype;
options = specification.FitOptions;
customEquation = specification.Equation;
independentVariables = specification.IndependentVariables;
dependentVariable = specification.DependentVariable;

fittypeStr = sftoolgui.util.javaFittypeCategory(type, customEquation);
javaMethodEDT('setFittype', javaFittypeModel, ...
    fittypeStr, ...
    sftoolgui.util.getQualifier(type), ...
    sftoolgui.util.javaNameValuePairs(type, options), ...
    iJavaStringArray(coeffnames(type)), ...
    iGetStartpoint(options), ...
    iGetLower(options), ...
    iGetUpper(options), ...
    iJavaString(dependentVariable), ...
    iJavaStringArray(independentVariables), ...
    iEmptyJavaArray(), ...
    iEmptyJavaArray());
end

function iSetFittype(javaFittypeModel, specification)
% iSetFittype calls the java FittypeModel setFittype method with all
% information that might need updating.
type = specification.Fittype;
options = specification.FitOptions;

fittypeStr = sftoolgui.util.javaFittypeCategory(type, '');
javaMethodEDT('setFittype', javaFittypeModel, ...
    fittypeStr, ...
    sftoolgui.util.getQualifier(type), ...
    sftoolgui.util.javaNameValuePairs(type, options), ...
    iJavaStringArray(coeffnames(type)), ...
    iGetStartpoint(options), ...
    iGetLower(options), ...
    iGetUpper(options), ...
    iJavaString(dependnames(type)), ...
    iJavaStringArray(indepnames(type)), ...
    iEmptyJavaArray(), ...
    iEmptyJavaArray());
end

function javaString = iJavaString(matlabString)
% Returns a java String, this is necessary so that nulls are not passed to
% Java accidentally
javaString = java.lang.String(matlabString);
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

function sp = iGetStartpoint( options )
% Get the startpoint if it is defined.
if isprop(options, 'StartPoint')
    sp = options.StartPoint;
else
    sp = [];
end
end

function lb = iGetLower( options )
% Get the lower bounds if it is defined.
if isprop(options, 'Lower')
    lb = options.Lower;
else
    lb = [];
end
end

function ub = iGetUpper( options )
% Get the upper bounds if it is defined.
if isprop(options, 'Upper')
    ub = options.Upper;
else
    ub = [];
end
end

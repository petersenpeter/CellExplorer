classdef (Sealed) CustomLinearCurveSpecification < sftoolgui.fittypespec.FittypeSpecification
    % CustomLinearCurveSpecification builds custom linear curve data
    %
    % A CustomLinearCurveSpecification is built using an array which
    % represents the coefficients and the terms.
    %
    % Example:
    %
    % specification = sftoolgui.fittypespec.CustomLinearCurveSpecification(...
    %       {'a', 'c', 'd'}, ...
    %       {'x+1', 'x^2', 'sin(x)'}, ...
    %       sftoolgui.ImmutableCoefficientCache(), ...
    %       'x', 'y', ...
    %       );
    
    %   Copyright 2012-2013 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        Equation
        Coefficients
        Terms
        CoefficientOptions
        DependentVariable
        IndependentVariable
    end
    
    methods
        function this = CustomLinearCurveSpecification(linearCoefficients, linearTerms, coefficientOptions, independentVariable, dependentVariable)
            import sftoolgui.ImmutableCoefficientCache
            
            % We assume that the correct description is provided
            this.CoefficientOptions = ImmutableCoefficientCache(coefficientOptions);
            
            this.Coefficients = linearCoefficients;
            this.Terms = linearTerms;
            
            this.DependentVariable = dependentVariable;
            this.IndependentVariable = iGetIndependentVariable(independentVariable);
            
            this.build();
        end
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitCustomLinearCurveSpecification(this)
        end
    end
    
    methods(Access = protected)
        function fittypeString = getFittypeString(this)
            fittypeString = this.Equation;
        end
    end
    
    methods(Access = private)
        function build(this)
            % If the custom linear equation does not build then we populate
            % with a blank fit
            try
                this.Fittype = fittype(this.Terms, 'coefficients', this.Coefficients, 'independent', this.IndependentVariable, 'dependent', this.DependentVariable);
                this.FitOptions = sftoolgui.util.createFitOptions(this.Fittype, {}, this.CoefficientOptions);
                this.Equation = formula(this.Fittype);
                this.ErrorString = '';
            catch e
                this.Fittype = fittype();
                this.FitOptions = fitoptions('Method', 'LinearLeastSquares');
                this.Equation = '';
                this.ErrorString = e.message;
            end
            
        end
    end
end

function independent = iGetIndependentVariable(independent) 
if iscellstr(independent)
    independent = independent{1};
end
end

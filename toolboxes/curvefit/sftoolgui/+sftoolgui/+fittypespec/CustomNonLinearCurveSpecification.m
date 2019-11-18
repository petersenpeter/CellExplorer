classdef (Sealed) CustomNonLinearCurveSpecification < sftoolgui.fittypespec.FittypeSpecification
    % CustomNonLinearCurveSpecification builds custom general curve data
    
    %   Copyright 2012-2015 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        Equation
        OptionNameValuePairs
        CoefficientOptions
        IndependentVariable
        DependentVariable
    end
    
    methods
        function this = CustomNonLinearCurveSpecification(...
                expression, optionNameValuePairs, coefficientOptions, independent, dependent)
            import sftoolgui.ImmutableCoefficientCache
            
            this.Equation = expression;
            this.OptionNameValuePairs = optionNameValuePairs;
            this.CoefficientOptions = ImmutableCoefficientCache(coefficientOptions);
            this.IndependentVariable =  iGetIndependentVariable(independent);
            this.DependentVariable = dependent;
            this.build();
        end
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitCustomNonLinearCurveSpecification(this)
        end
    end
    
    methods(Access = protected)
        function fittypeString = getFittypeString(this)
            fittypeString = this.Equation;
        end
    end
    
    methods(Access = private)
        function build(this)
            [this.Fittype, this.ErrorString] = sftoolgui.fittypespec.nonlinearEquationFittype( ...
                this.Equation, ...
                {this.IndependentVariable}, ...
                this.DependentVariable );
            
            this.FitOptions = sftoolgui.util.createFitOptions(...
                this.Fittype, ...
                this.OptionNameValuePairs, ...
                this.CoefficientOptions);
        end
    end
end

function independent = iGetIndependentVariable(independent) 
if iscellstr(independent)
    independent = independent{1};
end
end

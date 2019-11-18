classdef (Sealed) CustomNonLinearSurfaceSpecification < sftoolgui.fittypespec.FittypeSpecification
    % CustomNonLinearSurfaceSpecification builds custom general surface data
    
    %   Copyright 2013-2015 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        Equation
        DependentVariable
        IndependentVariables
        OptionNameValuePairs
        CoefficientOptions
    end
    
    methods
        function this = CustomNonLinearSurfaceSpecification(...
                expression, optionNameValuePairs, coefficientOptions, independent, dependent)
            import sftoolgui.ImmutableCoefficientCache
            
            this.Equation = expression;
            this.OptionNameValuePairs = optionNameValuePairs;
            this.CoefficientOptions = ImmutableCoefficientCache(coefficientOptions);
            this.IndependentVariables = independent;
            this.DependentVariable = dependent;
            this.build();
        end
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitCustomNonLinearSurfaceSpecification(this)
        end
    end
    
    methods(Access = protected)
        function fittypeString = getFittypeString(this)
            fittypeString = this.Equation;
        end
    end
    
    methods(Access = private)
        function build(this)
            [this.Fittype, this.ErrorString] = iTranslateCustomInputs( ...
                this.Equation, ...
                this.IndependentVariables, ...
                this.DependentVariable);

            this.FitOptions = sftoolgui.util.createFitOptions(...
                this.Fittype, ...
                this.OptionNameValuePairs, ...
                this.CoefficientOptions);
        end
    end
end

function [ft, errorStr] = iTranslateCustomInputs( eqn, ind, dep )
[ft, errorStr] = sftoolgui.fittypespec.nonlinearEquationFittype( eqn, ind, dep );
end

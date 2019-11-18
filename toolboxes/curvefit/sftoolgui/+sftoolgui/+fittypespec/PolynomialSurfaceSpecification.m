classdef (Sealed) PolynomialSurfaceSpecification < sftoolgui.fittypespec.FittypeSpecification
    % PolynomialSurfaceSpecification builds a polynomial surface
    % specification 
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        Qualifier
        OptionNameValuePairs
        CoefficientOptions
    end
    
    methods
        function this = PolynomialSurfaceSpecification(qualifier, optionNameValuePairs, coefficientOptions)
            import sftoolgui.ImmutableCoefficientCache
            
            this.OptionNameValuePairs = optionNameValuePairs;
            this.Qualifier = qualifier;
            this.CoefficientOptions = ImmutableCoefficientCache(coefficientOptions);
            
            this.build();
        end
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitPolynomialSurfaceSpecification(this);
        end
    end
    
    methods(Access = private)
        function build(this)
            this.ErrorString = '';
            
            this.Fittype = fittype( sprintf( 'poly%s%s', this.Qualifier(1), this.Qualifier(2) ) );
            
            this.FitOptions = sftoolgui.util.createFitOptions(...
                this.Fittype, ...
                this.OptionNameValuePairs, ...
                this.CoefficientOptions);
        end
    end
end


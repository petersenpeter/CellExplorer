classdef (Sealed) LowessSurfaceSpecification  < sftoolgui.fittypespec.FittypeSpecification
    % LowessSurfaceSpecification builds a Lowess surface specification
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        Qualifier
        OptionNameValuePairs
        CoefficientCache
    end
    
    methods
        function this = LowessSurfaceSpecification(qualifier, optionNameValuePairs)
            this.Qualifier = qualifier;
            this.OptionNameValuePairs = optionNameValuePairs;
            this.ErrorString = '';
            this.build;
        end
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitLowessSurfaceSpecification(this);
        end
    end
    
    methods(Access = private)
        function build(this)
            switch this.Qualifier
                case 'linear'
                    this.Fittype = fittype( 'lowess' );
                case 'quadratic'
                    this.Fittype = fittype( 'loess' );
                otherwise
                    this.Fittype = fittype( 'lowess' );
                    warning(message('curvefit:sftoolgui:util:createNewSurfaceSpecification:unknownPolynomial', this.Qualifier));
            end
            
            this.FitOptions = sftoolgui.util.createFitOptions(...
                this.Fittype, ...
                this.OptionNameValuePairs, ...
                sftoolgui.ImmutableCoefficientCache);
        end
    end
    
end


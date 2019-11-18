classdef (Sealed) LibraryCurveSpecification < sftoolgui.fittypespec.FittypeSpecification
    % LibraryCurveSpecification builds parametric curves
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = private)
        Qualifier
        Model
        CoefficientOptions
        OptionNameValuePairs
    end
    
    methods
        function this = LibraryCurveSpecification(model, qualifier, optionNameValuePairs, coefficientOptions)
            import sftoolgui.ImmutableCoefficientCache
            
            this.Model = model;
            this.Qualifier = qualifier;
            this.OptionNameValuePairs = optionNameValuePairs;
            this.CoefficientOptions = ImmutableCoefficientCache(coefficientOptions);
            this.build();
        end
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitLibrarySpecification(this);
        end
    end
    
    methods(Access = private)
        function build(this)
            model = this.Model;
            qualifier = this.Qualifier;
            
            % Attempt to create a fit type with the given model and
            % qualifiers
            try
                this.Fittype = fittype( sprintf( '%s%s', model, qualifier ));
            catch %#ok<CTCH>
                warning(message('curvefit:sftoolgui:util:CreateNewCurveSpecification:UnknownNonLinearParametricFittype', model, qualifier));
                this.Fittype = fittype('poly1');
            end
            
            this.FitOptions = sftoolgui.util.createFitOptions(...
                this.Fittype, ...
                this.OptionNameValuePairs, ...
                this.CoefficientOptions);
            
            this.ErrorString = '';
        end
    end
end


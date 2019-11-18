classdef (Sealed) SmoothingSplineCurveSpecification < sftoolgui.fittypespec.FittypeSpecification
    % SmoothingSplineCurveSpecification builds spline curve data
    
    %   Copyright 2012-2013 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = private)
        OptionNameValuePairs
    end
    
    methods
        function this = SmoothingSplineCurveSpecification(optionNameValuePairs)
            this.OptionNameValuePairs = optionNameValuePairs;
            this.build();
        end 
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitSmoothingSplineCurveSpecification(this);
        end
    end
    
    methods(Access = private)
        function build(this)
            this.Fittype = fittype( 'smoothingspline' );
            
            this.FitOptions = sftoolgui.util.createFitOptions(...
                this.Fittype, ...
                this.OptionNameValuePairs, ...
                sftoolgui.ImmutableCoefficientCache ...
                );
            
            this.ErrorString = '';
        end
    end
end


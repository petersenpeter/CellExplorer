classdef (Sealed) InterpolantCurveSpecification < sftoolgui.fittypespec.FittypeSpecification
    % InterpolantCurveSpecification builds Interpolant curve data
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = private)
        Qualifier
        OptionNameValuePairs
    end
    
    methods
        function this = InterpolantCurveSpecification(qualifier, optionNameValuePairs)
            this.Qualifier = qualifier;
            this.OptionNameValuePairs = optionNameValuePairs;
            this.build();
        end
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitInterpolantCurveSpecification(this);
        end
    end
    
    methods(Access = private)
        function build(this)
            keys =   {'cubic',       'nearest',       'linear',       'PCHIP'};
            values = {'splineinterp', 'nearestinterp', 'linearinterp', 'pchipinterp'};
            map = curvefit.MapDefault( ...
                'Keys', keys, ...
                'Values', values, ...
                'DefaultValue', 'linearinterp', ...
                'WarningID', 'curvefit:sftoolgui:util:CreateNewCurveSpecification:UnknownInterpolantFittype', ...
                'WarningArguments', {this.Qualifier} ...
                );

            this.Fittype = fittype( map.get(this.Qualifier) );
            
            this.FitOptions = sftoolgui.util.createFitOptions(this.Fittype, this.OptionNameValuePairs, sftoolgui.ImmutableCoefficientCache);
            
            this.ErrorString = '';
        end
    end
    
end


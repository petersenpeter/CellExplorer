classdef (Sealed) InterpolantSurfaceSpecification < sftoolgui.fittypespec.FittypeSpecification
    % InterpolantSurfaceSpecification builds an interpolant surface
    % specification
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        Qualifier
        OptionNameValuePairs
    end
    
    methods 
        function this = InterpolantSurfaceSpecification(qualifier, optionNameValuePairs)
            this.Qualifier = qualifier;
            this.OptionNameValuePairs = optionNameValuePairs;
            
            this.build;
        end
    end
    
    methods(Access = public)
        function accept(this, fittypeSpecificationVisitor)
            fittypeSpecificationVisitor.visitInterpolantSurfaceSpecification(this)
        end
    end
    
    methods(Access = private)
        function build(this)
            this.ErrorString = '';
            
            keys =   {'cubic',       'nearest',       'linear',       'v4',               'thinplate', };
            values = {'cubicinterp', 'nearestinterp', 'linearinterp', 'biharmonicinterp', 'thinplateinterp'};
            map = curvefit.MapDefault( ...
                'Keys', keys, ...
                'Values', values, ...
                'DefaultValue', 'linearinterp', ...
                'WarningID', 'curvefit:sftoolgui:util:createNewSurfaceSpecification:TranslationError', ...
                'WarningArguments', {this.Qualifier} ...
                );
            
            this.Fittype = fittype( map.get(this.Qualifier), 'numindep', 2 );
            
            this.FitOptions = sftoolgui.util.createFitOptions(...
                this.Fittype, ...
                this.OptionNameValuePairs, ...
                sftoolgui.ImmutableCoefficientCache);
        end
        
    end
    
end



classdef PredictablePlotCodeGenerator < sftoolgui.codegen.PlotCodeGenerator
    % PredictablePlotCodeGenerator   Abstract class for PlotCodeGenerator
    % classes that support display of prediction bounds.

    %   Copyright 2011-2012 The MathWorks, Inc.

    properties(Dependent)
        % DoPredictionBounds -- boolean
        %   Set to true to include code for plotting prediction bounds
        DoPredictionBounds;
        
        % PredictionLevel -- scalar \in (0, 1.0)
        %   The prediction level for the surface
        PredictionLevel
    end
    
    properties(Access = protected)
        % PrivateDoPredictionBounds   Private storage of DoPredictionBounds
        PrivateDoPredictionBounds = false;
        
        % PrivatePredictionLevel   Private storage of PredictionLevel
        PrivatePredictionLevel = iDefaultPredictionLevel()
    end
    
    methods
        function obj = set.DoPredictionBounds( obj, tf )
            obj.PrivateDoPredictionBounds = tf;
            obj = updatePlotStyleArgs( obj );
        end
        function tf = get.DoPredictionBounds( obj )
            tf = obj.PrivateDoPredictionBounds;
        end
        
        function obj = set.PredictionLevel( obj, level )
            obj.PrivatePredictionLevel = level;
            obj = updatePlotStyleArgs( obj );
        end
        function level = get.PredictionLevel( obj )
            level = obj.PrivatePredictionLevel;
        end
    end
    
    methods(Access = private)
        function obj = updatePlotStyleArgs( obj )
            % If we are doing prediction bounds then we need to set the style
            % appropriately.
            if obj.PrivateDoPredictionBounds
                if obj.PrivatePredictionLevel == iDefaultPredictionLevel()
                    styleArguments = getDefaultPredictionStyle( obj );
                else
                    styleArguments = getCustomPredictionStyle( obj );
                end
            else
                styleArguments = {};
            end
            
            obj.PlotCommandGenerator.StyleArguments = styleArguments;
        end
    end
    
    methods( Abstract, Access = protected )
        str = getDefaultPredictionStyle( obj )
        str = getCustomPredictionStyle( obj )
    end
end

function level = iDefaultPredictionLevel()
% iDefaultPredictionLevel -- The default value for the prediction interval level
defaultPredictionOpts = curvefit.PredictionIntervalOptions;
level = defaultPredictionOpts.Level;
end

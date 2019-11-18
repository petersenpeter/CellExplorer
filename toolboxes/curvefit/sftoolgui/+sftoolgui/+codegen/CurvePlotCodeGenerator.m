classdef CurvePlotCodeGenerator < sftoolgui.codegen.PredictablePlotCodeGenerator
    % CURVEPLOTCODEGENERATOR   Class for generating code for curve plots
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    properties
        % HasXData -- boolean
        %   Set to true when generating code for a fit that has x-data defined.
        HasXData = true;
    end
    
    methods
        function cg = CurvePlotCodeGenerator()
            cg.PlotCommandGenerator = sftoolgui.codegen.CfitPlotCommandGenerator();
        end
    end
    
    methods( Access = protected )
        function str = getDefaultPredictionStyle( ~ )
            str = {'''predobs'''};
        end
        function cellstr = getCustomPredictionStyle( obj )
            cellstr = {'''predobs''', num2str( obj.PredictionLevel )};
        end
        
        function addAxesLabels( cg, mcode )
            % addAxesLabels   Add commands for axes labels to generated code.
            %
            %   addAxesLabels( obj, mcode )
            acg = sftoolgui.codegen.CurveAxesLabelCodeGenerator();
            acg.HasXData = cg.HasXData;
            generateCode( acg, mcode );
        end
        
        function addValidationPlotCommand( cg, mcode )
            % addValidationPlotCommand -- Add code for validation plot
            if cg.HaveLegend,
                rhs = {'<h>(end+1)'};
            else
                rhs = {};
            end
            
            mcode.addFunctionCall( rhs{:}, '=', 'plot', ...
                '<validation-x>', '<validation-y>', ...
                '''bo''', '''MarkerFaceColor''', '''w''' );
        end
        
        function addLegendCommand( cg, mcode )
            if cg.HaveLegend
                lcg = sftoolgui.codegen.LegendCommandGenerator();
                
                % The legend command need to always start with the data
                % name
                lcg.addName( cg.SafeFittingDataName );
                
                % The next name is the optional excluded data
                if cg.HaveExcludedData
                    lcg.addName( cg.ExcludedDataName );
                end
                
                % The name of the fit always comes next
                lcg.addName( cg.SafeFitName );
                
                % If there are prediction bounds, then they are next.
                if cg.DoPredictionBounds
                    lcg.addName( getString(message('curvefit:sftoolgui:LowerBounds', cg.SafeFitName )) );
                    lcg.addName( getString(message('curvefit:sftoolgui:UpperBounds', cg.SafeFitName )) );
                end
                
                % The last name is the validation data, if there is any
                if cg.HaveValidation
                    lcg.addName( cg.SafeValidationDataName );
                end
                
                % Add the command to the mcode                
                addCommand( lcg, mcode );
            end
        end
    end
end

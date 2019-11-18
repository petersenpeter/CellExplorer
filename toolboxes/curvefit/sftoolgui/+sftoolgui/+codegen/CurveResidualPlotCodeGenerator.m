classdef CurveResidualPlotCodeGenerator < sftoolgui.codegen.ResidualPlotCodeGenerator
    % CurveResidualPlotCodeGenerator   Class for generating code for
    %   residual plots of curve fits
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
        properties
            % HasXData -- boolean
            %   Set to true when generating code for a fit that has x-data defined.
            HasXData = true;
        end
    
    methods
        function cg = CurveResidualPlotCodeGenerator()
            cg.PlotCommandGenerator = sftoolgui.codegen.CfitPlotCommandGenerator();
            cg.PlotCommandGenerator.StyleArguments = {'''residuals'''};
        end
    end
    
    methods( Access = protected )
        function cellstr = getValidationPlotRHS( ~ )
            % getValidationPlotRHS   The RHS of the command to plot validation
            % data
            cellstr = {'plot', '<validation-x>', '<validation-y> - <fo>( <validation-x> )', ...
                '''bo''', '''MarkerFaceColor''', '''w'''};
        end
        
        function addAxesLabels( cg, mcode )
            % addAxesLabels   Add commands for axes labels to generated code.
            %
            %   addAxesLabels( obj, mcode )
            acg = sftoolgui.codegen.CurveAxesLabelCodeGenerator();
            acg.HasXData = cg.HasXData;
            generateCode( acg, mcode );
        end
        
        function addLegendCommand( cg, mcode )
            % addLegendCommand -- Add the legend command to the generated code
            % if we have a legend
            if cg.HaveLegend
                lcg = sftoolgui.codegen.LegendCommandGenerator();
                
                residualsName = getString(message('curvefit:sftoolgui:Residuals', cg.SafeFitName ));
                validationName = getString(message('curvefit:sftoolgui:ValidationResiduals', cg.SafeFitName ));
                
                % The names in the legend command always start with the
                % name of the residuals
                lcg.addName( residualsName );
                
                % The next name is the optional excluded data
                if cg.HaveExcludedData
                    lcg.addName( cg.ExcludedDataName );
                end
                
                % The residual plot has a zero line and that comes next
                lcg.addName( 'Zero Line' );
                
                % The last name is the validation data, if there is any
                if cg.HaveValidation
                    lcg.addName( validationName );
                end
                
                % Add the command to the mcode
                addCommand( lcg, mcode );
            end
        end
    end
end

classdef ContourPlotCodeGenerator < sftoolgui.codegen.PlotCodeGenerator
    %CONTOURPLOTCODEGENERATOR   Class for generating code for contour plots
    
    %   Copyright 2009-2014 The MathWorks, Inc.
    
    methods
        function obj = ContourPlotCodeGenerator()
            obj.PlotCommandGenerator = sftoolgui.codegen.SfitPlotCommandGenerator();
            obj.PlotCommandGenerator.StyleArguments = {'''Style''', '''Contour'''};
        end
    end
    
    methods(Access = protected)
        function addAxesLabels( ~, mcode )
            addFitComment( mcode, getString(message('curvefit:sftoolgui:LabelAxes')) );
            addCommandCall( mcode, 'xlabel', '<x-name>' );
            addCommandCall( mcode, 'ylabel', '<y-name>' );
        end
        
        function addValidationPlotCommand( obj, mcode )
            % addValidationPlotCommand -- Add code for validation plot
            if obj.HaveLegend,
                rhs = {'<h>(end+1)'};
            else
                rhs = {};
            end
            
            mcode.addFunctionCall( rhs{:}, '=', 'plot', ...
                '<validation-x>', '<validation-y>', ...
                '''bo''', '''MarkerFaceColor''', '''w''' );
        end
        
        function addLegendCommand( obj, mcode )
            % addLegendCommand -- Add the legend command to the generated code
            % if we have a legend
            if obj.HaveLegend
                lcg = sftoolgui.codegen.LegendCommandGenerator();

                % The first names on the legend are the fit name and the
                % fitting data name
                lcg.addName( obj.SafeFitName );
                lcg.addName( obj.SafeFittingDataName );
                
                % If there are exclusions, then they come next
                if obj.HaveExcludedData
                    lcg.addName( obj.ExcludedDataName );
                end

                % If there is validation data, then that comes last
                if obj.HaveValidation
                    lcg.addName( obj.SafeValidationDataName );
                end
                
                addCommand( lcg, mcode  );
            end
        end

    end
end

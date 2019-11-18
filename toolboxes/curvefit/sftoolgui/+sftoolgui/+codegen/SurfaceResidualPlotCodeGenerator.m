classdef SurfaceResidualPlotCodeGenerator < sftoolgui.codegen.ResidualPlotCodeGenerator
    %SURFACERESIDUALPLOTCODEGENERATOR   Class for generating code for residual plots
    
    %   Copyright 2009-2012 The MathWorks, Inc.
    
    properties
        % View -- 1-by-2 vector -- view angle
        %   The angle for the view from which the observer sees the plot.
        %
        %   See also: VIEW
        View = iDefaultView;
    end
    
    methods
        function obj = SurfaceResidualPlotCodeGenerator()
            obj.PlotCommandGenerator = sftoolgui.codegen.SfitPlotCommandGenerator();
            obj.PlotCommandGenerator.StyleArguments = {'''Style''', '''Residual'''};
        end
    end
    
    methods(Access = protected)
        function addViewCode( obj, mcode )
            % addViewCode -- Adds code to set the view.
            %   Only display the view command if the view differs from the
            %   default 3D view.
            if any( obj.View ~= iDefaultView() )
                azimuth = sprintf( '%.1f', obj.View(1) );
                elevation = sprintf( '%.1f', obj.View(2) );
                addFunctionCall( mcode, 'view', azimuth, elevation );
            end
        end
        
        function cellstr = getValidationPlotRHS( ~ )
            % getValidationPlotRHS   The RHS of the command to plot validation
            % data
            cellstr = {'plot3', '<validation-x>', '<validation-y>', ...
                '<validation-z> - <fo>( <validation-x>, <validation-y> )', ...
                '''bo''', '''MarkerFaceColor''', '''w'''};
        end
        
        function addLegendCommand( cg, mcode )
            % addLegendCommand   Add the legend command to the generated code
            % if we have a legend
            if cg.HaveLegend
                lcg = sftoolgui.codegen.LegendCommandGenerator();
                
                residualsName = getString(message('curvefit:sftoolgui:Residuals', cg.SafeFitName ));
                validationName = getString(message('curvefit:sftoolgui:ValidationResiduals', cg.SafeFitName ));
                excludedName = getString(message('curvefit:sftoolgui:DisplayNameExcluded', cg.SafeFittingDataName ));
                
                % The names in the legend command always start with the
                % name of the residuals
                lcg.addName( residualsName );
                
                % The next name is the optional excluded data
                if cg.HaveExcludedData
                    lcg.addName( excludedName );
                end
                
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

function ae = iDefaultView()
% iDefaultView -- The default view angle for 3D plots
ae = [-37.5, 30];
end

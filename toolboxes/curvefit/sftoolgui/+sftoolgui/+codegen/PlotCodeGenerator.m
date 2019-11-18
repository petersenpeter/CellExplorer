classdef PlotCodeGenerator < curvefit.Handle
    %PLOTCODEGENERATOR   Base class for plot code generators
    
    %   Copyright 2009-2014 The MathWorks, Inc.
    
    properties
        % FitName -- string
        %   Name of the fit to be used in the legend
        FitName = getString(message('curvefit:sftoolgui:MyFit1'));
        
        % FittingDataName -- string
        %   Name of the fitting data to be used in the legend
        FittingDataName = 'z vs. x, y';
        
        % ValidationDataName -- string
        %   Name of the validation data to be used in the legend
        ValidationDataName = 'zv vs. xv, yv';
        
        % HaveValidation -- boolean
        %   Set to true when there is validation data that should be plotted.
        HaveValidation = false;
        
        % GridState -- 'on' or 'off'
        %   Indicates that the grid should or should not be plotted
        GridState = 'on';
        
        % HaveLegend -- boolean
        %   Set to true when code for a legend should be generated.
        HaveLegend = false;
        
        % HaveExcludedData -- boolean
        %   Set to true when there is excluded data
        HaveExcludedData = false;
    end
    properties(SetAccess = protected, GetAccess = protected)
        % PlotCommandGenerator -- AbstractPlotCommandGenerator
        PlotCommandGenerator = [];
    end
    properties(SetAccess = private, GetAccess = protected, Dependent)
        % SafeFitName -- string
        %   A "safe" version of obj.FitName. This is safe in the sense that in
        %   can be inserted into code with out causing syntax errors. For
        %   example, any quotes (') in obj.FitName will be replaced bu double
        %   quotes ('').
        SafeFitName
        
        % SafeFittingDataName -- string
        %   A "safe" version of obj.FittingDataName.
        SafeFittingDataName
        
        % SafeFittingDataName -- string
        %   A "safe" version of obj.ValidationDataName.
        SafeValidationDataName
        
        % ExcludedDataName -- string
        %   Name of any excluded data
        ExcludedDataName
    end
    
    methods
        function name = get.SafeFitName( obj )
            name = sftoolgui.codegen.stringLiteral( obj.FitName );
        end
        function name = get.SafeFittingDataName( obj )
            name = sftoolgui.codegen.stringLiteral( obj.FittingDataName );
        end
        function name = get.SafeValidationDataName( obj )
            name = sftoolgui.codegen.stringLiteral( obj.ValidationDataName );
        end
        function name = get.ExcludedDataName( obj )
            name = getString(message('curvefit:sftoolgui:DisplayNameExcluded', obj.SafeFittingDataName));
        end
        
        function obj = PlotCodeGenerator()
            obj.PlotCommandGenerator = sftoolgui.codegen.SfitPlotCommandGenerator();
        end
    end

    methods( Sealed )
        function generateMCode( obj, mcode )
            % generateMCode -- Generate MATLAB code and add it to the given
            %   sftoolgui.codegen.MCode object.
            
            % Register a handle for the legend?
            addLegendVariable( obj, mcode )
            % Plot command
            addPlotCommand( obj, mcode );
            % Plot Validation Data?
            addValidationPlotBlock( obj, mcode )
            % Add a Legend?
            addLegendCommand( obj, mcode )
            % Axes labels
            addAxesLabels( obj, mcode );
            % Grid?
            addGridCommand( obj, mcode );
            % View
            addViewCode( obj, mcode );
        end
    end

    methods(Access = private)
        function addLegendVariable( obj, mcode )
            if obj.HaveLegend
                addVariable( mcode, '<h>', 'h' );
            end
        end
        
        function addPlotCommand( obj, mcode )
            % addPlotCommand -- Add the main plot command to the generated code.
            pcg = obj.PlotCommandGenerator;
            
            % If we have a legend then we need a LHS from the plot command
            pcg.HaveLHS = obj.HaveLegend;
            
            pcg.HaveValidation = obj.HaveValidation;
            pcg.HaveExcludedData = obj.HaveExcludedData;
            
            addPlotCommand( pcg, mcode );
        end
        
        function addValidationPlotBlock( obj, mcode )
            % addValidationPlotBlock -- Add a block of code that plots
            % validation data.
            %
            %   To change the style of the plot for a subclass, overload the
            %   "addValidationPlotCommand" method.
            %
            %   See also addValidationPlotCommand.
            if obj.HaveValidation
                mcode.addFitComment( getString(message('curvefit:sftoolgui:AddValidationDataToPlot')) );
                mcode.addCommandCall( 'hold', 'on' );
                addValidationPlotCommand( obj, mcode );
                mcode.addCommandCall( 'hold', 'off' );
            end
        end
                
        function addGridCommand( obj, mcode )
            % addGridCommand -- Add the GRID command to the generated code
            mcode.addCommandCall( 'grid', obj.GridState ); 
        end
    end
    
    methods(Abstract, Access = protected)
        % addValidationPlotCommand -- Overload this method to change the
        % plot command for validation data.
        addValidationPlotCommand( obj, mcode )
        
        % addLegendCommand -- Add the legend command to the generated code
        % if we have a legend
        addLegendCommand( obj, mcode )
    end
    methods(Access = protected)
        function addAxesLabels( ~, mcode )
            % addAxesLabels -- Overload this method to set the axes labels.
            %   By Default the labels of the x-, y- and z-axes are set to be the
            %   same name as the corresponding fitting variable.
            %
            %   >> addAxesLabels( obj, mcode )
            addFitComment( mcode, getString(message('curvefit:sftoolgui:LabelAxes')) );
            addCommandCall( mcode, 'xlabel', '<x-name>' );
            addCommandCall( mcode, 'ylabel', '<y-name>' );
            addCommandCall( mcode, 'zlabel', '<z-name>' );
        end
        
        function addViewCode( ~, ~ )
            % addViewCode -- Overload this method to add code to set the view.
            %   By Default, no view code is added
            %
            %   >> addViewCode( obj, mcode );
        end
    end
end

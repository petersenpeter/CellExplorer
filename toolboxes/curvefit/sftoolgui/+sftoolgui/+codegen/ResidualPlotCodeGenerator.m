classdef ResidualPlotCodeGenerator < sftoolgui.codegen.PlotCodeGenerator
    %RESIDUALPLOTCODEGENERATOR   Class for generating code for residual plots
    
    %   Copyright 2009-2012 The MathWorks, Inc.
    
    methods(Sealed, Access = protected)
        function addValidationPlotCommand( obj, mcode )
            
            % If we have a legend, then we need to catch the handle to the
            % validation line in the LHS (left hand side) of the command.
            if obj.HaveLegend
                lhs = {'<h>(end+1)'};
            else
                lhs = {};
            end
            
            % The fit code is just the concatenation of the LHS and the RHS
            rhs = getValidationPlotRHS( obj );
            addFunctionCall( mcode, lhs{:}, '=', rhs{:} );
        end
    end
    
    methods( Abstract, Access = protected )
        % getValidationPlotRHS   The RHS of the command to plot validation
        % data
        %
        % Sub-classes need to overload this method and use it to the define
        % the RHS (right hand side) of the command used to plot validation
        % data. It should return a cell-string. The first element of the cell-string
        % should be the name of the function to plot validation. The remaining elements
        % should be the arguments to pass to the function.
        cellstr = getValidationPlotRHS( obj )
    end
end

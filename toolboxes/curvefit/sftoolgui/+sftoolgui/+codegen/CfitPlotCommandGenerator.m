classdef( Sealed ) CfitPlotCommandGenerator < sftoolgui.codegen.AbstractPlotCommandGenerator
    % CfitPlotCommandGenerator   A class for generating code to call the
    % plot method of CFIT

    %   Copyright 2011-2012 The MathWorks, Inc.

    methods
        function addPlotCommand( cg, mcode )
            % addPlotCommand   Add the command for plotting CFIT objects to
            % the generated code.
            
            if cg.HaveLHS
                lhs = {'<h>'};
            else
                lhs = {};
            end
            
            if cg.HaveExcludedData
                ex = {'<ex>'};
            else
                ex = {};
            end
            
            addFunctionCall( mcode, lhs{:}, '=', ...
                'plot', '<fo>', '<x-input>', '<y-input>', ...
                ex{:}, cg.StyleArguments{:} );
        end
    end
end

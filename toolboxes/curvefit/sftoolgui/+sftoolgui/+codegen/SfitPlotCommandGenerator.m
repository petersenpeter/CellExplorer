classdef( Sealed ) SfitPlotCommandGenerator < sftoolgui.codegen.AbstractPlotCommandGenerator
    % SfitPlotCommandGenerator   A class for generating code to call the
    % plot method of SFIT

    %   Copyright 2011-2012 The MathWorks, Inc.

    methods
        function addPlotCommand( cg, mcode )
            % addSfitPlotCommand -- Add the command for plotting SFIT
            % objects to the generated code. 
            % 
            %   In subclasses, to overload the style of the plot set the
            %   "PlotStyleArgs" property to an appropriate value.
            %
            %   See also: PlotStyleArgs
            if cg.HaveValidation
                limitArgs = {'''XLim''', '<xlim>', '''YLim''', '<ylim>'};
            else
                limitArgs = {};
            end
            
            if cg.HaveExcludedData
                excludeArgs = {'''Exclude''', '<ex>'};
            else
                excludeArgs = {};
            end
            
            if cg.HaveLHS
                plotReturnArg = {'<h>'};
            else
                plotReturnArg = {};
            end

            mcode.addFunctionCall( plotReturnArg{:}, '=', ...
                'plot', '<fo>', '[<x-input>, <y-input>]', '<z-output>', ...
                cg.StyleArguments{:}, excludeArgs{:}, limitArgs{:} );
        end
    end
end

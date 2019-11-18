classdef( Sealed ) LegendCommandGenerator < curvefit.Handle
    % LegendCommandGenerator   A class to generate code for legend commands
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    properties( SetAccess = private )
        % Names   Names of objects that will be displayed in the legend.
        Names = {}
    end
    
    methods
        function addName( cg, name )
            % addName   Adds a name to a LegendCommandGenerator
            %
            % Note that the order that the names are added is the order
            % that they will be displayed in the legend command
            cg.Names{end+1} = name;
        end
        
        function addCommand( cg, mcode )
            % addCommand   Add MATLAB code for a legend to the given 
            %   sftoolgui.codegen.MCode object.
            
            % Put quotes around the names of the various graphics
            quotedNames = cellfun( @(c) sprintf( '''%s''', c ), cg.Names, 'UniformOutput', false );
            
            mcode.addFunctionCall( 'legend', '<h>', quotedNames{:}, '''Location''', '''NorthEast''' );
        end
    end
end

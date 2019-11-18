classdef( Sealed ) FitOptionsCodeGeneratorFactory < curvefit.Handle
    % FitOptionsCodeGeneratorFactory   Factory for Fit Options code generators
    
    %   Copyright 2012 The MathWorks, Inc.
    
    methods
        function focg = create( ~, options )
            % create   Create a fit options code generator for a given set of fit options.
            %
            % Syntax:
            %   factory = sftoolgui.codegen.FitOptionsFactory();
            %   focg = factory.create( options );
            
            if iIsDefaultFitOptions( options )
                focg = sftoolgui.codegen.FitOptionsArguments( options );
                
            elseif isequal( options.Method, 'None' )
                focg = sftoolgui.codegen.FitOptionsArguments( options );
                
            else
                focg = sftoolgui.codegen.FitOptionsObjectCode( options );
            end
        end
    end
end

function tf = iIsDefaultFitOptions( aFitOptions )
% iIsDefaultFitOptions   True if given fit options have default values (ignoring
% Normalize).

defaultOptions = fitoptions( 'Method', aFitOptions.Method );

% Two sets of fit options are the same if all corresponding properties have the
% same value.
fields = fieldnames( aFitOptions );

tf = true;
for i = 1:length( fields )
    thisField = fields{i};
    
    switch thisField
        case 'Normalize'
            % Ignore
            thisIsEqual = true;
        case 'Exclude'
            thisIsEqual = isempty( aFitOptions.Exclude ) || ~any( aFitOptions.Exclude );
        case 'Lower'
            thisIsEqual = isempty( aFitOptions.Lower ) || all( aFitOptions.Lower == -Inf );
        case 'Upper'
            thisIsEqual = isempty( aFitOptions.Upper ) || all( aFitOptions.Upper == Inf );
        case 'Weights'
            thisIsEqual = isempty( aFitOptions.Weights );
        otherwise
            thisIsEqual = isequal( aFitOptions.(thisField), defaultOptions.(thisField) ); 
    end
    
    tf = tf && thisIsEqual;
end
end


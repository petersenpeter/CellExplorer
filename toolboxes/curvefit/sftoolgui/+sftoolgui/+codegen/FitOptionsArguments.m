classdef( Sealed ) FitOptionsArguments < sftoolgui.codegen.FitOptionsCodeGenerator
    % FitOptionsArguments   Generate code for Fit Options as arguments to FIT
    % function.
    
    %   Copyright 2012 The MathWorks, Inc.
    
    properties(Access = private)
        % PrivateExtraFitArguments   Cell-array of strings of "extra arguments" that
        % should be passed to the FIT function in generated code.
        PrivateExtraFitArguments = {};
    end
    
    methods(Access = 'protected')
        function arguments = getExtraFitArguments( this )
            % getExtraFitArguments   Implementation of get method for ExtraFitArguments
            % property
            arguments = this.PrivateExtraFitArguments;
        end
    end
    
    methods
        function this = FitOptionsArguments( aFitOptions )
            % FitOptionsArguments   Construct fir options code generator for fit options
            %
            % Syntax:
            %   focg = sftoolgui.codegen.FitOptionsArguments( aFitOptions )
            %
            % See also: fitoptions, curvefit.basefitoptions
            this.addFitOptionsAsParameterValues( aFitOptions );
        end
        
        function addParameterValue( this, parameter, value )
            % addParameterValue   Add a parameter-value pair to the list of Fit Options to
            % generate code generated.
            this.PrivateExtraFitArguments = [this.ExtraFitArguments, ...
                {iQuoteString( parameter ), mat2str( value )}];
        end
        
        function addParameterToken( this, parameter, token )
            % addParameterToken   Add a parameter-value pair where the value is a variable token.
            %
            % The parameter-value pair will be added to the list of Fit Options to generate
            % code generated.
            this.PrivateExtraFitArguments = [this.ExtraFitArguments, ...
                {iQuoteString( parameter ), token}];
        end
        
        function generateSetupCode( ~, ~ )
            % generateSetupCode   Generate the code required to setup a Fit Options object.
            %
            % Syntax:
            %     generateSetupCode( this, mcode )
            %
            % See also: sftoolgui.codegen.MCode
        end
    end
end

function b = iQuoteString( a )
% iQuoteString   Put quotes around a string
b = ['''', a, ''''];
end

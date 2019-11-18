classdef( Sealed ) FitOptionsObjectCode < sftoolgui.codegen.FitOptionsCodeGenerator
    % FitOptionsObjectCode   Generate code for a Fit Options object.
    
    %   Copyright 2012 The MathWorks, Inc.
    
    properties(Access = private)
        % Method   Name of the method to generate fit options code for (string)
        Method = '';
        
        % Parameters   List of parameter names to generates code for (cell-string)
        Parameters = {};
        
        % Values   List of parameter values to generate code for (cell array)
        Values = {};
    end
    
    methods(Access = 'protected')
        function arguments = getExtraFitArguments( ~ )
            % getExtraFitArguments   Implementation of get method for ExtraFitArguments
            % property
            arguments = {'<opts>'};
        end
    end
    
    methods
        function this = FitOptionsObjectCode( aFitOptions )
            % FitOptionsObjectCode   Generate code for Fit Options
            %
            % Syntax:
            %     FitOptionsCodeGenerator( aFitOptions )
            %
            % See also: fitoptions, curvefit.basefitoptions
            this.Method = aFitOptions.Method;
            this.addFitOptionsAsParameterValues( aFitOptions );
        end
        
        function addParameterValue( this, parameter, value )
            % addParameterValue   Add a parameter-value pair to the list of Fit Options to
            % generate code generated.
            %
            % Syntax:
            %     focg.addParameterValue( parameter, value )
            this.Parameters{end+1} = parameter;
            this.Values{end+1} = mat2str( value );
        end
        
        function addParameterToken( this, parameter, token )
            % addParameterToken   Add a parameter-value pair where the value is a variable token.
            %
            % The parameter-value pair will be added to the list of Fit Options to generate
            % code generated.
            this.Parameters{end+1} = parameter;
            this.Values{end+1} = token;
        end
        
        function generateSetupCode( this, mcode )
            % generateSetupCode   Generate the code required to setup a Fit Options object.
            %
            % Syntax:
            %     focg.generateSetupCode( mcode )
            %
            % See also: sftoolgui.codegen.MCode
            mcode.addVariable( '<opts>', 'opts' );
            mcode.addFunctionCall( '<opts>', '=', 'fitoptions', '''Method''', ...
                mat2str( this.Method ) );
            
            for i = 1:length( this.Parameters )
                iGenerateCodeForParameter( mcode, this.Parameters{i}, this.Values{i} );
            end
        end
    end
end

function iGenerateCodeForParameter( mcode, parameter, value )
% iGenerateCodeForParameter   Generate code to assign the value of one parameter
% to the fit options object.
mcode.addAssignment( ['<opts>.', parameter], value );
end

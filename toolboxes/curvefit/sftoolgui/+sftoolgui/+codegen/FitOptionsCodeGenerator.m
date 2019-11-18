classdef FitOptionsCodeGenerator < curvefit.Handle
    % FitOptionsCodeGenerator   Classes for generating code for Fit Options
    %
    %   Example
    %       mcode = sftoolgui.codegen.MCode();
    %       factory = sftoolgui.codegen.FitOptionsFactory();
    %
    %       % Create fit options code generator
    %       focg = factory.create( aFitOptions );
    %
    %       % Most options are taken from the fit options. However, 
    %       % 'Exclude' and 'Weights' must be added as parameter-value pairs.
    %       % If the value for an option should be set from a variable in the
    %       % generated code, then the addParameterToken() method should be used to
    %       % add the option.
    %       focg.addParameterToken( 'Exclude', '<ex>' );
    %       focg.addParameterToken( 'Weights', '<weights>' );
    %       focg.addParameterValue( 'TolX', 1.23 ); % usually taken from fit options
    %
    %       % Generate code to setup fit options object (possible no-op)
    %       focg.generateSetupCode( mcode );
    %
    %       % Generate code to call FIT function
    %       mcode.addFunctionCall( 'f', 'g', '=', 'fit', 'x', 'y', 'poly1', focg.ExtraFitArguments{:} );
    %
    %   See also: sftoolgui.codegen.FitOptionsFactory, sftoolgui.codegen.MCode.
    
    %   Copyright 2012-2013 The MathWorks, Inc.
    
    properties(SetAccess = 'private', GetAccess = 'public', Dependent)
        % ExtraFitArguments   Cell-array of strings of "extra arguments" that should be
        % passed to the FIT function in generated code.
        ExtraFitArguments
    end
    
    methods
        function arguments = get.ExtraFitArguments( this )
            % get.ExtraFitArguments  Get method for ExtraFitArguments property
            arguments = getExtraFitArguments( this );
        end
    end
    
    methods(Abstract, Access = 'protected')
        % getExtraFitArguments  Implementation of get method for ExtraFitArguments property
        arguments = getExtraFitArguments( this )
    end
    
    methods(Abstract)
        % addParameterValue   Add a parameter-value pair to the list of Fit Options to
        % generate code generated.
        addParameterValue( this, parameter, value )
        
        % addParameterToken   Add a parameter-value pair where the value is a variable token.
        %
        % The parameter-value pair will be added to the list of Fit Options to generate
        % code generated.
        addParameterToken( this, parameter, token )
        
        % generateSetupCode   Generate the code required to setup a Fit Options object.
        %
        % See also: sftoolgui.codegen.MCode
        generateSetupCode( this, mcode )
    end
    
    methods(Access = protected)
        function addFitOptionsAsParameterValues( this, aFitOptions )
            % addFitOptionsAsParameterValues   Adds the names and values of any non-default
            % options fields as parameter-value pairs.
            
            % Get the default values for options
            defaultOptions = fitoptions( 'Method', aFitOptions.Method );
            
            % Get a list of all the possible parameters
            parameters = fieldnames( aFitOptions );
            parameters = setdiff( parameters, 'Method' );
            
            % For any options parameter where the value differs from the default, store the
            % pair.
            for i = 1:length( parameters )
                thisParameter = parameters{i};
                
                thisValue = aFitOptions.(thisParameter);
                defaultValue = defaultOptions.(thisParameter);
                
                if ismember( thisParameter, {'Exclude', 'Weights'} )
                    % ignore these options -- they should be added as parameter-value pairs
                elseif isequal( defaultValue, thisValue )
                    % do not store anything that has a default value
                elseif iAreLowerBoundsNegativeInfinity( thisParameter, thisValue )
                    % do not store lower bounds if they are negative infinity
                elseif iAreUpperBoundsInfinity( thisParameter, thisValue )
                    % do not store upper bounds if they are infinity
                else
                    this.addParameterValue( thisParameter, thisValue );
                end
            end
        end
    end
end

function tf = iAreLowerBoundsNegativeInfinity( parameter, value )
% iAreLowerBoundsNegativeInfinity   True if lower bounds are all negative
% infinity
tf = isequal( parameter, 'Lower' ) && all( value == -Inf );
end

function tf = iAreUpperBoundsInfinity( parameter, value )
% iAreUpperBoundsInfinity   True if upper bounds are all positive infinity
tf = isequal( parameter, 'Upper' ) && all( value == Inf );
end
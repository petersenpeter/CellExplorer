classdef(Sealed) Error < curvefit.attention.Thrower
    % Error   An attention thrower that throws MATLAB errors.
    
    %   Copyright 2011 The MathWorks, Inc.
    
    methods
        function throw( ~, msg )
            % throw   Throw a message object as a MATLAB error
            %
            % Syntax:
            %   throw( thrower, msg )
            %
            % Inputs
            %   message - A message object or MException
            if isempty( msg )
                % Ignore empty messages
            else
                if isa( msg, 'message' )
                    anException = MException( msg.Identifier, getString( msg ) );
                else
                    anException = msg;
                end
                throwAsCaller( anException );
            end
        end
    end
    
    methods(Access = protected)
        % doGetString   Get message for error.

        % An instance of curvefit.attention.Error will use the usual channels, i.e.,
        % MATLAB error, to pass the message around. Hence the message string is always
        % empty.
        function string = doGetString( ~ )
            string = '';
        end
    end
end

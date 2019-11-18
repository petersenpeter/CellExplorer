classdef(Sealed) SuppressedError < curvefit.attention.Thrower
    % SuppressedError   An attention thrower that suppresses error messages and
    % MException.
    
    %   Copyright 2011 The MathWorks, Inc.
    
    properties(Access = private)
        Message = [];
    end
    
    methods
        function throw( thrower, msg )
            % throw   Suppress an error message or MException for later access.
            %
            % Syntax:
            %   throw( thrower, msg )
            %
            % Inputs:
            %   msg   A message object or MException
            %
            % Notes:
            %   Each instance of SuppressedError allows only one error to be thrown.
            %   Subsequent calls to throw() will generate warnings at the command line.
            
            % If an error has not already been thrown ...
            if isempty( thrower.Message )
                % ... then store the message.
                thrower.Message = msg;
            else
                % Otherwise, throw a warning that only one error can be thrown per instance. 
                warning( message( 'curvefit:curvefit:attention:SuppressedError:ThrowOnlyOne', ...
                    iGetString( msg ) ) );
            end
        end
    end
    
    methods(Access = protected)
        function string = doGetString( thrower )
            % doGetString   Get message for suppressed error.
            string = iGetString( thrower.Message );
        end
    end
end

function string = iGetString(msg)
% iGetString   Get the string form of a message object or
% an MException.
if isempty( msg )
    string = '';
    
elseif isa( msg, 'message' )
    string = getString( msg );
    
else % assume isa( Message, 'MException' )
    string = msg.message;
end
end

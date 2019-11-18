classdef(Sealed) Warning < curvefit.attention.Thrower
    % Warning   An attention thrower that throws MATLAB warnings.

    %   Copyright 2011 The MathWorks, Inc.
    
    properties(Access = private)
        % Messages   Array of messages that have been thrown
        Messages
    end
    
    methods
        function thrower = Warning()
            % Warning   Constructor for curvefit.attention.Warning
            thrower.Messages = curvefit.attention.MessageArray;
        end
        
        function throw( thrower, msg )
            % throw   Throw a message.
            %
            % Syntax:
            %   throw( thrower, msg )
            %
            % Inputs
            %   msg - A message object
            if isempty( msg )
                % Ignore empty messages
                
            elseif ~thrower.Messages.contains( msg )
                % Throw the warning ...
                warning( msg );
                % ... and store it
                thrower.Messages.add( msg );
            end
        end
    end
    
    methods(Access = protected)
        function string = doGetString( ~ )
            % doGetString   Get message string.
            string = '';
        end
    end
end

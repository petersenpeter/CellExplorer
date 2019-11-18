classdef(Sealed) SuppressedWarning < curvefit.attention.Thrower
    % SuppressedWarning   An attention thrower that suppresses warning messages.
    
    %   Copyright 2011 The MathWorks, Inc.
    
    properties(Access = private)
        % Messages   Array of messages that have been thrown
        Messages
    end
    
    methods
        function thrower = SuppressedWarning()
            % SuppressedWarning   Constructor for curvefit.attention.SuppressedWarning
            thrower.Messages = curvefit.attention.MessageArray;
        end
        
        function throw( thrower, msg )
            % throw   Suppress an error message or MException for later access.
            %
            % Syntax:
            %   throw( thrower, msg )
            %
            % Inputs
            %   msg - A message object
            if isempty( msg )
                % Ignore empty messages
                
            elseif ~thrower.Messages.contains( msg )
                thrower.Messages.add( msg );
            end
        end
    end
    
    methods(Access = protected)
        function string = doGetString( thrower )
            % doGetString   Get message for suppressed warning.
            string = getString( thrower.Messages );
        end
    end
end

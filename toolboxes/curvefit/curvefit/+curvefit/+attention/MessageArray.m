classdef MessageArray < curvefit.Handle
    % MessageArray   An array of messages
    
    %   Copyright 2011-2012 The MathWorks, Inc.

    
    properties(Access = private)
        % Messages   Cell-array of messages in the array
        Messages = {};
    end
    
    methods
        function add( array, msg )
            % add   Add a message to the array

            if isa( msg, 'message' )
                array.Messages{end+1} = msg;
            else
                warning( message( 'curvefit:curvefit:attention:MessageArray:MustAddMessage' ) );
            end
        end
        
        function found = contains( array, msg )
            % contains   True if the array contains a given message
            %
            % Two messages are consider the same if their identifiers are the same. 
            messages = array.Messages;
            found = false;
            count = 0;
            while ~found && count < length( messages )
                count = count+1;
                found = isequal( messages{count}.Identifier, msg.Identifier );
            end
        end
        
        function string = getString( array )
            % getString   Get the string from an array of messages
            %
            % The strings for pairs of messages are separated by new lines ('\n'). If the
            % array is empty, then an empty string is returned.
            if isempty( array.Messages )
                string = '';
            else
                string = getString( array.Messages{1} );
                for i = 2:length( array.Messages )
                    string = sprintf( '%s\n%s', string, getString( array.Messages{i} ) );
                end
            end
        end
    end
end


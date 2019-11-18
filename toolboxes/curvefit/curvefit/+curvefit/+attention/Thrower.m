classdef Thrower < curvefit.Handle
    % Thrower   Something that throws an error or warning.
    %
    %   Thrower objects allow a general way to "throw" a message object (error or warning)
    %   from once piece of code and then access the message (string) from another
    %   piece of code.
    %
    %   Example -- When fitting a curve or surface to data, the choice of warning
    %   functions depends on whether a warning string (4th output) is asked for.
    %
    %       if nargout > 3
    %           warningFcn = curvefit.attention.SuppressedWarning();
    %       else
    %           warningFcn = curvefit.attention.Warning();
    %       end
    %
    %   The fitting code can then use this warning Thrower to throw a warning:
    %
    %       if ~isa( xdatain, 'double' )
    %           warningFcn.Throw( message( 'curvefit:fit:nonDoubleXData' ) );
    %       end
    %
    %   In command-line mode (nargin <= 3) the warning Thrower will use the usual
    %   MATLAB warning function to display a warning in the command window. But when
    %   used from CFTOOL (nargin > 3) the warning message can returned for display in
    %   the GUI:
    %
    %       warnstr = warningFcn.String;
    %
    %   A similar scheme can be done for errors.
    %
    %   Methods
    %       throw   Throw a message
    %
    %   Properties
    %       String   The string (char array) from a thrown message
    %
    %   See also:
    %       curvefit.attention.Warning
    %       curvefit.attention.SuppressedWarning
    %       curvefit.attention.Error
    %       curvefit.attention.SuppressedError
    
    %   Copyright 2011 The MathWorks, Inc.
    
    properties(Dependent)
        % String   The string (char array) from a thrown message.
        String
    end
    methods
        function string = get.String( thrower )
            string = doGetString( thrower );
        end
    end
    methods(Abstract, Access = protected)
        % doGetString   Implementation of get.String for Thrower
        %
        % Sub-classes must implement the doGetString() to provide access to a char-array
        % version of the message held by the thrower (if any).
        string = doGetString( thrower )
    end
    
    methods(Abstract)
        % throw   Throw a message.
        %
        % Syntax:
        %   throw( thrower, msg )
        %
        % Inputs
        %   msg - A message object
        throw( thrower, msg )
    end
end

classdef(Abstract) Client < curvefit.Handle
% Client   Abstract client for use in Surface Fitting Tool.

%   Copyright 2008-2013 The MathWorks, Inc.
    
    properties(SetAccess = 'protected', GetAccess = 'protected')
        % JavaPanel   The Java version of this panel.
        JavaPanel
        % JavaClient
        JavaClient
    end
    
    properties(SetAccess = 'protected', GetAccess = 'public')
        % Name   The name of the panel - this should not be translated
        Name
    end
    
    methods
        function addClient( obj, dt, dtl )
            % addClient   Add the panel to the desktop
            %
            %   addClient( HPANEL, DT, DTL ) adds the panel HPANEL to the MATLAB desktop DT
            %   in the position DTL (DTLocation)
            %
            %   'Name' is actually controlled by setClientName and setTitle in the JavaClient
            javaMethodEDT( 'addClient', dt, obj.JavaClient, obj.Name, true, dtl, true );
        end
    end
end

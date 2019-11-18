classdef ResidualsConfiguration < sftoolgui.Configuration
    %RESIDUALSCONFIGURATION configuration file for sftool Residuals plot 
    %
    %   SFTOOLGUI.RESIDUALSCONFIGURATION
    %
    %   Copyright 2008 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'private')
         Version = 1;
    end

    properties(SetAccess = 'public', GetAccess = 'public')
         Visible = 'off';
    end
    
    methods
          function this = ResidualsConfiguration()
          end
    end
end

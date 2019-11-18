classdef ResultsConfiguration < sftoolgui.Configuration
    %RESULTSCONFIGURATION configuration file for sftool Results panel
    %
    %   SFTOOLGUI.RESULTSCONFIGURATION
    %
    %   Copyright 2008 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'private')
         Version = 1;
    end
    
    properties(SetAccess = 'public', GetAccess = 'public')
         Visible = 'on';
    end
    
    methods
        function this = ResultsConfiguration()
        end
    end
end

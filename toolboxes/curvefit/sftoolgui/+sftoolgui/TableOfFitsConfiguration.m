classdef TableOfFitsConfiguration < sftoolgui.Configuration
    % TABLEOFFITSCONFIGURATON configuration file for sftool TableOfFits 
    
    %   SFTOOLGUI.TABLEOFFITSCONFIGURATION
    %
    %   Copyright 2008 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'private')
         Version = 1;
    end
    properties(SetAccess = 'public', GetAccess = 'public')
         Visible = true;
         Location = 'S';
    end

    methods
          function this = TableOfFitsConfiguration()
          end
     end
end

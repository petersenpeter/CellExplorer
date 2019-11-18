classdef CloseFitEventData < event.EventData
    %CLOSEFITEVENTDATA Data for a close fit event
    %
    %   SFTOOLGUI.CLOSEFITTEVENTDATA
    %
    %   Copyright 2008 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'public')
         FitUUID;
         FitFigureConfig;
    end

    methods
          function this = CloseFitEventData( fID, config )
                this.FitUUID = fID;
                this.FitFigureConfig = config;
          end
     end
end

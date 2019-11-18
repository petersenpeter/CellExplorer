classdef LoadFitEventData < event.EventData
    %LOADFITEVENTDATA Data for a load fit event
    %
    %   SFTOOLGUI.LOADFITTEVENTDATA
    %
    %   Copyright 2008 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'public')
         HFitdev;
         HFitFigureConfig;
    end

    methods
        function this = LoadFitEventData( fdev, config )
            this.HFitdev = fdev;
            this.HFitFigureConfig = config;
        end
    end
end

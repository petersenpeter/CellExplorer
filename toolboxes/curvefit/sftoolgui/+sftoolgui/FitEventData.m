classdef FitEventData < event.EventData
    %FITEVENTDATA Data for a FitsManager event
    %
    %   SURFTOOLGUI.FITTEVENTDATA
    %
    %   Copyright 2008 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'public')
           HFitdev;
    end

    methods
        function this = FitEventData( fitdev )
                this.HFitdev = fitdev;
        end
    end
end

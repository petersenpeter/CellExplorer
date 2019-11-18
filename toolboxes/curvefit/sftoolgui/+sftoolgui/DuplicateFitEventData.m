classdef DuplicateFitEventData < event.EventData
    %DUPLICATEFITEVENTDATA Data for a FitsManager duplicate fit event
    %
    %   SFTOOLGUI.DUPLICATEFITTEVENTDATA
    %
    %   Copyright 2008 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'public')
         SourceFitUUID;
         HFitdev;
    end

    methods
          function this = DuplicateFitEventData( sID,  dF)
                this.SourceFitUUID = sID;
                this.HFitdev = dF; %duplicated fit fitdev
          end
     end
end

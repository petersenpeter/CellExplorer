classdef Tracker < matlab.mixin.SetGet & ...
        mga.QueryGroup
    %TRACKER Tracker for logging hits to google analytics
    %
    %   t = Tracker(trackingID, hostname) creates a tracker for a unique
    %   google tracking id.
    
    properties (Constant)
        ProtocolVersion = 1 % The Protocol version. The current value is '1'. This will only change when there are changes made that are not backwards compatible.
    end % constant properties
    
    properties (SetAccess = private)
        TrackingID % The tracking ID / web property ID. The format is UA-XXXX-Y. All collected data is associated by this ID.
        Hostname % Specifies the hostname from which content was hosted.
    end % read-only properties
    
    properties (Constant, Access = private)
        TrackingURL = "https://www.google-analytics.com/collect" % Http post endpoint for Google Analytics
    end % private constant properties
    
    methods
        
        function obj = Tracker(varargin)
            %TRACKER Class constructor
            
            % parse inputs
            persistent p
            if isempty(p)
                p = inputParser;
                p.addRequired('TrackingID', @isstring); % TODO: Validate according to google requirements
                p.addRequired('Hostname', @isstring); % TODO: Validate is valid hostname
            end % if
            p.parse(varargin{:});
            
            % assign inputs
            set(obj, p.Results);
            
        end % Tracker
        
    end % structors
    
    methods
        
        function qp = queryParameters(obj)
            %QUERYPARAMETERS Convert tracker to query parameter objects
            
            s.v = obj.ProtocolVersion;
            s.tid = obj.TrackingID;
            s.dh = obj.Hostname;
            
            % convert to query parameters
            qp = matlab.net.QueryParameter(s);
            
        end % queryParameters
        
        function u = uri(obj, qp)
            
            % parse inputs
            persistent p
            if isempty(p)
                p = inputParser;
                p.addRequired('QueryParams', @(qp) all(isa(qp, 'matlab.net.QueryParameter')));
            end % if
            p.parse(qp);
            
            % combine uri and query parameters into a string
            uri = matlab.net.URI(obj.TrackingURL, qp);
            u = uri.string;
            
        end % string
        
        function r = track(obj, user, hit)
            %TRACK Track a hit
            
            % parse inputs
            persistent p
            if isempty(p)
                p = inputParser;
                p.addRequired('User', @(u) isa(u, 'mga.Visitor'));
                p.addRequired('Hit', @(h) isa(h, 'mga.hit.Hit'));
            end % if
            p.parse(user, hit);
            
            % combine all query parameters
            qp = cellfun(@(o) o.queryParameters, {obj, user, hit}, 'Un', 0);
            qp = [qp{:}];
            
            % create url string
            url = obj.uri(qp);
            
            % track hit
            [~, r] = urlread(char(url)); %#ok<URLRD>
            
        end % track
        
    end % public methods
    
end % Tracker
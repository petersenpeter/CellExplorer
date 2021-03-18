classdef Pageview < mga.hit.Hit
    %PAGEVIEW Pageview hit type
    %
    %   p = Pageview(path)
    %
    %   p = Pageview(..., 'Name', Value) constructs pageviews with optional
    %   properties:
    %       - Title
    %       - NonInteraction
    
    properties (Constant)
        Type = mga.hit.HitType.pageview % The type of hit.
    end % constant properties
    
    properties (SetAccess = private, AbortSet = true)
        Path (1, 1) string % The path portion of the page URL.
        Title string % The title of the page / document.
    end % read-only properties
    
    methods
        
        function obj = Pageview(varargin)
            %PAGEVIEW Class constructor
            
            % parse inputs
            persistent p
            if isempty(p)
                p = inputParser;
                p.KeepUnmatched = true;
                p.addRequired('Path', @(p) isstring(p));
                p.addParameter('Title', string.empty, @(a) isstring(a) && ...
                    mga.hit.Hit.validateByteLength(a, 1500, 'Title'));
            end % if
            p.parse(varargin{:});
            
            % call superclass construtor
            obj = obj@mga.hit.Hit(p.Unmatched);
            
            % set values
            set(obj, p.Results);
            
        end % Pageview
        
    end % structors
    
    methods
        
        function qp = queryParameters(obj)
            %QUERYPARAMETERS Convert hit to query parameters objects
            
            % convert to struct using measurement protocol query names
            s.t = obj.Type.string;
            s.dp = obj.Path;
            if ~isempty(obj.Title)
                s.dt = obj.Title;
            end % if
            
            % convert to query parameters
            qp = matlab.net.QueryParameter(s);
            
            % combine superclass parameters
            qp = [qp, queryParameters@mga.hit.Hit(obj)];
            
        end % queryParameters
        
    end % public methods
    
    methods (Static, Access = private)
        
        function tf = validateFirstChar(str, chr, prop)
            %VALIDATEFIRSTCHAR Validate that the first character in a
            %string matched the requested character.
            
            % assert that the first character in the string is as requested
            assert(strcmp(str{1}(1), chr), ...
                'Pageview:invalidFirstChar', ...
                "Expected first character of '" + prop + "' to be '" + chr + "'");
            
            % return true so that validation can be used in logical
            % statements
            tf = true;
            
        end % validateFirstChar
        
    end % private static methods
    
end % classdef
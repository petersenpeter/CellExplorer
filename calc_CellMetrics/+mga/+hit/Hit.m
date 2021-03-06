classdef (Abstract) Hit < matlab.mixin.SetGet & ...
        mga.QueryGroup
    %HIT Superclass for hits
    %
    %   h = Hit() constructs with default values
    %   
    %   h = Hit('Name', Value) constructs with optional properties:
    %       - NonInteraction
    
    properties (Abstract, Constant)
        Type % The type of hit. Must be one of 'pageview', 'screenview', 'event', 'transaction', 'item', 'social', 'exception', 'timing'.
    end % constant properties
    
    properties (SetAccess = private, AbortSet = true)
        NonInteraction (1, 1) logical = false % Specifies that a hit be considered non-interactive.
    end % read-only properties
    
    methods
        
        function obj = Hit(varargin)
            %HIT Class constructor
            
            % parse inputs
            persistent p
            if isempty(p)
                p = inputParser;
                p.addParameter('NonInteraction', false, @islogical);
            end % if
            p.parse(varargin{:});
            
            % assign values
            set(obj, p.Results);
            
        end % Hit
        
    end % structors
    
    methods
        
        function qp = queryParameters(obj)
            %QUERYPARAMETERS Convert hit to query parameter objects
            
            % only include NonInteraction if it is not default
            if obj.NonInteraction
                s.ni = obj.NonInteraction;
                qp = matlab.net.QueryParameter(s);
            else
                qp = matlab.net.QueryParameter.empty;
            end % if
            
        end % queryParameters
        
    end % public methods
    
    methods (Static, Access = protected)
        
        function tf = validateByteLength(str, len, prop)
            %VALIDATEBYTELENGTH Errors if byte length of string exceeds max
            %length
            
            % assert that the byte length is less than or equal to the
            % limit
            assert(numel(unicode2native(str, 'utf-8')) <= len, ...
                'Hit:maxLengthExceeded', ...
                "'" + prop + "' exceeds max length of " + len + "bytes");
            
            % return true so that validation can be used in logical
            % statements
            tf = true;
            
        end % validateByteLength
        
    end % static protected methods
    
end % classdef
classdef Visitor < matlab.mixin.SetGet & ...
        mga.QueryGroup
    %VISITOR Visitor object
    
    properties (SetAccess = private)
        ClientID (1, 1) string % This anonymously identifies a particular device.
        UserID % This is intended to be a known identifier for a user provided by the site owner/tracking library user. It must not itself be PII (personally identifiable information). (optional)
        ScreenResolution % Specifies the screen resolution.
        ScreenColors % Specifies the screen color depth.
        UserLanguage % Specifies the language.
        DataSource % Indicates the data source of the hit. In this case, operating system / matlab version is used.
        UserAgent % The User Agent of the browser.
        AppVersion % Version of application being tracked
    end % read-only properties
    
    methods
        
        function obj = Visitor(varargin)
            %VISITOR Class constructor
            
            % parse inputs
            p = inputParser;
            p.addParameter('UserID', string.empty, @isStringScalar);
            p.addParameter('AppVersion', "unknown", @isstring);
            p.parse(varargin{:});
            
            % assign properties
            set(obj, p.Results);
            obj.ClientID = obj.getClientID;
            obj.ScreenResolution = obj.getScreenResolution;
            obj.ScreenColors = get(0, 'ScreenDepth') + "-bits";
            obj.UserLanguage = string(get(0, 'Language'));
            obj.UserAgent = obj.getMatlab + "/" + p.Results.AppVersion + " (" + obj.getOS + ")";
            obj.DataSource = obj.getDataSource;
            
        end % Visitor
        
    end % structors
    
    methods
        
        function qp = queryParameters(obj)
            %QUERYPARAMETERS Convert hit to query parameter objects
            
            % convert to struct using measurement protocol query names
            s.cid = obj.ClientID;
            if ~isempty(obj.UserID)
                s.uid = obj.UserID;
            end % if
            s.sr = obj.ScreenResolution;
            s.sd = obj.ScreenColors;
            s.ul = obj.UserLanguage;
            s.ds = obj.DataSource;
            s.ua = obj.UserAgent;
            
            % convert to query parameters
            qp = matlab.net.QueryParameter(s);
            
        end % queryParameters
        
    end % public methods
    
    methods (Static, Access = private)
        
        function cid = getClientID
            %GETCLIENTID Returns client id for current machine.
            %   This client id persists across matlab instances, and is unique to a
            %   machine. It is stored in matlabprefs.mat.
            
            % return from preference if it exists, otherwise create a new uuid and save
            % it
            cid = getpref('GoogleAnalytics', 'ClientID', mga.util.uuid);
            cid = string(cid); % getpref returns a char when it was set as string?
            
        end % getClientID
        
        function res = getScreenResolution
            %GETSCREENRESOLUTION Returns screen resoltion as a string
            
            % get screen size array and convert to string
            sz = get(0, 'ScreenSize');
            res = sz(3) + "x" + sz(4);
            
        end % getScreenResolution
        
        function os = getOS
            %GETOS Returns operating system and version
            
            % get name and version and convert to string
            [name, version] = mga.util.detectOS;
            os = name + " " + strjoin(string(version), ".");
            
            % capitalise
            os{1}(1) = upper(os{1}(1));
            
        end % getOS
        
        function m = getMatlab
            %GETMATLAB Returns matlab version
            
            % extract release string
            v = ver('matlab');
            m = extractBetween(v.Release, "(", ")");
            
        end % getMatlab
        
        function ds = getDataSource
            %GETDATASOURCE Returns data source
            
            % are we deployed or running in matlab
            if isdeployed
                ds = "deployed";
            else
                ds = "matlab";
            end % if else
            
        end % getDataSource
        
    end % static private methods
    
end % classdef
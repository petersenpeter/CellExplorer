classdef PredictionIntervalOptions
    %PREDICTIONINTERVALOPTIONS Options for computing prediction intervals
    %
    %   PREDICTIONINTERVALOPTIONS are the options that can be used in the
    %   computation of prediction intervals. 
    %
    %   curvefit.PredictionIntervalOptions properties:
    %
    %   LEVEL - is the confidence level and has a default value of 0.95. Level
    %       must be greater than zero and less than 1.
    %
    %   INTERVAL - specifies the type of interval to compute. Interval can be
    %       either 'Observation' (the default) to compute bounds for a new
    %       observation, or 'Functional' to compute bounds for the fit evaluated
    %       at a point.
    %
    %   SIMULTANEOUS - specifies simultaneous confidence bounds ('on') or
    %       non-simultaneous bounds ('off'). The default is 'off'.
    
    %   Copyright 2008-2010 The MathWorks, Inc.
    
    properties(Constant)
        % OBSERVATION is the value of INTERVAL corresponding to observation intervals
        OBSERVATION = 'Observation';
        % FUNCTIONAL is the value of INTERVAL corresponding to functional intervals
        FUNCTIONAL = 'Functional';
    end
    properties
        % LEVEL is the confidence level and has a default value of 0.95. Level
        %   must be greater than zero and less than 1.
        Level = 0.95;
        % INTERVAL specifies the type of interval to compute. Interval can be
        %   either 'Observation' (the default) to compute bounds for a new
        %   observation, or 'Functional' to compute bounds for the fit evaluated
        %   at a point.
        Interval = curvefit.PredictionIntervalOptions.OBSERVATION;
        % SIMULTANEOUS specifies simultaneous confidence bounds ('on') or
        %   non-simultaneous bounds ('off'). The default is 'off'.
        Simultaneous = 'off';
    end
    methods
        function obj = PredictionIntervalOptions( varargin )
            % PREDICTIONINTERVALOPTIONS  Construct options object
            %
            %   OPTS = PREDICTIONINTERVALOPTIONS is a prediction interval
            %   options object. 
            %
            %   OPTS = PREDICTIONINTERVALOPTIONS( LEVEL ) sets the value of
            %   .Level in the options to LEVEL.
            %
            %   OPTS = PREDICTIONINTERVALOPTIONS( ..., PARAMETER, VALUE, ... )
            %   allows the options to be passed in at construction time as
            %   parameter-value pairs. Valid PARAMETERS are the same properties
            %   of the class.
            
            % Note that we allow "partial matching" of parameter names in the
            % constructor. However this feature should undocumented because the
            % valid abbreviations may change as more options are added. Using
            % the full form is recommended for forward compatibility.
            
            % Check for the optional LEVEL argument at the front of the list
            if nargin && isnumeric( varargin{1} )
                varargin = [{'Level'}, varargin];
            end
            % Parse parameter-value pairs
            for i = 1:2:length( varargin )
                prop = findProperty( obj, varargin{i} );
                obj.(prop) = varargin{i+1};
            end
        end
        
        function obj = set.Level( obj, value )
            if isscalar( value ) && isnumeric( value ) && 0 < value && value < 1
                obj.Level = value;
            else
                error(message('curvefit:PredictionIntervalOptions:InvalidLevel'))
            end
        end
        
        function obj = set.Interval( obj, value )
            % SET.INTERVAL -- Set Function for Interval Property
            %   INTERVAL must be 'Observation' or 'Functional', however we allow
            %   partial matching. This partial matching should be considered
            %   "undocumented" as further options maybe added in the future.
            %   Using the full form, including correct case, is recommended for
            %   forward compatibility.
            obj.Interval = makeValidInterval( value );
        end
        
        function obj = set.Simultaneous( obj, value )
            if ischar( value ) && ismember( value, {'on', 'off'} ),
                obj.Simultaneous = value;
            else
                error(message('curvefit:PredictionIntervalOptions:InvalidSimultaneous'));
            end
        end
    end
    
    methods(Access = 'private')
        function prop = findProperty( obj, prop )
            % findProperty   Find a property
            %   Look through the list of properties for the one that is a close
            %   match to the given PROP name.
            allProperties = properties( obj );
            idx = strncmpi( prop, allProperties, length( prop ) );
            if nnz( idx ) == 1,
                prop = allProperties{idx};
            else
                ME = curvefit.exception( 'curvefit:PredictionIntervalOptions:InvalidProperty', prop );
                throwAsCaller( ME );
            end
        end
    end
end

function value = makeValidInterval( value )
% makeValidInterval   Convert the input value to a valid value of .Interval if
% it can be uniquely matched.
validValues = {
    curvefit.PredictionIntervalOptions.OBSERVATION 
    curvefit.PredictionIntervalOptions.FUNCTIONAL
    };
idx = strncmpi( value, validValues, length( value ) );
% If there is a unique match ...
if nnz( idx ) == 1,
    % ... then return the full form of that value
    value = validValues{idx};
else
    % ... otherwise, throw an error.
    ME = curvefit.exception( 'curvefit:PredictionIntervalOptions:InvalidInterval', ...
        curvefit.PredictionIntervalOptions.OBSERVATION, ...
        curvefit.PredictionIntervalOptions.FUNCTIONAL );
    throwAsCaller( ME );
end
end

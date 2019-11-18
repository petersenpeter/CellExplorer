classdef (Sealed) MapDefault < curvefit.Handle
    % MapDefault   A map which supplies a default value when an invalid key
    % is supplied.  A warning can be optionally thrown when a default value
    % is retrieved.
    %
    % Example:
    %
    % keys =   {'cubic',       'nearest',       'linear',       'v4',               'thinplate', };
    % values = {'cubicinterp', 'nearestinterp', 'linearinterp', 'biharmonicinterp', 'thinplateinterp'};
    % aMap = curvefit.MapDefault( ...
    %       'Keys', keys, ...
    %       'Values', values, ...
    %       'DefaultValue', 'cubic', ...
    %       'WarningID', 'curvefit:sftoolgui:util:createNewSurfaceFittype:unknownPolynomial', ...
    %       'WarningArguments', {'myExponential'} ...
    %       );
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(Access = private)
        Container
        WarningID
        WarningArguments
        DefaultValue
        DefaultHasBeenSet
    end
    
    methods(Static)
        function map = fromCellArray( data, varargin )
            % fromCellArray   Construct MapDefault from cell-array of key and value pairs.
            %
            % Syntax:
            %   map = curvefit.MapDefault.fromCellArray( cellArray, <name>, <value> )
            %
            % Inputs
            %   cellArray -- a cell-array with two columns. Each row of cell should contain
            %       one key-value pair.
            %   <name>, <value> -- any parameter name-value pairs supported by the
            %       constructor, i.e., DefaultValue, WarningID, WarningArguments.
            %
            % Example:
            %   map = curvefit.MapDefault.fromCellArray( {
            %       1, 'One'
            %       2, 'Two'
            %       Inf, 'Infinity'
            %       -1, 'Negative One'
            %       } );
            %   map.get( -1 )
            %
            validateattributes( data, {'cell'}, {'ncols', 2} );
            map = curvefit.MapDefault( ...
                'Keys', data(:,1), ...
                'Values', data(:,2), ...
                varargin{:} );
        end
    end
    
    methods
        function this = MapDefault(varargin)
            [keys, values, warningID, warningArguments, default] = parseInputs(varargin{:});
            
            constructContainer(this, keys, values);
            
            this.WarningID = warningID;
            this.WarningArguments = warningArguments;
            
            this.DefaultValue = default;
            this.DefaultHasBeenSet = iCheckIfDefaultHasBeenSpecificified(varargin);
        end
        
        function value = get(this, key)
            % get Retrieves the value for a given key.  If the key is
            % invalid the method will throw an error unless a default value
            % has been specified.  If a default value has been specified
            % this will be returned.  The default value will be accompanied
            % with a warning only when the user supplies one in the
            % constructor.
            
            % If no default is set, then proceed as normal
            if ~this.DefaultHasBeenSet;
                value = this.Container(key);
                return
            end
            
            % Else check for presence and return default if necessary
            if this.Container.isKey(key)
                value = this.Container(key);
            else
                value = this.DefaultValue;
                throwWarningIfNecessary(this);
            end
            
        end
        
        function set(this, key, value)
            % set   This method sets the value for a key
            this.Container(key) = value;
        end
        
    end
    
    methods(Access = private)
        function constructContainer(this, keys, values)
            if isempty(keys)
                this.Container = containers.Map;
            else
                this.Container = containers.Map(keys, values);
            end
        end
        
        function throwWarningIfNecessary(this)
            if ~isempty(this.WarningID)
                % The api for warning depends on whether arguments are
                % required
                if ~isempty(this.WarningArguments)
                    warning(message(this.WarningID, this.WarningArguments{:}));
                else
                    warning(message(this.WarningID));
                end
            end
        end
    end
end

function [keys, values, warningID, warningArguments, default] = parseInputs(varargin)
parser = inputParser;
parser.FunctionName = 'MapDefault';
parser.addParamValue('Keys', {});
parser.addParamValue('Values', {});
parser.addParamValue('WarningID', '');
parser.addParamValue('WarningArguments', {});
parser.addParamValue('DefaultValue', []);
parser.parse( varargin{:} );

keys = parser.Results.Keys;
values = parser.Results.Values;
warningID = parser.Results.WarningID;
warningArguments = parser.Results.WarningArguments;
default = parser.Results.DefaultValue;
end


function tf = iCheckIfDefaultHasBeenSpecificified(args)
tf = any(strcmp(args, 'DefaultValue'));
end
classdef(Sealed) ExclusionCollection < sftoolgui.exclusion.ExclusionRule ...
        & curvefit.Handle & matlab.mixin.Copyable
    % ExclusionCollection   This class acts as the container for exclusion
    % rules and represents a light weight wrapper of a cell array.  An
    % exclude method is included which interprets the rules and applies
    % them to data.
    %
    % Example:
    %
    %     data = sftoolgui.Data();
    %     collection = sftoolgui.exclusion.ExclusionCollection();
    %     collection.add('x', '<', 1000);
    %     collection.exclude(data)
    
    %   Copyright 2013-2014 The MathWorks, Inc.
    
    events
        % RulesChanged   Fired for any changed in the rules held by the
        % collection
        RulesChanged
        
        % NameChanged   Fired when the name of the collection is changed.
        NameChanged
    end
    
    properties(SetAccess = private, GetAccess = public)
        Rules
    end
    
    properties
        % Name   (string)
        Name = '';
    end
    
    properties(Access = private)
        % Version   This version number may be used for serialisation
        % purposes
        Version = 1;
    end
    
    methods
        function this = ExclusionCollection()
            this.Rules = cell(0, 1);
        end
        
        function set.Version(this, version)
            % set.Version was created so that load would create a struct
            % for objects whose version number is less than the current
            % version.
            currentVersion = 1;
            if version >= currentVersion
                this.Version = version;
            else
                error(message('curvefit:sftoolgui:IncompatibleVersion', currentVersion - 1));
            end
        end
        
        function set.Name( this, name )
            this.Name = name;
            this.notify( 'NameChanged' )
        end
    end
    
    methods(Access = public)
        function add(this, variable, operator, value, varargin)
            % add   Adds a rule to the collection while optionally
            % specifying whether the rule is enabled.  The rule is enabled
            % by default.
            %
            % Example:
            %
            %     collection = sftoolgui.exclusion.ExclusionCollection();
            %     collection.add('x', '<', 1000);
            %     collection.add('y', '<', 1000, 'Enabled', true);
            %     collection.add('z', '<', 1000, 'Enabled', false);
            addQuietly(this, variable, operator, value, varargin{:});
            
            notify(this, 'RulesChanged')
        end
        
        function clear(this)
            % clear   Clears all rules from the collection
            %
            % Example:
            %
            %     collection = sftoolgui.exclusion.ExclusionCollection();
            %     collection.add('x', '<', 1000);
            %     collection.clear();
            this.Rules = cell(0,1);
            
            notify(this, 'RulesChanged')
        end
        
        function replace(this, rules)
            % replace   Replace all rules from the collection with a new
            % set of rules using an Nx5 cell array
            %
            % Example:
            %
            %     collection = sftoolgui.exclusion.ExclusionCollection();
            %     collection.replace({...
            %         'x', '<', 1000, 'Enabled', true;
            %         'y', '>', 0.5, 'Enabled', false
            %     });
            this.Rules = cell(0, 1);
            for i = 1:size(rules, 1)
                this.addQuietly(rules{i, :});
            end
            
            notify(this, 'RulesChanged')
        end
        
        function exclusions = exclude(this, data)
            % exclude   Creates a logical vector representing the rows that
            % should be excluded from the data.
            %
            % Example:
            %
            %     collection = sftoolgui.exclusion.ExclusionCollection();
            %     collection.add('x', '<', 1000);
            %     data = sftoolgui.Data({[1; 10; 100; 1000], [2; 20; 200; 2000], []}, {'x', 'y', 'z'});
            %     tf = collection.exclude(data)
            exclusions = false(0,1);
            if ~data.isAnyDataSpecified()
                return
            end
            
            if iDataIsValid(data)
                [~, y] = data.getValues();
                numberOfDataPoints = length( y );
                exclusions = false(numberOfDataPoints, 1);
                for i = 1:length(this.Rules)
                    newExclusions = this.Rules{i}.exclude(data);
                    if ~isempty(newExclusions)
                        exclusions = exclusions | newExclusions;
                    end
                end
            end
        end
        
        function accept( collection, visitor )
            % accept   Accept a ExclusionRuleVisitor
            cellfun( @(r) r.accept( visitor ), collection.Rules );
        end
    end
    
    methods(Access = private)
        function addQuietly(this, variable, operator, value, varargin)
            % addQuietly   Adds a rule to the collection without firing an
            % event
            enabled = iParseAddMethodInputs(varargin{:});
            this.Rules(end+1) = {sftoolgui.exclusion.OneSidedOneDExclusionRule(variable, operator, value, 'Enabled', enabled)};
        end
    end
end

function isValid = iDataIsValid(data)
isValid = (isSurfaceDataSpecified(data) || isCurveDataSpecified(data)) ...
    && areNumSpecifiedElementsEqual(data);
end

function enabled = iParseAddMethodInputs(varargin)
p = inputParser;
p.addOptional('Enabled', true, @islogical)
p.parse(varargin{:})
enabled = p.Results.Enabled;
end

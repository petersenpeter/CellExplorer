classdef ExclusionRulePlotter < curvefit.Handle & curvefit.ListenerTarget
    % ExclusionRulePlotter   The ExclusionRulePlotter class is used to keep
    % track of an ExclusionCollection and update the shaded regions of an
    % axes according to the one sided one dimensional exclusion rules (see:
    % sftoolgui.exclusions.OneSidedOneDExclusionRules).  An
    % ExclusionManager may optionally ignore a set of exclusion rules when
    % it does not make sense for a plot to display them, e.g. z < 1 for a
    % contour plot of a surface.
    %
    % Example:
    %
    %    a = axes('Parent', f); collection =
    %    sftoolgui.exclusion.ExclusionCollection(); e =
    %    ExclusionRulePlotter(a, collection, 'VariablesToIgnore', {'y',
    %    'z'});
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties
        Axes
    end
    
    properties(SetAccess = public, GetAccess = public)
        VariablesToIgnore = {};
    end
    
    properties(SetAccess = private, GetAccess = private)
        Collection
        ShadedAxesRegionFactory
        ShadedRegions
    end
    
    methods
        function this = ExclusionRulePlotter(collection, varargin)
            this.Collection = collection;
            this.ShadedRegions = {};
            this.ShadedAxesRegionFactory = iParseArguments(varargin{:});

            % This listener will update the shaded regions every time the
            % rules are changed
            this.listenToRulesChanged();
        end
        
        function set.VariablesToIgnore(this, value)
            this.VariablesToIgnore = value;
            this.createShadedRegions();
        end
        
        function set.Axes( this, anAxes )
            this.Axes = anAxes;
            this.createShadedRegions();
        end
    end
    
    methods(Access = private)
        function createShadedRegions(this)
            % createShadedRegions   This method deletes all the previous
            % shaded regions, and then reconstructs new shaded regions from
            % the rules stored in the collection
            this.deleteShadedRegions();
            
            rulesToShade = this.findRulesToShade();
            
            for i = 1:length(rulesToShade)
                rule = rulesToShade{i};
                region = this.ShadedAxesRegionFactory.createAxesShadedRegion(...
                    rule.Variable, rule.Operator, rule.Value, 'Parent', this.Axes ...
                    );
                
                this.ShadedRegions(i) = {region};
            end
        end
        
        function rulesToShade = findRulesToShade(this)
            % findRulesToShade   This function finds the rules in a
            % collection which can be shaded using an AxesShadedRegion. In
            % the future this code could be replaced with a visitor when we
            % have more than one ExclusionRule class
            rulesToShade = [];
            rules = this.Collection.Rules;
            
            if ~isempty(rules)
                rulesToIgnore = iFindRulesToIgnore(rules, this.VariablesToIgnore);
                rulesToShade = rules(~rulesToIgnore);
            end
        end
        
        function listenToRulesChanged(this)
            this.createListener(this.Collection, 'RulesChanged', @(src, evt)this.createShadedRegions);
        end
        
        function deleteShadedRegions(this)
            cellfun(@delete, this.ShadedRegions);
            this.ShadedRegions = {};
        end
    end
end

function shadedRegionFactory = iParseArguments(varargin)
% iParseArguments   Parse the optional parameters of the constructor
p = inputParser;
p.addOptional('AxesShadedRegionFactory', sftoolgui.exclusion.AxesShadedRegionFactory, @(x)isa(x, 'sftoolgui.exclusion.AxesShadedRegionFactory'));
p.parse(varargin{:});

shadedRegionFactory = p.Results.AxesShadedRegionFactory;
end

function rulesToIgnore = iFindRulesToIgnore(rules, variablesToIgnore)
variableNames = cellfun(@(x){x.Variable}, rules);
rulesToIgnore = ismember(variableNames, variablesToIgnore);
disabledRules = cellfun(@(rule)~rule.Enabled, rules);

rulesToIgnore = disabledRules|rulesToIgnore;
end

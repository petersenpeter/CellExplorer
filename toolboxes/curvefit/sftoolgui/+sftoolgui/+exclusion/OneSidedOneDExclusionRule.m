classdef (Sealed) OneSidedOneDExclusionRule < sftoolgui.exclusion.ExclusionRule
    % OneSidedOneDExclusionRule   This class acts as a wrapper for an one
    % sided one dimensional exclusion rule
    %
    % Example:
    %
    %     data = sftoolgui.Data();
    %     rule = sftoolgui.exclusion.OneSidedOneDExclusionRule('x', '<', 1000);
    %     tf = rule.exclude(data)
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        Variable
        Operator
        Value
        Enabled
    end
    
    properties(Access = private)
        % OperatorFunction   The function which is represented by the the
        % operator e.g. le, gt, leq, geq
        OperatorFunction
        
        % Version   This version number may be used for serialisation
        % purposes
        Version = 1;
    end
    
    methods
        function  this = OneSidedOneDExclusionRule(variable, operator, value, varargin)
            % OneSidedOneDExclusionRule   Create an exclusion rule from a
            % variable, an operator, a value and optionally specify whether
            % the rule is enabled.  The rule is enabled by default.
            %
            % Example:
            %
            %     rule = sftoolgui.exclusion.OneSidedOneDExclusionRule('x', '<', 1000);
            %     rule = sftoolgui.exclusion.OneSidedOneDExclusionRule('x', '<', 1000, 'Enabled', true);
            %     rule = sftoolgui.exclusion.OneSidedOneDExclusionRule('x', '<', 1000, 'Enabled', false);
            validatestring(variable, {'x', 'y', 'z'});
            validatestring(operator, {'<', '<=', '>', '>='});
            validateattributes(value, {'numeric'},{'scalar'});
            
            this.Enabled = iParseInputs(varargin{:});
            
            this.Variable = variable;
            this.Operator = operator;
            this.Value = value;
            
            this.OperatorFunction = iConvertOperatorToFunction(this.Operator, this.Enabled);
        end
        
        function this = set.Version(this, version)
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
    end
    
    methods(Access = public)
        function exclusions = exclude(this, data)
            % exclude   exclude data according to the rules specification
            %
            % Example:
            %
            %     data = sftoolgui.Data();
            %     rule = sftoolgui.exclusion.OneSidedOneDExclusionRule('x', '<', 1000);
            %     tf = rule.exclude(data)
            [x, y, z] = data.getValues();
            
            allData = {x,y,z};
            
            names = {'x', 'y', 'z'};
            
            index = strcmp(this.Variable, names);
            dataForExclusion = allData{index};
            
            exclusions = this.OperatorFunction(dataForExclusion, this.Value);
        end
        
        function accept( this, visitor )
            % accept   Accept a ExclusionRuleVisitor
            visitor.visitOneSidedOneDExclusionRule( this );
        end
    end
end

function operatorFunction = iConvertOperatorToFunction(operator, enabled)
% iConvertOperatorToFunction   Find the correct operator function for a
% given string representation

% Initially assume that the rule is disabled
operatorFunction = iAlwaysFalseOperator();

% If the rule is enabled, use the correct operator function
if enabled
    convert = curvefit.MapDefault.fromCellArray( {
        '<', @lt 
        '>', @gt 
        '<=', @le 
        '>=', @ge 
    });
    operatorFunction = convert.get(operator);
end
end

function operator = iAlwaysFalseOperator()
% iAlwaysFalseOperator   Generates a function which is used when the rule
% is disabled.  This function will return false for all input values
operator = @(data, ~) false(size(data));
end

function enabled = iParseInputs(varargin)
p = inputParser;
p.addOptional('Enabled', true, @islogical)
p.parse(varargin{:})
enabled = p.Results.Enabled;
end


classdef ExclusionsGenerator < curvefit.Handle & sftoolgui.exclusion.ExclusionRuleVisitor
    % ExclusionsGenerator   Generate code from exclusions and exclusion rules.
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties
        % ManualExclusions   Boolean vector with true elements corresponding to manually
        % excluded points
        ManualExclusions = [];
    end
    
    properties(Access = private)
        % Rules   Cell-str with each element the code for an exclusion rule.
        Rules = {};
    end
    
    properties(Access = private, Dependent)
        % ManualExclusionVariable   Name of the variable to use in code for points
        % excluded manually
        ManualExclusionVariable
        
        % ExcludedByRuleVariable   Name of the variable to use in code for points
        % excluded by rule
        ExcludedByRuleVariable
    end
    
    methods
        function visitOneSidedOneDExclusionRule( this, rule )
            % visitOneSidedOneDExclusionRule   Visit a sftoolgui.exclusion.OneSidedOneDExclusionRule
            %
            % Synatx:
            %   generator.visitOneSidedOneDExclusionRule( oneSidedOneDExclusionRule );
            if rule.Enabled
                this.Rules{end+1} = iCharArrayFromOneSidedOneDExclusionRule( rule );
            end
        end
        
        function generateCode( this, mcode )
            % generateCode   Generate code for exclusions and exclusion rules
            %
            % Syntax:
            %   generator.generateCode( mcode )
            %
            % Inputs
            %   mcode -- sftoolgui.codegen.MCode
            if this.anyExclusions()
                iAddVariableForExcludedPoints( mcode );
            end
            
            if this.anyManualExclusions()
                this.generateCodeForManualExclusions( mcode );
            end
            
            if this.anyExclusionRules()
                this.generateCodeForRules( mcode );
            end
            
            if this.hasManualExclusionsAndRules()
                iAddCodeToCombineManualAndRuleBasedExclusions( mcode );
            end
        end
        
        function variable = get.ManualExclusionVariable( this )
            if isempty( this.Rules )
                variable = '<ex>';
            else
                variable = 'excludedManually';
            end
        end
        
        function variable = get.ExcludedByRuleVariable( this )
            if this.anyManualExclusions()
                variable = 'excludedByRule';
            else
                variable = '<ex>';
            end
        end
    end
    
    methods(Access = private)
        function tf = anyExclusions( this )
            % anyExclusions   True if there are any exclusions, either by rule or manually
            % excluded
            tf = this.anyManualExclusions() ||  this.anyExclusionRules();
            
        end
                
        function tf = hasManualExclusionsAndRules( this )
            % hasManualExclusionsAndRules   True if there are both manual exclusions and
            % exclusion rules
            tf = this.anyManualExclusions() &&  this.anyExclusionRules();
        end
        
        function tf = anyManualExclusions( this )
            % anyManualExclusions   True if any points are manually excluded
            tf = any( this.ManualExclusions );
        end
        
        function tf = anyExclusionRules( this )
            % anyExclusionRules   True is there are any exclusion rules
            tf = ~isempty( this.Rules );
        end
        
        function generateCodeForRules(this,mcode)
            if length( this.Rules ) > 1
                rules = iAddParenthsisAroundRules( this.Rules );
            else
                rules = this.Rules;
            end
            codeForRules = strjoin( rules, ' | ' );
            mcode.addAssignment( this.ExcludedByRuleVariable, codeForRules );
        end
        
        function generateCodeForManualExclusions(this,mcode)
            mcode.addFunctionCall( this.ManualExclusionVariable, '=', 'excludedata', ...
                '<x-input>', '<y-input>', '''Indices''', ...
                mat2str( find( this.ManualExclusions ) ) );
        end
    end
end

function string = iCharArrayFromOneSidedOneDExclusionRule( rule )
string = sprintf( '%s %s %s', rule.Variable, rule.Operator, mat2str( rule.Value ) ); 
string = strrep( string, 'x', '<x-input>' );
string = strrep( string, 'y', '<y-input>' );
string = strrep( string, 'z', '<z-output>' );
end

function iAddVariableForExcludedPoints( mcode )
mcode.addVariable( '<ex>', 'excludedPoints' );
end

function iAddCodeToCombineManualAndRuleBasedExclusions(mcode)
mcode.addAssignment( '<ex>', 'excludedManually | excludedByRule' );
end

function rules = iAddParenthsisAroundRules(Rules)
rules = strcat( '(', Rules, ')' );
end

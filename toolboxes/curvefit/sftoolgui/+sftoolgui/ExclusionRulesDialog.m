classdef ExclusionRulesDialog < curvefit.Handle & curvefit.ListenerTarget
    % ExclusionRulesDialog   Panel for editing exclusion rules in SFTOOL
    % 
    % Example: 
    %   collection = sftoolgui.exclusion.ExclusionCollection()
    %   dialog = sftoolgui.ExclusionRulesDialog(collection);
    %   dialog.Visible = true
    %   collection.add('x', '<', 1000);
    
    %   Copyright 2013-2014 The MathWorks, Inc.
    
    properties(Access = private)
        % ExclusionRules   (sftoolgui.exclusion.ExclusionCollection)
        ExclusionRules
        
        % JavaExclusionRuleFrame   (com.mathworks.toolbox.curvefit.surfacefitting.exclusions.ExclusionRuleDialog)
        JavaExclusionRuleFrame
    end

    properties(Dependent)
        % Visible   True if the dialog is visible
        Visible
    end

    methods
        function this = ExclusionRulesDialog(exclusionCollection)
            % ExclusionRulesDialog   Construct a Panel for editing
            % exclusion rules
            %
            % Example:
            %
            %   collection = sftoolgui.exclusion.ExclusionCollection()
            %   dialog = sftoolgui.ExclusionRulesDialog(collection);
            this.ExclusionRules = exclusionCollection;
                        
            this.JavaExclusionRuleFrame = javaObjectEDT( 'com.mathworks.toolbox.curvefit.surfacefitting.exclusions.ExclusionRuleDialog' );
            
            this.updateExclusionRuleFrame();
            this.updateDialogName();
            
            this.createListener(this.JavaExclusionRuleFrame,'RuleChange',@this.updateExclusionRules);
            this.createListener(exclusionCollection, 'RulesChanged', @this.updateExclusionRuleFrame);
            this.createListener(exclusionCollection, 'NameChanged', @this.updateDialogName);
        end

        function delete(this)
            javaMethodEDT('cleanup', this.JavaExclusionRuleFrame);
        end
        
        function set.Visible(this, visible)
            javaMethodEDT('setVisible', this.JavaExclusionRuleFrame, visible);
        end
        
        function visible = get.Visible(this)
            visible = javaMethodEDT('isVisible', this.JavaExclusionRuleFrame);
        end
    end
    
    methods(Access = private)
        function updateExclusionRules(this, ~, e)
            javaRules = iGetRulesFromJavaEvent(e);
            
            rules = iConvertJavaRulesToMATLABRules(javaRules);
            
            this.ExclusionRules.replace(rules);
        end
        
        function updateExclusionRuleFrame(this, ~, ~)
            rules = sftoolgui.exclusion.coalesceExclusionRules(this.ExclusionRules);
            
            javaList = iConvertToListOfRuleContainers(rules);
            
            javaMethodEDT('setValuesQuietly', this.JavaExclusionRuleFrame, javaList);
        end
        
        function updateDialogName(this, ~, ~)
            excludePointsByRule = getString(message('curvefit:sftoolgui:ExcludeByRule'));

            title = [excludePointsByRule ' - ' this.ExclusionRules.Name];
            javaMethodEDT( 'setTitle', this.JavaExclusionRuleFrame, title );
        end
    end
end

function list = iConvertToListOfRuleContainers(rules)
arrayOfRuleConatainers = cell(size(rules, 1), 1);
for i = 1:size(rules, 1)
    arrayOfRuleConatainers{i} = com.mathworks.toolbox.curvefit.surfacefitting.exclusions.RuleContainer(rules{i, 2}, rules{i, 3});
end
list = javaMethodEDT('asList', 'java.util.Arrays', arrayOfRuleConatainers);
end

function javaRules = iGetRulesFromJavaEvent(e)
javaRules = cell(javaMethodEDT('getRules', e));
end

function rules = iConvertJavaRulesToMATLABRules(javaRules)
numberOfRules = size(javaRules, 1);
rules = cell(numberOfRules, 5);

% parse the information from Java and reformat so that we can
% pass the data into the replace method
for i = 1:numberOfRules
    variable = javaRules(i, 1);
    operator = javaRules(i, 2);
    value = str2double(javaRules(i, 3));
    enabled = javaRules(i, 4);
    
    rules(i, :) = [variable operator value 'Enabled' enabled];
end
end

function coalescedRules = coalesceExclusionRules( exclusionRules )
% coalesceExclusionRules   This helper function is used to turn an
% exclusion collection which contains many overlapping rules into a cell
% array of coalesced rules which can be used to update the dialog box in
% CFTool
%
% e.g. 
% 
% collection = sftoolgui.exclusions.ExclusionCollection();
% collection.add('x', '<', 1000);
% collection.add('x', '<', 2000);
% rules = sftoolgui.exclusions.coalesceExclusionRules(collection);

%   Copyright 2013 The MathWorks, Inc.

rulesFromExclusionCollection = exclusionRules.Rules;

enabledRules = iExtractEnabledRules(rulesFromExclusionCollection);

if ~isempty(enabledRules)
    coalescedRules = iCoalesceCellArrayOfRules(enabledRules); 
else
    coalescedRules = {
        '', '', NaN
        '', '', NaN
        '', '', NaN
        '', '', NaN
        '', '', NaN
        '', '', NaN
        };
end
end

function coalesced = iCoalesceCellArrayOfRules(rules)
% iCoalesceCellArrayOfRules   This function takes a cell array of rules and
% coalesces the rules into a 6x3 array
xRules = iExtractRulesByVariable(rules, 'x');
yRules = iExtractRulesByVariable(rules, 'y');
zRules = iExtractRulesByVariable(rules, 'z');

coalescedX = iCoalesceRulesForVariable(xRules, 'x');
coalescedY = iCoalesceRulesForVariable(yRules, 'y');
coalescedZ = iCoalesceRulesForVariable(zRules, 'z');

coalesced = [
    coalescedX
    coalescedY
    coalescedZ
];
end

function rules = iExtractRulesByVariable(rules, variable)
% iExtractRulesByVariable   Extract rules based on what variable they refer
% to ('x', 'y', 'z')
allVariables = cellfun(@(x){x.Variable}, rules);
ruleIndices = strcmp(allVariables, variable);
rules = rules(ruleIndices);
end

function coalesced = iCoalesceRulesForVariable(rules, variable)
% iCoalesceRulesForVariable   Each variable has a rule for the upper bound
% and the lower bound, this function calculates those bounds
lowerBoundRule = iCoalesceLowerBound(rules, variable);
upperBoundRule = iCoalesceUpperBound(rules, variable);

coalesced = [
    lowerBoundRule
    upperBoundRule
    ];
end

function coalesced = iCoalesceLowerBound(rules, variable)
% iCoalesceLowerBound   Find the lower bound by finding the relevant
% operator and boundary value
lessThanValues = iExtractValuesByOperator(rules, '<');
lessThanEqualToValues = iExtractValuesByOperator(rules, '<=');

lessThanMaximum = max(lessThanValues);
lessThanEqualToMaximum = max(lessThanEqualToValues);

maximumMaximum = max([lessThanMaximum lessThanEqualToMaximum]);

if isempty(maximumMaximum)
    coalesced = {'', '', NaN};
elseif ismember(maximumMaximum, lessThanValues) && ismember(maximumMaximum, lessThanEqualToValues)
    coalesced = {variable, '<=', maximumMaximum};
elseif ismember(maximumMaximum, lessThanValues)
   coalesced = {variable, '<', maximumMaximum};
elseif ismember(maximumMaximum, lessThanEqualToValues)
    coalesced = {variable, '<=', maximumMaximum};
else
    coalesced = {'', '', NaN};
end

end

function coalesced = iCoalesceUpperBound(rules, variable)
% iCoalesceUpperBound   Find the upper bound by finding the relevant
% operator and boundary value
greaterThanValues = iExtractValuesByOperator(rules, '>');
greaterThanEqualValues = iExtractValuesByOperator(rules, '>=');

greaterThanMinimum = min(greaterThanValues);
greaterThanEqualToMinimum = min(greaterThanEqualValues);

minimumMinimum = min([greaterThanMinimum greaterThanEqualToMinimum]);

if isempty(minimumMinimum)
    coalesced = {'', '', NaN};
elseif ismember(minimumMinimum, greaterThanValues) && ismember(minimumMinimum, greaterThanEqualValues)
    coalesced = {variable, '>=', minimumMinimum};
elseif ismember(minimumMinimum, greaterThanValues)
   coalesced = {variable, '>', minimumMinimum};
elseif ismember(minimumMinimum, greaterThanEqualValues)
    coalesced = {variable, '>=', minimumMinimum};
else
    coalesced = {'', '', NaN};
end
end

function values = iExtractValuesByOperator(rules, operator)
% iExtractValuesByOperator   Extract values which have the specified
% operator ('<', '<=', '>', '>=')
operators = cellfun(@(x){x.Operator}, rules);
ruleIndices = strcmp(operators, operator);
rules = rules(ruleIndices);
values = cellfun(@(x)x.Value, rules);
end

function enabledRules = iExtractEnabledRules(rulesFromExclusionCollection)
% iExtractEnabledRules   Extract rules which are enabled
enabled = cellfun(@(x)x.Enabled, rulesFromExclusionCollection);
enabledRules = rulesFromExclusionCollection(enabled);
end

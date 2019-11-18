classdef(HandleCompatible) ExclusionRuleVisitor
    % ExclusionRuleVisitor   Visits sftoolgui.exclusion.ExclusionRule
    
    %   Copyright 2013 The MathWorks, Inc.
    
    methods(Abstract)
        visitOneSidedOneDExclusionRule( this, oneSidedOneDExclusionRule );
    end
end

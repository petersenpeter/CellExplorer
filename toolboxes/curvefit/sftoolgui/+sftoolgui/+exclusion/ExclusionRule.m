classdef(HandleCompatible) ExclusionRule
    % ExclusionRule   Interface for Exclusion Rules
    
    %   Copyright 2013 The MathWorks, Inc.
    
    methods(Abstract, Access = public)
        % exclude   Exclude data according to the rule
        %
        % Syntax:
        %   exclusions = exclude( rule, data )
        %
        % Inputs:
        %   rule -- sftoolgui.exclusion.ExclusionRule
        %   data -- sftoolgui.Data
        %
        % Outputs:
        %   exclusions -- Boolean vector with one element for each point in data
        exclusions = exclude( this, data );
        
        % accept   Accept an ExclusionRuleVisitor
        %
        % An exclusion rule must implement the accept method, by passing itself to the
        % appropriate visitXxxx() method of exclusionRuleVisitor.
        accept( rule, exclusionRuleVisitor );
    end
end

classdef CoalescerInterface
    % CoalescerInterface   Interface for things that coalesce duplicate points
    
    %   Copyright 2011 The MathWorks, Inc.
    
    methods(Abstract)
        % Coalesce duplicate points
        [X, z] = coalesce( this, X, z )
    end
end

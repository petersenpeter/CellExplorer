classdef AxesShadedRegionFactory
    % AxesShadedRegionFactory   A factory for producing AxesShadedRegion
    % example instances
    
    %   Copyright 2013-2014 The MathWorks, Inc.
    methods
        function axesShadedRegion = createAxesShadedRegion(~, variable, operator, value, varargin)
            axesShadedRegion = sftoolgui.exclusion.AxesShadedRegion(variable, operator, value, varargin{:});
        end
    end
end

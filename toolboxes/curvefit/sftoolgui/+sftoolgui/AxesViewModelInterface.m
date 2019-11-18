classdef AxesViewModelInterface < curvefit.Handle
    % AxesViewModelInterface is the interface for a model of axes View and Limits properties
    
    %   Copyright 2011 The MathWorks, Inc.
    
    events (NotifyAccess = protected)
        % ThreeDViewAngleChanged-- fired when the ThreeDViewAngle property
        % changes
        ThreeDViewAngleChanged
        % LimitsChanged-- fired when any of the Limit properties change
        LimitsChanged
    end
    
    properties (Abstract)
        % ThreeDViewAngle is view angle of a non-curve plot
        ThreeDViewAngle ;
        
        % XInputLimits are the limits for the x input
        XInputLimits ;
        
        % YInputLimits are the limits for the y input
        YInputLimits ;
        
        % ResponseLimits are the limits for the response data
        ResponseLimits ;
        
        % ResidualLimits are the limits for the residuals response data
        ResidualLimits ;
    end
    
    methods (Abstract)
        setLimits(this, input, output, residuals);
    end
end

classdef AbstractPlotCommandGenerator < curvefit.Handle
    %AbstractPlotCommandGenerator   Abstract class for generating code to call the
    % plot method of a fit object
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    properties
        HaveValidation = false;
        HaveLHS = false;
        HaveExcludedData = false;
        % StyleArguments -- cell-string
        %
        %   A cell-string of parameter-value pairs that describe the plot style.
        %   This property should set this to an appropriate value to get
        %   the plot that is needed.
        StyleArguments = {};
    end
    
    methods( Abstract )
        addPlotCommand( cg, mcode )
    end
    
end

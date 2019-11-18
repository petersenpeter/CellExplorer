classdef CurveAxesLabelCodeGenerator < curvefit.Handle
    % CurveAxesLabelCodeGenerator   Class for generating code for axes labels for
    % plots of curve fits.
    
    %   Copyright 2011-2014 The MathWorks, Inc.
    
    properties
        % HasXData -- boolean
        %   Set to true when generating code for a fit that has x-data defined.
        HasXData = true;
    end
    
    methods( Access = public )
        function generateCode( cg, mcode )
            % generateCode   Generate code for axes labels for plots of curve fits.
            %
            %   generateCode( obj, mcode )
            addFitComment( mcode, getString(message('curvefit:sftoolgui:LabelAxes')) );
            if cg.HasXData
                addCommandCall( mcode, 'xlabel', '<x-name>' );
            end
            addCommandCall( mcode, 'ylabel', '<y-name>' );
        end
    end
end

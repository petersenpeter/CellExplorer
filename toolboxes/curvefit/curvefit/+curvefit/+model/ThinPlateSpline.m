classdef(Sealed) ThinPlateSpline < curvefit.model.SurfaceInterpolant
    % ThinPlateSpline   Thin-plate spline surface interpolant 
    %
    % Examples: 
    %   x = [0.82;0.98;0.73;0.34;0.58;0.11;0.91;0.88;0.82;0.26;0.59;0.023;0.43];
    %   y = [0.31;0.16;0.18;0.42;0.094;0.6;0.47;0.7;0.7;0.64;0.034;0.069;0.32];
    %   z = [0.6;0.2;0.48;0.6;0.39;0.4;0.32;0.098;0.12;0.32;0.36;0.83;0.61];
    %   st = tpaps( [x, y].', z.' );
    %   thinPlateSpline = curvefit.model.ThinPlateSpline( st )
    %   predictions = thinPlateSpline.evaluate( [0, 1; 1, 1; 1, 0] )
    %
    % See also: curvefit.model.SurfaceInterpolant

    %   Copyright 2013 The MathWorks, Inc.
    
    properties(Access = private)
        % Spline   The spline in stform
        Spline
    end
    
    methods 
        function this = ThinPlateSpline( aSpline )
            % ThinPlateSpline   Create a thin-plate spline.
            %
            % Syntax: 
            %   curvefit.model.ThinPlateSpline( aSpline )
            %
            % Inputs: 
            %   aSpline - A spline in stform
            this = this@curvefit.model.SurfaceInterpolant( 'Thin-plate Spline' );
            
            this.Spline = aSpline;
        end
    end
    
    methods(Access = protected)
        function zi = doEvaluate( this, xi, yi )
            % doEvaluate   Evaluate surface interpolant.
            %
            % See also: curvefit.model.SurfaceInterpolant.doEvaluate
            zi = fnval( this.Spline, [xi, yi].' );
            zi = zi.';
        end
    end
end
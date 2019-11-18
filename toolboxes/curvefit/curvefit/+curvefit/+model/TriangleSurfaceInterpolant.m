classdef(Sealed) TriangleSurfaceInterpolant < curvefit.model.SurfaceInterpolant
    % TriangleSurfaceInterpolant   A surface interpolant that uses triangles
    %
    % Examples: Create linear and nearest neighbor surface interpolants
    %
    %   dt = DelaunayTri( X );
    %   curvefit.model.TriangleSurfaceInterpolant( 'Linear', 'linear', dt, z )
    %   curvefit.model.TriangleSurfaceInterpolant( 'Nearest Neighbor', 'nearest', dt, z )
    %
    % See also: curvefit.model.SurfaceInterpolant

    %   Copyright 2011-2013 The MathWorks, Inc.
    
    properties(Access = private)
        % TriInterp   A TriScatteredInterp
        TriInterp = []
    end
    methods 
        function this = TriangleSurfaceInterpolant( type, method, dt, z )
            % TriangleSurfaceInterpolant   Create a triangle surface interpolant.
            %
            % Syntax:
            %   curvefit.model.TriangleSurfaceInterpolant( type, method, dt, z )
            %
            % Inputs:
            %   type - Either 'Linear' or 'Nearest Neighbor'.
            %   method - Method of TriScatteredInterp to use. Either 'linear' or 'nearest'.
            %   dt - Delaunay triangulation (DelaunayTri) of the interpolation sites.
            %   z - Interpolation values (numPoints-by-1 array).
            this = this@curvefit.model.SurfaceInterpolant( type );
            
            % Construct an interpolant based on these triangles.
            this.TriInterp = TriScatteredInterp( dt, z, method );
        end
    end
    
    methods(Access = protected)
        function zi = doEvaluate( this, xi, yi )
            % doEvaluate   Evaluate surface interpolant.
            %
            % See also: curvefit.model.SurfaceInterpolant.doEvaluate
            zi = this.TriInterp( [xi, yi] );
        end
    end
end

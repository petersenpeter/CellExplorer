classdef SurfaceInterpolant
    % SurfaceInterpolant   Surface interpolant
    %
    % To create a surface interpolant, use a curvefit.model.SurfaceInterpolantFactory.
    %
    % See also: curvefit.model.SurfaceInterpolantFactory.
    
    %   Copyright 2011 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        % Type   Type of interpolant (string)
        Type = '';
    end
    
    methods
        function this = SurfaceInterpolant( type )
            % SurfaceInterpolant   Create a surface interpolant
            %
            % Syntax:
            %   this = this@curvefit.model.SurfaceInterpolant( type );
            %
            % Inputs:
            %   type = type of interpolant (string)
            this.Type = type;
        end
        
        function zi = evaluate( this, xi, yi )
            % evaluate   Evaluate interpolant
            %
            % Syntax:
            %   1: zi = evaluate( interpolant, Xi )
            %   2: zi = evaluate( interpolant, xi, yi )
            %
            % Inputs:
            %   interpolant - The interpolant (curvefit.model.SurfaceInterpolant) to
            %       evaluate.
            %   Xi - array (numPoints-by-2) of query points.
            %   xi, yi - arrays (any size) of query points.
            %
            % Output:
            %   zi - array of interpolated values, i.e., zi(i) = f( xi(i), y(i) ),
            %      where f is the function the represents the interpolant.
            %
            %   In the case of form 1, Xi is interpreted as [xi, yi] and zi will be column
            %   vector of numPoints elements.
            % 
            %   In the case of form 2, xi and yi must be the same size. The output, zi, will
            %   be the same size and xi and yi.
            narginchk( 2, 3 )
            
            if nargin == 3
                % zi = evaluate( this, xi, yi )
                zi = doEvaluate( this, xi(:), yi(:) );
                % Preserve input shape
                zi = reshape( zi, size( xi ) );
                
            else % assume nargin == 2
                % zi = evaluate( this, xi )
                zi = doEvaluate( this, xi(:,1), xi(:,2) );
            end
        end
    end
    
    methods(Abstract, Access = protected)
        % doEvaluate   Evaluate surface interpolant.
        %
        % Syntax:
        %   zi = doEvaluate( interpolant, xi, yi )
        %
        % Inputs:
        %   interpolant - The interpolant (curvefit.model.SurfaceInterpolant) to
        %       evaluate.
        %   xi, yi - Column vectors of evaluation points.
        %
        % Outputs:
        %   zi - Column vector of interpolated values, i.e., zi(i) = f( xi(i), y(i) ),
        %      where f is the function the represents the interpolant.
        zi = doEvaluate( this, xi, yi )
    end
    
end
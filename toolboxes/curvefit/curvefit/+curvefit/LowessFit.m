classdef LowessFit
    %LOWESSFIT   Encapsulates fitting a lowess model to data.
    %
    %   OBJ = LOWESSFIT
    %
    %
    %   Example 1.
    %       x  = linspace( 0, 10, 9 ).';
    %       xi = linspace( 0, 10, 7 ).';
    %       y = sin( x );
    %       obj = curvefit.LowessFit;
    %       obj = fit( obj, x, y );
    %       yi = evaluate( obj, xi )
    %       plot( x, y, 'o', xi, yi, 'x' )
    %
    %   Example 2.
    %       q = qrandstream( scramble( haltonset( 2 ), 'RR2' ) );
    %       X = qrand( q, 19 );
    %       Xi = qrand( q, 17 );
    %       z = franke( X(:,1), X(:,2) );
    %       obj = curvefit.LowessFit();
    %       obj.Span = 5/19;
    %       obj = fit( obj, X, z );
    %       zi = evaluate( obj, Xi );
    %
    %   References:
    %   [C79] W.S.Cleveland, "Robust Locally Weighted Regression and Smoothing
    %       Scatterplots", J. of the American Statistical Ass., Vol 74, No. 368
    %       (Dec.,1979), pp. 829-836.

    %   Copyright 2008-2012 The MathWorks, Inc.

    properties(SetAccess = 'public', GetAccess = 'public')
        % Degree   Degree of the polynomial used in the//tmw/Bcurvefit/main/matlab/toolbox/curvefit/curvefit/private/cfinterp1.m local regressions.
        %   The default is 1, with 0 and 2 being the other allowed values.
        Degree = 1;
        % Span   Proportion of points used in each local regression. 
        %   The default is 25%. 
        %   The value of Span must be between 0 and 1.
        Span  = 0.25;
        % Robust   Robust algorithm to use. 
        %   Options are: 'off', 'Bisquare', 'LAR'. 
        %   The default is 'off'.
        Robust = 'off';
    end
    
    properties(SetAccess = 'private', GetAccess = 'public')
        % Lambda   Effective number of parameters in model.
        Lambda
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        % XData -- Input data. The number of columns of XData is the number of
        % inputs.
        XData
        % YData -- Output data
        YData
        % Feps -- tolerance
        Feps
        % MaxIter --  the number of iterations with a robust lowess. The default
        % is five.
        MaxIter = 5;
        % NLocal -- the number of points to use in each local regression. This
        % is computed from the span and the number of data points provided.
        NLocal
        % Weights -- These include the weights passed in by the user as well as
        % any robust weights computed by the algorithm
        Weights
        % VandermondeFcn -- Handle to a function to compute the Vandermonde
        % matrix for the given degree and number of inputs (columns of X)
        VandermondeFcn
        % RobustWeightFcn -- Handle to a function to compute the robust weights
        % from a vector of residuals.
        RobustWeightFcn
    end

    methods
        function obj = set.Span( obj, value )
            if value > 1 || value < 0
                error(message('curvefit:LowessFit:InvalidSpan'));
            end
            obj.Span = value;
        end
    end
    
    methods(Access = 'public')
        function obj = fit( obj, x, y, weights )
            obj.Feps = eps( max( abs( y ) ) );
            obj.XData = x;
            obj.YData = y;
                            
            if nargin < 4 || isempty( weights )
                weights = ones( size( y ) );
            end
            
            % Parse options, i.e., degree, span, robust
            obj = parseDegree( obj );
            obj = parseSpan(   obj );
            obj = parseRobust( obj );
                        
            % Compute the robust weights, delta
            delta = weights;
            for i = 1:obj.MaxIter
                % 1. Smooth with Lowess
                yhat = weightedLowess( obj, x, delta .* weights );
                % 2. Compute the robust weights
                delta = weights .* obj.RobustWeightFcn( y - yhat, obj.Feps );
            end
            obj.Weights = delta;
            
            % Approximate number of parameters
            obj.Lambda = 2*(1 + length( obj.YData )/obj.NLocal);
        end
        
        function yi = evaluate( obj, xi )
            yi = weightedLowess( obj, xi, obj.Weights );
        end
    end
    
    methods(Access = 'private')
        function obj = parseDegree( obj )
            % Take the degree and construct the vandermonde function
            switch obj.Degree
                case 0
                    obj.VandermondeFcn = @iVandermondeConstant;
                case 1
                    obj.VandermondeFcn = @iVandermondeLinear;
                case 2
                    nDim = size( obj.XData, 2 );
                    if nDim == 1
                        obj.VandermondeFcn = @iVandermondeQuadratic1;
                    elseif nDim == 2
                        obj.VandermondeFcn = @iVandermondeQuadratic2;
                    else
                        throwAsCaller( curvefit.exception( 'curvefit:LowessFit:InvalidDimension' ) );
                    end
                otherwise
                    throwAsCaller( curvefit.exception( 'curvefit:LowessFit:InvalidDegree' ) );
            end
        end
        
        function obj = parseSpan( obj )
            % parseSpan -- Work out the number of points to use in each local
            % regression based on the span and the number of data points.

            % Take the size of the XData and requested span and compute the
            % number of points to use in each local regression.
            [nData, nDim] = size( obj.XData );
            
            % Work the minimum number of points in each local regression based
            % on the number of terms in the polynomial
            nTerms = [1, 2, 3; 1, 3, 6];
            minNLocal = nTerms(nDim,obj.Degree+1) + 2;
            
            % Finally work out the number of local points.
            obj.NLocal = max( ceil( obj.Span*nData ), minNLocal );
            if obj.NLocal > nData
                throwAsCaller( curvefit.exception( 'curvefit:fit:InsufficientData', minNLocal ) );
            end
        end
        
        function obj = parseRobust( obj )
            % Set the handle to the robust weighting function based on the
            % string given by the user
            switch lower( obj.Robust )
                case 'off'
                    obj.MaxIter = 0;
                    obj.RobustWeightFcn = @( r, myeps ) ones( size ( r ) );
                case {'bisquare', 'on'}
                    obj.RobustWeightFcn = @iBisquareWeights;
                case 'lar'
                    obj.RobustWeightFcn = @iLARWeights;
                otherwise
                    throwAsCaller( curvefit.exception( 'curvefit:LowessFit:InvalidRobust', obj.Robust ) );
            end
        end
        
        function yi = weightedLowess( obj, xi, delta  )
            x = obj.XData;
            y = obj.YData;
            k = obj.NLocal;
            vandermondeFcn = obj.VandermondeFcn;
            
            nPoints = size( xi, 1 );
            yi = zeros( nPoints, 1 );
            
            % Restrict the data set to those points with positive weights --
            % note that this will impact which points are in the local subsets.
            idx = delta > 0;
            x = x(idx,:);
            y = y(idx);
            delta = delta(idx);
            
            % Suppress warnings about rank deficient matrices that can occur
            % when we solve "beta = FX\wy" below.
            ws = warning( 'off', 'MATLAB:rankDeficientMatrix' );
            warningCleanup = onCleanup( @() warning( ws ) );
            
            % This loop is the main LOWESS computation. It works out the value
            % of the smoothed function at the point xi(i,:) based on the data
            % points nearby.
            for i = 1:nPoints
                
                % Work out k points closest to xi(i,:)
                [idx, d] = iKNearestNeighbours( k, xi(i,:), x );
                
                % Scale factor to for the regression
                sc = max( d );
                
                % Work out the local weights and combine with the external
                % weights
                w = sqrt( delta(idx) .* iTricubeWeights( d ) );
                
                % Perform local regression
                FX = vandermondeFcn( x(idx,:)/sc );
                FX = bsxfun( @times, w, FX );
                wy = w .* y(idx);
                beta = FX\wy;
                
                % Evaluate regression
                yi(i) = vandermondeFcn( xi(i,:)/sc ) * beta;
            end
        end % of function weightedLowess 
    end 
end % of classdef

%% K-Nearest Neighbors
function [idx, d] = iKNearestNeighbours( k, xi, x )
% Work out k points closest to xi

D = iDistance( x, xi );

[~, idx] = sort( D );
idx = idx(1:k);
d = D(idx);
end

%% Distance between Points
function D = iDistance( x, y )
% Calculate interpoint distances for two sets of points.

% Assume x or y has one point
D = sqrt( sum( bsxfun( @minus, x, y ).^2, 2 ) );

end

%% Tri-cubic weight function
function w = iTricubeWeights( d )
% Convert distances into weights using tri-cubic weight function.
%
% This function returns the square-root of the tri-cubic function
d = d/max( d );
w = (1 - d.^3).^3;
end
            
%% Bi-square weight function
function delta = iBisquareWeights( r, myeps )
% Convert residuals to weights using the bi-square weight function

% Only use non-NaN residuals to compute median
idx = ~isnan( r );
% And bound the median away from zero
s = max( 1e8 * myeps, median( abs( r(idx) ) ) );
% Covert the residuals to wrights
delta = iBisquare( r/(6*s) );
% Everything with NaN residual should have zero weight
delta(~idx) = 0;
end

function b = iBisquare( x )
% This is this bi-square function defined at the top of the left hand
% column of page 831 in [C79]
b = zeros( size( x ) );
idx = abs( x ) < 1;
b(idx) = (1 - x(idx).^2).^2;
end

%% LAR weight function
function w = iLARWeights( r, myeps )
% Convert residuals to weights using the LAR weight function
w = 1 ./ max( myeps, abs( r ) );
end

%% Vandermonde functions
function fx = iVandermondeConstant( x )
fx = ones( size( x, 1 ), 1 );
end
function fx = iVandermondeLinear( x )
fx = [ones( size( x, 1 ), 1 ), x];
end
function fx = iVandermondeQuadratic1( x )
fx = [ones( size( x, 1 ), 1 ), x, x.^2];
end
function fx = iVandermondeQuadratic2( x )
fx = [ones( size( x, 1 ), 1 ), x, x.^2, x(:,1).*x(:,2)];
end

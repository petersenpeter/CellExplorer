function algorithm = setAlgorithm(~, algorithm)
% iSetAlgorithm   Set method for 'Algorithm'

% Copyright 2015 The MathWorks, Inc.

if isequal( algorithm, 'Gauss-Newton' )
    error( message( 'curvefit:fitoptions:GaussNewtonRemoved' ) );
end

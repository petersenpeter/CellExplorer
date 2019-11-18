function [X, z] = coalesceDuplicatePoints( X, z )
% coalesceDuplicatePoints   Coalesce duplicate points
%
%   [X, z] = coalesceDuplicatePoints( X, z ) finds groups of points that are
%   duplicates of each other (within a tolerance) and coalesces such groups into
%   single points. The test for "duplicates" is applied to the X input. Rows of
%   [X, z] that are duplicates (within tolerance) are replaced by the mean value
%   of the row.
%
%   Distance between points (rows of X) is measured using the infinity (max)
%   norm.

%   Copyright 2011-2012 The MathWorks, Inc.

% The test for "duplicates" is applied to the X input and we need to compute an
% appropriate tolerance to use.
tolerance = iDeduceTolerance( X );

% We need to Coalesce duplicate points in terms of Xz = [X, z].
Xz = curvefitlib.internal.uniqueWithinTol( [X, z], [tolerance, Inf], 'average' );

% Pull the output versions of X and z out of the combined version (Xz = [X, z])
X = Xz(:,1:end-1);
z = Xz(:,end);
end 

function tolerance = iDeduceTolerance( X )
% iDeduceTolerance   Deduce the tolerance that we should use for this matrix.
%
% The tolerance is a row vector with same number of columns as X.
minX = min( X, [], 1 );
maxX = max( X, [], 1 );
tolerance = eps( maxX - minX ).^(1/3);
end

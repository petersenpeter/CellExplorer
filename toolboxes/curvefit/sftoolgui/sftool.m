function h_ = sftool( varargin )
%SFTOOL    Opens Curve Fitting Tool
%
%   SFTOOL will be removed in a future release. Use CFTOOL instead.
%
%   SFTOOL opens Curve Fitting Tool or brings focus to the Tool if it is
%   already open.
%
%   SFTOOL(X,Y,Z) creates a surface fit to X and Y inputs and Z output. X,
%   Y, and Z must be numeric, have two or more elements, and have
%   compatible sizes. Sizes are compatible if X, Y, and Z all have the same
%   number of elements or X and Y are vectors, Z is a 2D matrix, length(X)
%   = n, and length(Y) = m where [m,n] = size(Z). SFTOOL opens Curve
%   Fitting Tool if necessary.
%   
%   SFTOOL(X,Y,Z,W) creates a surface fit with weights W. W must be numeric
%   and have the same number of elements as Z.
%
%   SFTOOL(FILENAME) loads the surface fitting session in FILENAME into
%   Curve Fitting Tool. The FILENAME should have the extension '.sfit'.
%
%   See also CFTOOL.

%   SFTOOL(X,Y) creates a curve fit to X input and Y output. X and Y must
%   be numeric, have two or more elements, and have the same number of
%   elements. SFTOOL opens Surface Fitting Tool if necessary.
%   
%   SFTOOL(X,Y,[],W) creates a curve fit with weights W. W must be numeric
%   and have the same number of elements as X and Y.

%   Copyright 2008-2015 The MathWorks, Inc.

warning( message('curvefit:sftool:WillBeRemoved'));

% Get the names of the input arguments
names = cell( nargin, 1 );
for i = 1:nargin
    names{i} = inputname( i );
end

% Check for the special case of a single numeric argument ...
if nargin == 1 && isnumeric( varargin{1} )
    % ... where we convert it to three or four vectors
    [varargin, names] = iDataFromOneInput( varargin, names );
end

% Start SFTOOL with the given data and names
h = sftool_v1( varargin, names );

% Return output if requested.
if nargout
    h_ = h;
end

end

function [arguments, names] = iDataFromOneInput( arguments, names )
% iDataFromOneInput    Create vectors and names from a single numeric input
% argument. The return ARGUMENTS will be the input if the given ARGUMENTS{1} is
% not valid. The input is valid if it is numeric and has 3 or 4 columns and more
% than one row.

% We are only interested in the first (and only) argument
theMatrix = arguments{1};

% The input is good if it has 3 or 4 columns and more than one row.
[numRows, numColumns] = size( theMatrix );
goodInput = ( numColumns == 3 || numColumns == 4 ) && numRows > 1;

% If the input is good, 
if goodInput
    % ... convert the matrix to a cell array of vectors.
    arguments = num2cell( theMatrix, 1 );
    names = {'x', 'y', 'z', 'w'};
    names = names(1:numColumns);
end
% ... otherwise return what was given
end

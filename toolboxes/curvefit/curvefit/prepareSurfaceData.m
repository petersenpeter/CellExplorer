function [varargout] = prepareSurfaceData( varargin )
%PREPARESURFACEDATA   Prepare data inputs for surface fitting.
%
%   [XOUT, YOUT, ZOUT] = PREPARESURFACEDATA(XIN, YIN, ZIN)
%   [XOUT, YOUT, ZOUT, WOUT] = PREPARESURFACEDATA(XIN, YIN, ZIN, WIN)
%
%   This function transforms data, if necessary, for the FIT function as
%   follows:
%
%       * For table data, transforms row (YIN) and column (XIN) headers
%       into arrays YOUT and XOUT that are the same size as ZIN. Warn if
%       XIN and YIN are reversed.
%
%       * Return data as columns regardless of the input shapes. Error if
%       the number of elements do not match. Warn if the number of elements
%       match, but the sizes are different.
%
%       * Convert complex to real (remove imaginary parts) and warn.
%
%       * Remove NaN/Inf from data and warn.
%
%       * Convert nondouble to double and warn.
%
%   See also: FIT, EXCLUDEDATA, PREPARECURVEDATA.

%   Copyright 2010-2011 The MathWorks, Inc.

% Check the number of inputs is three or four and that the number of outputs is
% the same as the number of inputs.
narginchk( 3, 4 );
assertNumOutputsEqualsNumInputs( nargin, nargout );

data = varargin;

% If the data is tabular, then use MESHGRID to expand the row and column headers.
[data{:}] = iMeshgrid( data{:} );

% The inputs must all have the same number of elements
iAssertInputsHaveSameNumElements( data{:} );

% Prepare the data for fitting
[data{:}] = prepareFittingData( data{:} );

% The output is then just whatever is left of the data.
varargout = data;
end

function iAssertInputsHaveSameNumElements( x, y, z, w )
% iAssertInputsHaveSameNumElements   Ensure that all inputs have the same
% number of elements as each other
if numel( x ) ~= numel( y ) || numel( x ) ~= numel( z ) ...
        || (nargin == 4 && numel( x ) ~= numel( w ) )
    error( message( 'curvefit:prepareSurfaceData:unequalNumel' ) );
end
end

function [x, y, z, w] = iMeshgrid( x, y, z, w )
% iMeshgrid   Expand row & column (Y & X) headers if appropriate

% If Y and Y and vectors and Z is a matrix,
if isvector( x ) && isvector( y ) && ismatrix( z ) && ~isvector( z )
    [numZRows, numZColumns] = size( z );
    % ... and if the size of Y matches the number of rows of Z
    % ... and the size of X matches the number of columns of Z
    if numel( y ) == numZRows && numel( x ) == numZColumns
        % ... then "meshgrid" x and y
        [x, y] = meshgrid( x, y );
        
        % ... but if the size of X matches the number of rows of Z
        % ... and the size of Y matches the number of columns of Z
    elseif numel( x ) == numZRows && numel( y ) == numZColumns
        % ... then "meshgrid" x and y in the swapped positions
        [y, x] = meshgrid( y, x );
        % ... and warn
        warning( message( 'curvefit:prepareSurfaceData:swapXAndYForTable' ) );
    end
end
end

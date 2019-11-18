function [varargout] = prepareCurveData( varargin )
%PREPARECURVEDATA   Prepare data inputs for curve fitting.
%
%   [XOUT, YOUT] = PREPARECURVEDATA(XIN, YIN)
%   [XOUT, YOUT, WOUT] = PREPARECURVEDATA(XIN, YIN, WIN)
%
%   This function transforms data, if necessary, for the FIT function as
%   follows:
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
%       * If XIN is empty then XOUT will be a vector of indices into YOUT. The
%       FIT function can then use vector XOUT as x-data when there is only
%       y-data.
%
%   See also: FIT, EXCLUDEDATA, PREPARESURFACEDATA.

%   Copyright 2011 The MathWorks, Inc.

% Check the number of inputs is two or three and that the number of outputs is
% the same as the number of inputs.
narginchk( 2, 3 );
assertNumOutputsEqualsNumInputs( nargin, nargout );

% When XIN is empty, it needs to replaced by a index vector for YIN
[varargin{1:nargin}] = iEmptyXToIndexVector( varargin{:} );

% The inputs must all have the same number of elements
iAssertInputsHaveSameNumElements( varargin{:} );

% Prepare the data for fitting
[varargout{1:nargin}] = prepareFittingData( varargin{:} );
end

function iAssertInputsHaveSameNumElements( x, y, w )
% iAssertInputsHaveSameNumElements   Ensure that all inputs have the same number
% of elements as each other
if numel( x ) ~= numel( y ) || (nargin == 3 && numel( x ) ~= numel( w ) )
    error(message('curvefit:prepareCurveData:unequalNumel'));
end
end

function [x, y, w] = iEmptyXToIndexVector( x, y, w )
% iEmptyXToIndexVector   If x is empty then replace it by an index vector the
% same size and shape as y.
if isempty( x )
    x = reshape( 1:numel( y ), size( y ) );
end
end

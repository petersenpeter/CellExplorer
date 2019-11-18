function varargout=cftool(varargin)
% CFTOOL   Open Curve Fitting Tool.
%
%   CFTOOL opens Curve Fitting Tool or brings focus to the Tool if it is already
%   open.
%
%   CFTOOL( X, Y ) creates a curve fit to X input and Y output. X and Y must be
%   numeric, have two or more elements, and have the same number of elements.
%   CFTOOL opens Curve Fitting Tool if necessary.
%
%   CFTOOL( X, Y, Z ) creates a surface fit to X and Y inputs and Z output. X, Y,
%   and Z must be numeric, have two or more elements, and have compatible sizes.
%   Sizes are compatible if X, Y, and Z all have the same number of elements or X
%   and Y are vectors, Z is a 2D matrix, length(X) = n, and length(Y) = m where
%   [m,n] = size(Z). CFTOOL opens Curve Fitting Tool if necessary.
%
%   CFTOOL( X, Y, [], W ) creates a curve fit with weights W. W must be numeric
%   and have the same number of elements as X and Y.
%
%   CFTOOL( X, Y, Z, W ) creates a surface fit with weights W. W must be numeric
%   and have the same number of elements as Z.
%
%   CFTOOL( FILENAME ) loads the surface fitting session in FILENAME into Curve
%   Fitting Tool. The FILENAME should have the extension '.sfit'.

%   Copyright 2000-2015 The MathWorks, Inc.

% Get the names of the input arguments
names = cell( nargin, 1 );
for i = 1:nargin
    names{i} = inputname( i );
end

if usingLegacyTool( varargin{:} )
    error( message( 'curvefit:cftool:HasBeenRemoved' ) );
else
    theApplication = iStartSFTOOL( varargin, names );
end

if nargout
    varargout = {theApplication};
end

% ---------------- Start Curve & Surface Fitting Tool
function application = iStartSFTOOL( varaibles, names )
try
    application = sftool_v1( varaibles, names );
catch exception
    throwAsCaller( exception );
end

% ---------------- Does the syntax request legacy v1 Curve Fitting Tool
function tf = usingLegacyTool( varargin )
% usingLegacyTool   True if using legacy v1 Curve Fitting Tool

% If there are no input arguments, then using current tool
if ~nargin
    tf = false;
    
    % If the first argument is '-v1', then using legacy tool
elseif strcmpi( '-v1', varargin{1} )
    tf = true;
    
    % Otherwise, using the current tool
else
    tf = false;
end


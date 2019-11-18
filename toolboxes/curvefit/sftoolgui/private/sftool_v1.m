function out = sftool_v1( arguments, names )
% SFTOOL_V1   Opens Curve Fitting Tool
%
%   SFTOOL_V1( ARGUMENTS, NAMES ) opens Curve Fitting Tool as if it had been
%   called with the command SFTOOL( ARGUMENTS{:} ) but uses NAMES as the input
%   name for the ARGUMENTS.
% 
%   See also CFTOOL.

%   Details of what the command SFTOOL( ARGUMENTS{:} ) should do:
%
%   SFTOOL opens Surface Fitting Tool or brings focus to the Tool if it is
%   already open.
%
%   SFTOOL(X,Y) creates a curve fit to X input and Y output. X and Y must
%   be numeric, have two or more elements, and have the same number of
%   elements. SFTOOL opens Surface Fitting Tool if necessary.
%   
%   SFTOOL(X,Y,[],W) creates a curve fit with weights W. W must be numeric
%   and have the same number of elements as X and Y.
%
%   SFTOOL(X,Y,Z) creates a surface fit to X and Y inputs and Z output. X,
%   Y, and Z must be numeric, have two or more elements, and have
%   compatible sizes. Sizes are compatible if X, Y, and Z all have the same
%   number of elements or X and Y are vectors, Z is a 2D matrix, length(X)
%   = n, and length(Y) = m where [m,n] = size(Z). SFTOOL opens Surface
%   Fitting Tool if necessary.
%   
%   SFTOOL(X,Y,Z,W) creates a surface fit with weights W. W must be numeric
%   and have the same number of elements as Z.
%
%   SFTOOL(FILENAME) loads the surface fitting session in FILENAME into
%   SFTOOL. The FILENAME should have the extension '.sfit'.
%
%   See also CFTOOL.

%   Copyright 2008-2015 The MathWorks, Inc.

iLicenseCheck();

% Try to get the SFTOOL handle from the root
hroot = groot;
h = getappdata( hroot, iSFTOOLAppDataPropertyName() );

% If the SFTOOL handle is not in the root, then we need to create it.
isStartUp = isempty( h ) || ~isa( h, 'handle' ) || ~isvalid( h );
if isStartUp
    % Create the main tool
    h = sftoolgui.sftool;
    sftoolOpened( h );
    
    % Store the handle in the root to preserve it
    setappdata( hroot, iSFTOOLAppDataPropertyName(), h );
    % Listen to the "close" event so that we can remove the handle from the app-data.
    addlistener( h, 'SftoolClosed', @iRemoveSftoolFromAppData );
end

setWaiting(h, true);

% Make SFTOOL visible
selectTool( h );

% Parse inputs for data or name of a session to load
[sessionFile, data] = iParseInputs( arguments, names );

% Handle inputs
if ~isempty( sessionFile )
    % Load session
    h.loadSessionWithFile( sessionFile );
elseif ~isempty( data )
    % Create new fit with this data
    h.HFitsManager.newFit( data );
elseif isStartUp
    % If no session or data is given AND we are starting the tool, then we
    % need to create an empty fit
    h.HFitsManager.newFit( [] );
end

% The GUI should be good to go now...
setWaiting(h, false);

if nargout
    out = [];
end
end

function [sessionFile, data ] = iParseInputs( args, names )
% iParseInputs -- Parse the inputs looking for data or a valid session 
% name. The return arguments will be empty if the appropriate input is not 
% found.
data = [];
sessionFile = '';

% The "bGoodInput " flag indicates that the user has given valid input
nargs = length( args );
switch nargs
    case 1
        if ischar(args{1})
            % SFTOOL( '<session file>' )
            [msg, sessionFile] = iCheckSessionName( args{1} );          
        else
            msg = getString(message('curvefit:cftoolgui:InputMustBeTwoThreeOrFourVariablesOrACurveFittingSes'));
        end
    case {2, 3, 4}
        % SFTOOL( X, Y ) 
        % SFTOOL( X, Y, [] ) or SFTOOL( X, Y, Z )
        % SFTOOL( X, Y, [], W ) or SFTOOL( X, Y, Z, W )
        [msg, data] = iDataFromMultipleInputs( args, names );   
    case 0
        % The only other way to have valid input is if there is no input
        msg = '';
    otherwise
        msg = getString(message('curvefit:cftoolgui:InputMustBeTwoThreeOrFourVariablesOrACurveFittingSes'));
end

if ~isempty( msg )
    msg = sprintf('%s\n\n%s', getString(message('curvefit:cftoolgui:InvalidInputsToCFTOOL')), msg );
    uiwait( warndlg( msg, getString(message('curvefit:cftoolgui:CurveFittingWarning')), 'modal' ) );
end

end

function [msg, sessionFile] = iCheckSessionName( sessionFile )
% iCheckSessionName -- Check that the given string is a valid session name. 
% The return "sessionFile" will either be a valid session filename or
% empty.

% The session is good if it has the extension ".sfit"
[~, ~, extension] = fileparts( sessionFile );
bGoodInput = strcmpi( extension, '.sfit' );

% If the input is not good then we need to return an empty string for the
% session name
if bGoodInput
    msg = '';
else
    sessionFile = '';
    msg = getString(message('curvefit:cftoolgui:SessionNameMustBe'));
end
end

function [msg, data] = iDataFromMultipleInputs( args, names )
% iDataFromMultipleInputs -- Create an sftoolgui.Data object from the input
% arguments.
%
% ARGS is a cell-array of whatever has been passed into SFTOOL. 
% NAMES is a cell-array the same size as ARGS with the names that should be
%   used for the things in ARGS. Elements of NAMES can be empty.
%
% We need to test each element of ARGS for validity, i.e., that they are
% a numeric matrix with more than one element.
%
% If an element of ARGS is invalid we assign that element to [] and assign
% '' to the corresponding element of NAMES.
%
% If an element of ARGS is invalid then we increment the message (MSG) as
% appropriate.

% The following data names will be used in the message.
DATA_NAMES = {getString(message('curvefit:cftoolgui:Xdata')), ...
    getString(message('curvefit:cftoolgui:Ydata')), ...
    getString(message('curvefit:cftoolgui:Zdata')), ...
    getString(message('curvefit:cftoolgui:Weights'))};

% Let's say that we're ok until we see otherwise
msg = '';

% If there are only two input arguments, it is curve data. Add an empty
% third argument.
if length( args ) == 2
    args{end + 1} = [];
    names{end + 1} = '';
end

for i = 1:length( args )
    % The third argument can be []
    if (i==3) && iIsEmptyNumeric( args {i} ) 
        continue;
    elseif ~iIsValidInput( args{i} ) % Test element of ARGS for validity
        % If the element of ARGS is invalid then increment the message (MSG).
        % Get an informative message as to why the data is invalid.
        invalidMessage = iInvalidMessage( args{i}, DATA_NAMES{i});
        msg = sprintf( '%s    %s\n', msg, invalidMessage );
        args{i} = [];
        names{i} = '';
    end
end

data = sftoolgui.Data(args, names);

% If we've generated a warning message, then put something polite at the
% front.
if ~isempty( msg )
    msg = sprintf('%s\n%s', getString(message('curvefit:cftoolgui:InputMustBeNumericWithTwoOrMoreElements')), msg );
end

end

function tf = iIsValidInput( arg )
% iIsValidInput -- Test that an input given at the command-line is valid. To be
% valid it must be a numeric matrix with more than one element.
tf = isa( arg, 'numeric' ) && numel( arg ) > 1;
end

function tf = iIsEmptyNumeric( arg ) 
% iIsEmptyNumeric - Test that an input is empty and numeric. Empty strings
% for instance, should not pass this test.
tf = isempty( arg ) && isnumeric( arg );
end

function msg = iInvalidMessage( arg, name )
    if ~isa( arg, 'numeric' )
        msg = getString(message('curvefit:cftoolgui:IgnoringNotNumeric', name));
    elseif numel( arg ) < 2
        msg = getString(message('curvefit:cftoolgui:IgnoringFewerThanTwoElements', name));
    else
        msg = getString(message('curvefit:cftoolgui:IgnoringInvalid', name));
    end
end

function iLicenseCheck()
% iLicenseCheck -- Check for a license for curve fitting toolbox. Throw an
% error if no license.


if ~builtin( 'license', 'test', 'Curve_Fitting_Toolbox' )
    error(message('curvefit:sftool:noLicense'));
else
    [canCheckout, checkoutMsg] = builtin( 'license', 'checkout', 'Curve_Fitting_Toolbox' );
    if ~canCheckout
        error(message('curvefit:sftool:cannotCheckOutLicense', checkoutMsg));
    end
end
end

function iRemoveSftoolFromAppData( ~, ~ )
% iRemoveSftoolFromAppData   Remove SFTOOL Application Object from app-data of root
%
%   iRemoveSftoolFromAppData( src, evt )
rmappdata( groot, iSFTOOLAppDataPropertyName );
end

function name = iSFTOOLAppDataPropertyName()
% iSFTOOLAppDataPropertyName   Name of the app-data property used to store the
% SFTOOL Application Object.
name = 'SurfaceFittingToolHandle';
end


function ok=sfsession(sftool, action, fn)
%SFSESSION Clear, load, or save a Surface Fitting session

%   Copyright 2008-2011 The MathWorks, Inc.

if nargin<3
    fn = '';
end

% Wrap real function with a try/catch block so we can catch/display
% errors
ok = false;
try
    ok = sfsession1(sftool, action, fn);
catch e
    uiwait(errordlg ...
        (getString(message('curvefit:sftoolgui:UnexpectedErrorOccurred', e.message )),...
        getString(message('curvefit:sftoolgui:CurveFittingTool')),'modal'));
end
end

% --------- Helper function does the real work
function ok=sfsession1(sftool, action, fn)

ok = true;

switch(action)
    % ---- Save current Curve Fitting Tool session
    case 'save'
        ok = iSaveAction(sftool, fn);
        
    % ---- Load Curve Fitting Tool session
    case 'load'
        ok = iLoadAction(sftool, fn);
        
    % ---- Clear current Curve Fitting Tool session
    case 'clear'
        iClearSession(sftool);
        
    % ---- Unexpected action    
    otherwise
        ok = false;
        warning(message('curvefit:sftoolgui:sfsession:UnexpectedAction', action));       
end
end

function iClearSession(sftool)
clearSession(sftool.HFitsManager);
end

function ok = iSaveAction(sftool, fn)
if isempty(fn)
    % Get file name to use, remember the directory name
    filespec = [sftool.SessionPath '*.sfit'];
    [fn,pn] = uiputfile(filespec,getString(message('curvefit:sftoolgui:SaveSession')));
    if isequal(fn,0) || isequal(pn,0)
        ok = false;
        return
    end
    if ~ismember('.',fn)
        fn = [fn '.sfit'];
    end
    sftool.SessionPath = pn;
    fn = [pn fn];
end

savedSession = saveSession(sftool, fn);  %#ok<NASGU>

% Save the session
try
    save(fn, 'savedSession', '-mat');
catch e
    uiwait(errordlg ...
        (getString(message('curvefit:sftoolgui:ErrorSavingSessionFile', ...
        e.message )), getString(message('curvefit:sftoolgui:SaveError')),'modal'))
    ok = false;
    return
end
ok = true;
end

function ok = iLoadAction(sftool, fn)
if isempty(fn)
    % Get file name and load from it, remember the directory name
    filespec = [sftool.SessionPath '*.sfit'];
    [fn,pn] = uigetfile(filespec,getString(message('curvefit:sftoolgui:LoadSession')));
    if isequal(fn,0) || isequal(pn,0)
        ok = false;
        return
    end
    if ~ismember('.',fn)
        fn = [fn '.sfit'];
    end
    fn = [pn fn];
else % a name has been passed in, get the full name and path
    fn = iGetFullFilename(fn);
    pn = fullfile(fileparts(fn),filesep);
end

sftool.SessionPath = pn;

try
    s = load('-mat', fn);
catch e
    uiwait(errordlg ...
        (getString(message('curvefit:sftoolgui:ErrorLoadingSessionFile', e.message )),...
        getString(message('curvefit:sftoolgui:LoadError')),'modal'));
    ok = false;
    return
end

if ~isfield(s, 'savedSession')
    uiwait(errordlg ...
        (getString(message('curvefit:sftoolgui:NotAValidCurveFittingSessionFile')),...
        getString(message('curvefit:sftoolgui:FileInvalid')),'modal'))
    ok = false;
    return
end

if ~isa(s.savedSession, 'sftoolgui.Session')
    uiwait(errordlg ...
        (getString(message('curvefit:sftoolgui:NotAValidCurveFittingSessionFile')),...
        getString(message('curvefit:sftoolgui:FileInvalid')),'modal'))
    ok = false;
    return
end

iClearSession(sftool);
loadSession(sftool, s.savedSession, fn);
ok = true;
end

function filename = iGetFullFilename(filename)
% iGetFullname returns a name with a complete path

% We need to determine whether we have a full path or a path relative to
% the current directory.

% First, find a name assuming it is relative to the current path.
fullFilename = fullfile(pwd, filename);

% Then test to see if it exists.
if exist(fullFilename, 'file') == 2
    % If it exists, return that name.
    filename = fullFilename;
end
% Otherwise, assume filename includes a full path. (Its validity is checked
% when we try to load it.)
end

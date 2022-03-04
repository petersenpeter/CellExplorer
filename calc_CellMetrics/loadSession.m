function session = loadSession(basepath,basename,varargin)
% Loads the session struct from existing basename.session.mat file from basepath. If no  basepath is providede it will try to load from current directory
% If the basename.session.mat is not available the session struct will be generated using the sessionTemplate script.
% Part of CellExplorer
% 
% - Example calls:
% session = sessionTemplate; % Load session from session struct
% session = sessionTemplate(basepath); % Load session from session struct
% session = sessionTemplate(basepath,basename,'showGUI',true); % Load session from session struct

p = inputParser;
addOptional(p,'basepath',[],@isstr);
addOptional(p,'basename',[],@isstr);
addParameter(p,'showGUI',false,@islogical); % Show the session gui
addParameter(p,'sessionTemplate',true,@islogical); % Generates a session struct using the session-template script

% Parsing inputs
parse(p,varargin{:})
parameters = p.Results;

% Setting current folder as basepath if not provided
if ~exist('basepath','var')
    basepath = pwd;
end

% Determining the basename if not provided
if ~exist('basename','var')
    basename = basenameFromBasepath(basepath);
end

file = fullfile(basepath,[basename,'.session.mat']);
if exist(file,'file')
    % Loads an existing session struct from the basepath: basename.session.mat
    load(fullfile(basepath,[basename,'.session.mat']),'session')
elseif parameters.sessionTemplate
    % Generates the session struct using the sessionTemplate script if no file exist
    session = sessionTemplate(basepath,'basename',basename);
else
    % Returns an error
    error('No session file exist')
end

session.general.basePath = basepath;

% Shows session GUI if requested by user
if parameters.showGUI
    session = gui_session(session);
end
function sessions_out = db_load_sessions(varargin)
% Loads session metadata from the buzsakilab database

% Check the website of the CellExplorer for more details: https://cellexplorer.org/

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 30-01-2020

p = inputParser;
addParameter(p,'sessionId',[],@isnumeric);
addParameter(p,'sessionName','',@isstr);
addParameter(p,'sessions','',@iscell);
addParameter(p,'animal','',@isstr);
addParameter(p,'details','1',@isstr);
addParameter(p,'db_settings',db_load_settings,@isstr);
parse(p,varargin{:})

sessionId = p.Results.sessionId;
sessionName = p.Results.sessionName;
sessions = p.Results.sessions;
animal = p.Results.animal;
details = p.Results.details;
db_settings = p.Results.db_settings;
sessions_out = [];

options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'RequestMethod','get','Timeout',50,'CertificateFilename','');


if ~isempty(animal)
    bz_db = webread([db_settings.address,'views/15274/'],options,'animal',animal,'details',details);
elseif ~isempty(sessionName)
    bz_db = webread([db_settings.address,'views/15274/'],options,'session',sessionName,'details',details);
elseif ~isempty(sessions)
    bz_db = webread([db_settings.address,'views/15274/'],options,'session',sessions,'details',details);
elseif ~isempty(sessionId)
    bz_db = webread([db_settings.address,'views/15274/'],options,'entryid',sessionId,'details',details);
else
    bz_db = webread([db_settings.address,'views/15274/'],options,'details',details);
end

test = bz_db.renderedHtml;
if ~strcmp(test,'<div class="frm_no_entries">No Entries Found</div>')
    str_test = strfind(test,',]');
    str_test2 = strfind(test,',}');
    test([str_test,str_test2]) = [];
    sessions_out = loadjson(test);
else
    warning('No Entries Found in the database with select criteria');
end

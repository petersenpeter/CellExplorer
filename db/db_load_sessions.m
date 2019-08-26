function sessions_out = db_load_sessions(varargin)
p = inputParser;
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session','',@isstr);
addParameter(p,'sessions','',@iscell);
addParameter(p,'animal','',@isstr);
addParameter(p,'details','1',@isstr);
addParameter(p,'db_settings',db_load_settings,@isstr);
parse(p,varargin{:})

id = p.Results.id;
session = p.Results.session;
sessions = p.Results.sessions;
animal = p.Results.animal;
details = p.Results.details;
db_settings = p.Results.db_settings;
% db_settings = db_load_settings
sessions_out = [];

options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'RequestMethod','get','Timeout',50);
options.CertificateFilename=('');


if ~isempty(animal)
    bz_db = webread([db_settings.address,'views/15274/'],options,'animal',animal,'details',details);
elseif ~isempty(session)
    bz_db = webread([db_settings.address,'views/15274/'],options,'session',session,'details',details);
elseif ~isempty(sessions)
    bz_db = webread([db_settings.address,'views/15274/'],options,'session',sessions,'details',details);
elseif ~isempty(id)
    bz_db = webread([db_settings.address,'views/15274/'],options,'entryid',id,'details',details);
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

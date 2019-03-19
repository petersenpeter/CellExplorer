function sessions_out = db_load_sessions(varargin)
p = inputParser;
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session','',@isstr);
addParameter(p,'sessions','',@iscell);
addParameter(p,'animal','',@isstr);
addParameter(p,'details','1',@isstr);
addParameter(p,'bz_database',db_credentials,@isstr);
parse(p,varargin{:})

id = p.Results.id;
session = p.Results.session;
sessions = p.Results.sessions;
animal = p.Results.animal;
details = p.Results.details;
bz_database = p.Results.bz_database;

sessions_out = [];

options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'RequestMethod','get','Timeout',50);
options.CertificateFilename=('');
if ~isempty(animal)
    bz_db = webread([bz_database.rest_api.address,'views/15274/'],options,'animal',animal,'details',details);
elseif ~isempty(session)
    bz_db = webread([bz_database.rest_api.address,'views/15274/'],options,'session',session,'details',details);
elseif ~isempty(sessions)
    bz_db = webread([bz_database.rest_api.address,'views/15274/'],options,'session',sessions,'details',details);
elseif ~isempty(id)
    bz_db = webread([bz_database.rest_api.address,'views/15274/'],options,'entryid',id,'details',details);
else
    bz_db = webread([bz_database.rest_api.address,'views/15274/'],options,'details',details);
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

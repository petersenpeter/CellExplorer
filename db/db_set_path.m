function [session,basename, basepath,clusteringpath] = db_set_path(varargin)

p = inputParser;
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'sessionstruct',[],@isstruct);

parse(p,varargin{:})
id = p.Results.id;
sessionin = p.Results.session;
sessionstruct = p.Results.sessionstruct;

basename = ''; 
basepath = ''; 
clusteringpath = '';

if ~isempty(id)
    sessions = db_load_sessions('id',id);
    session = sessions{1};
elseif ~isempty(sessionin)
    sessions = db_load_sessions('session',sessionin);
    session = sessions{1};
else
    session = sessionstruct;
end

db_database = db_credentials;
cd(fullfile(db_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name))
% session = bz_update_session(session);
%     save('session.mat','session')
basename = session.General.Name;
basepath = fullfile(db_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name);

if ~isempty(session.SpikeSorting.RelativePath)
    clusteringpath = fullfile(db_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name, session.SpikeSorting.RelativePath{1});
else
    clusteringpath = basepath;
end

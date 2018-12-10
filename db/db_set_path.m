function [session,basename, basepath,clusteringpath] = db_set_path(varargin)

p = inputParser;
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'sessionstruct',[],@isstruct);
addParameter(p,'saveMat',true,@islogical);
parse(p,varargin{:})
id = p.Results.id;
sessionin = p.Results.session;
sessionstruct = p.Results.sessionstruct;
saveMat = p.Results.saveMat;

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
defined_repositories = fieldnames(db_database.repositories);
if ~contains(defined_repositories,{session.General.Repositories{1}})
   warning(['The repository has not been defined. Please specify the path for ' session.General.Repositories{1},' in db_credentials.m']);
   edit db_credentials
   return
end
cd(fullfile(db_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name))

if saveMat
    save('session.mat','session')
end
basename = session.General.Name;
basepath = fullfile(db_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name);

if ~isempty(session.SpikeSorting.RelativePath)
    clusteringpath = fullfile(db_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name, session.SpikeSorting.RelativePath{1});
else
    clusteringpath = basepath;
end
session.General.BaseName = basename;
session.General.BasePath =  basepath;
session.General.ClusteringPath = clusteringpath;

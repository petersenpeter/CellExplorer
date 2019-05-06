function [session,basename, basepath,clusteringpath] = db_set_path(varargin)

p = inputParser;
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'sessionstruct',[],@isstruct);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'changeDir',true,@islogical);

parse(p,varargin{:})

id = p.Results.id;
sessionin = p.Results.session;
sessionstruct = p.Results.sessionstruct;
saveMat = p.Results.saveMat;
changeDir = p.Results.changeDir;

if ~isempty(id)
    sessions = db_load_sessions('id',id);
    if isempty(sessions)
        return
    end
%     session = sessions{1};
elseif ~isempty(sessionin)
    sessions = db_load_sessions('session',sessionin);
    if isempty(sessions)
        return
    end
%     session = sessions{1};
else
    sessions{1} = sessionstruct;
end

db_database = db_credentials;
defined_repositories = fieldnames(db_database.repositories);

for i = 1:length(sessions)
    session = sessions{i};
    if ~contains(defined_repositories,{session.general.repositories{1}})
        warning(['The repository has not been defined. Please specify the path for ' session.general.repositories{1},' in db_credentials.m']);
        edit db_credentials
        return
    end
    
    basename = session.general.name;
    if strcmp(session.general.repositories{1},'NYUshare_Datasets')
        Investigator_name = strsplit(session.general.investigator,' ');
        path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
        basepath = fullfile(db_database.repositories.(session.general.repositories{1}), path_Investigator,session.general.animal, session.general.name);
    else
        basepath = fullfile(db_database.repositories.(session.general.repositories{1}), session.general.animal, session.general.name);
    end
    
    if ~isempty(session.spikeSorting.relativePath)
        clusteringpath = fullfile(basepath, session.spikeSorting.relativePath{1});
    else
        clusteringpath = basepath;
    end
    session.general.baseName = basename;
    session.general.basePath =  basepath;
    session.general.clusteringPath = clusteringpath;
    
    if changeDir
        cd(basepath)
    end
    
    if saveMat
        [stat,mess]=fileattrib(fullfile(basepath, 'session.mat'));
        if stat==0
            try
                save(fullfile(basepath, 'session.mat'),'session');
            catch
                warning('Failed to save session.mat. Location not available');
            end
        elseif mess.UserWrite
            save(fullfile(basepath, 'session.mat'),'session');
        else
            warning('Unable to write to session.mat. No writing permissions.');
        end
    end
    if length(sessions)>1
        sessions{i} = session;
        basepaths{i} = basepath;
        clusteringpaths{i} = clusteringpath;
        basenames{i} = basename;
    end
end
if length(sessions)>1
    session = sessions;
    basepath = basepaths;
    clusteringpath = clusteringpaths;
    basename = basenames;
end

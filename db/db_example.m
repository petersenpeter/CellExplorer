% Load meta data for single session

sessionName = 'Peter_MS10_170307_154746_concat';
sessions = db_load_sessions('session',sessionName);
session = sessions{1};


%% % % % % % % % % % % % % % % % % % % % % %
% Load and set session parameters

[session, basename, basepath, clusteringpath] = db_set_path('session',sessionName);


%% % % % % % % % % % % % % % % % % % % % % %
% Example as to loading spikes from database 

sessionName = 'Rat08-20130708';
[session, basename, basepath, clusteringpath] = db_set_path('session',sessionName);
spikes = loadClusteringData(session.General.Name,session.SpikeSorting.Format{1},clusteringpath);


%% % % % % % % % % % % % % % % % % % % % % %
% Load all aninals in database with related meta data

animals = db_load_table('animals');


%% % % % % % % % % % % % % % % % % % % % % %
% Load all silicon probes

siliconprobes = db_load_table('siliconprobes'); % Examples: siliconprobes, projects, 


%% % % % % % % % % % % % % % % % % % % % % %
% Load meta data for multiple session

animalName = 'MS12';
sessions = db_load_sessions('animal',animalName);


%% % % % % % % % % % % % % % % % % % % % % %
% Save meta data from data to database

session = db_update_session(session,'forceReload',true)

%% % Get brain regions

chListBrainRegions = findBrainRegion(session);

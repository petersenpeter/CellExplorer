% Load meta data for single session
% Please provide your credentials and define relevant local paths before running these examples:
% edit db_credentials
% edit db_local_repositories

sessionName = 'Rat08-20130708';
sessions = db_load_sessions('sessionName',sessionName);
session = sessions{1};

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Load and set session parameters

[session, basename, basepath, clusteringpath] = db_set_session('sessionName',sessionName);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Inspecting and editing local session metadata

session = gui_session(session);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Load all aninals in database with related meta data

animals = db_load_table('animals');

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Load all silicon probes

siliconprobes = db_load_table('siliconprobes'); % Examples: siliconprobes, projects


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Save meta data from data to database

session = db_update_session(session,'forceReload',true);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Example as to loading spikes via database/metadata

spikes = loadSpikes('session',session);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Running the Cell Explorer pipeline via the db

cell_metrics = calc_CellMetrics('sessionName',sessionName);
cell_metrics = CellExplorer('metrics',cell_metrics);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Running the Cell Explorer directly via the db

cell_metrics = CellExplorer('sessionName',sessionName);

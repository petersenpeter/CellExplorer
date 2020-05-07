%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Load meta data for single session
% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Please provide your credentials and define relevant local paths before running these examples:
edit db_credentials
edit db_local_repositories

%% Load session from db

sessionName = 'Peter_MS13_171129_105507_concat';
sessions = db_load_sessions('sessionName',sessionName);
session = sessions{1}

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

session = db_upload_session(session);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Example as to loading spikes via database/metadata

spikes = loadSpikes('session',session);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Running the CellExplorer pipeline via the db

cell_metrics = ProcessCellMetrics('sessionName',sessionName);
cell_metrics = CellExplorer('metrics',cell_metrics);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Running the CellExplorer directly via the db

cell_metrics = CellExplorer('sessionName',sessionName);

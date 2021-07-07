% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Tutorial for running CellExplorer on your own data from a basepath
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%  1. Define the basepath of the dataset to run. The dataset should at minimum consist of the raw data and spike sorted data.
basepath = '/your/data/path/basename/';
cd(basepath)

%% 2. Generate session metadata struct using the template function and display the meta data in a gui
session = sessionTemplate(pwd,'showGUI',true);

% You can also inspect the session struct by calling the GUI directly:
% session = gui_session(session);

% And validate the required and optional fields
validateSessionStruct(session);

%% 3.1.1 Run the cell metrics pipeline 'ProcessCellMetrics' using the session struct as input
cell_metrics = ProcessCellMetrics('session', session);

%% 3.1.2 Visualize the cell metrics in CellExplorer
cell_metrics = CellExplorer('metrics',cell_metrics); 

%% 3.2 Open several session from basepaths
basepaths = {'/your/data/path/basename_1/','/your/data/path/basename_2/'};
cell_metrics = loadCellMetricsBatch('basepaths',basepaths);
cell_metrics = CellExplorer('metrics',cell_metrics);

%% 4. load a subset of units fullfilling multiple of criterium

% Get cells that are assigned as 'Interneuron'
cell_metrics_idxs1 = loadCellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Interneuron'});

% Get cells that are have a tag 'InverseSpike' or 'Good' and are assigned as 'Interneuron'
cell_metrics_idxs2 = loadCellMetrics('cell_metrics',cell_metrics,'tags',{'InverseSpike','Good'},'putativeCellType',{'Interneuron'});

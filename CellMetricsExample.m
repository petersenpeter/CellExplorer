% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
 % Running the Cell Explorer on your own data from a basepath
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% 1. Define basepath of your dataset to run. This folder should contain at minimum a basename.dat and a basename.xml.
basepath = '/Volumes/buzsakilab/peterp03/IntanData/MS10/Peter_MS10_170307_154746_concat';
cd(basepath)

% 2. Generate session metadata struct using the template function
session = sessionTemplate;

% 3. Run the cell metrics pipeline 'calc_CellMetrics' using the session struct as input
cell_metrics = calc_CellMetrics('session', session);

% 4. Visualize the cell metrics in the Cell Explorer
cell_metrics = CellExplorer('metrics',cell_metrics);

%% % Open several session from paths

basenames = {'Rat08-20130708','Rat08-20130708'};
clusteringpaths = {'/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708','/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708'};
cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths,'basenames',basenames);
cell_metrics = CellExplorer('metrics',cell_metrics);


%% % load a subset of units fullfilling multiple of criterium

% Get cells that are assigned as 'Interneuron'
cell_metrics_idxs = loadCellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Interneuron'});

% Get cells that are has groundTruthClassification as 'Axoaxonic'
cell_metrics_idxs = loadCellMetrics('cell_metrics',cell_metrics,'groundTruthClassification',{'Axoaxonic'});


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Running the Cell Explorer from the database
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% 0. Define your credentials and local repositories by editing the two files:
% edit db_credentials
% edit db_local_repositories

% 1. Define sessionName/basename your dataset to run and load session meta data struct. This data folder should contain at minimum a basename.dat and a basename.xml.
sessionName = 'R2W3_10A2_20191002';

% 3. Run the cell metrics pipeline 'calc_CellMetrics' using the session struct as input
cell_metrics = calc_CellMetrics('sessionName', session);

% 4. Visualize the cell metrics in the Cell Explorer
cell_metrics = CellExplorer('metrics',cell_metrics);

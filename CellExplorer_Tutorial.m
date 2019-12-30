% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Tutorial for running the Cell Explorer on your own data from a basepath
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%  1. Define the basepath of the dataset to run. The dataset should at minimum consist of a basename.dat, a basename.xml and spike sorted data.
% basepath = '/your/data/path/basename/';
cd(basepath)

%% 2. Generate session metadata struct using the template function and display the meta data in a gui
session = sessionTemplate(pwd,'showGUI',true);

%% 3. Run the cell metrics pipeline 'calc_CellMetrics' using the session struct as input
cell_metrics = calc_CellMetrics('session', session);

%% 4. Visualize the cell metrics in the Cell Explorer
cell_metrics = CellExplorer('metrics',cell_metrics); 

%% 5. Open several session from paths
basenames = {'Rat08-20130708','Rat08-20130709'};
clusteringpaths = {'/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708','/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130709'};
cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths,'basenames',basenames);
cell_metrics = CellExplorer('metrics',cell_metrics);

%% 6. load a subset of units fullfilling multiple of criterium

% Get cells that are assigned as 'Interneuron'
cell_metrics_idxs1 = loadCellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Interneuron'});

% Get cells that are has groundTruthClassification as 'Axoaxonic'
cell_metrics_idxs2 = loadCellMetrics('cell_metrics',cell_metrics,'groundTruthClassification',{'Axoaxonic'});


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Tutorial for running the Cell Explorer from the Buzsaki lab database
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%  1. Define your credentials and local repositories by editing the two files:
edit db_credentials.m
edit db_local_repositories.m

%% 2. Define sessionName/basename of a dataset existing in the database. The dataset should at minimum consist of a sessionName.dat, a sessionName.xml and spike sorted data.
sessionName = 'Rat08-20130708';

%% 3. Run the cell metrics pipeline using the session name as input
cell_metrics = calc_CellMetrics('sessionName', sessionName);

%% 4. Visualize the cell metrics in the Cell Explorer
cell_metrics = CellExplorer('metrics',cell_metrics);


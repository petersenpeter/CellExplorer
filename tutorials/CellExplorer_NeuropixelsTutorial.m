% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% CellExplorer Tutorial
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%%  1. Generate session metadata struct using the template script and display the metadata in the session gui

% Neuropixels recording from a pilot study from a rat (384 channels, 200GB, ~2.5 hours)
basepath = '/Volumes/Peter_SSD_4/NeuropixelsData/PP02/PP02_2020-07-10';
cd(basepath)

% PP02_2020-07-10.dat       : raw data
% rez.mat                   : metadata from KiloSort
% PP02_2020-07-10.xml       : metadata from NeuroSuite
% *.npy and *.tsv files 	: Spike data from Phy

% Run a template script to generate and import relevant session-level metadata
session = sessionTemplate(basepath);

% View the session struct with the session-GUI:
session = gui_session(session);

% You can validate that all required and optional fields for CellExplorer has been entered
% validateSessionStruct(session);


%% 2 Run the cell metrics pipeline 'ProcessCellMetrics' using the session struct as input

cell_metrics = ProcessCellMetrics('session', session,'excludeMetrics',{'monoSynaptic_connections'},'showWaveforms',false,'sessionSummaryFigure',false);

% Several files are generated here
%
% basename.cell_metrics.cellinfo.mat    : cell_metrics
% basename.session.mat                  : session-level metadata
% basename.spikes.cellinfo.mat          : spikes struct
%
% All files and structs are documented on the CellExplorer website:
% https://cellexplorer.org/datastructure/data-structure-and-format/
%
% Once created the files can be loaded with dedicated scripts
% session = loadSession;
% cell_metrics = loadCellMetrics;
% spikes = loadSpikes;

%% 3.1 Visualize the cell metrics in CellExplorer

cell_metrics = CellExplorer('metrics',cell_metrics);


%% 3.2 Batch of sessions from Mice and rats (3686 cells from 111 sessions)

load('/Volumes/Peter_SSD_4/cell_metrics/cell_metrics_peter_viktor.mat');
cell_metrics = CellExplorer('metrics',cell_metrics);


%% 3.3 Work with several sessions (batch-mode)

basepaths = {'/your/data/path/basename1/','/your/data/path/basename2/'};
basenames = {'basename1','basename2'};

cell_metrics = loadCellMetricsBatch('basepaths',basepaths,'basenames',basenames);

cell_metrics = CellExplorer('metrics',cell_metrics);


%% 4.1 NeuroScope2: Two 6-shank silicon probes implanted bilaterally in CA1 (128 channels; 150 cells)

cd('/Volumes/Peter_SSD_4/CellExplorerTutorial/MS22/Peter_MS22_180629_110319_concat');
NeuroScope2


%% 4.2 NeuroScope2: Inspect Neuropixels data

cd('/Volumes/Peter_SSD_4/NeuropixelsData/PP01/PP01_2020-06-29_13-15-57');
NeuroScope2


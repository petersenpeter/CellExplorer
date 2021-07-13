% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% NWB CellExplorer Tutorial
% 
% NWB container file instead of Matlab's .mat file for the cell metrics
% The tutorial extend the general tutorial 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%  1. Define the basepath of the dataset to run. The dataset should at minimum consist of the raw data and spike sorted data.
basepath = '/your/data/path/basename/';
cd(basepath)

%% 2. Generate session metadata struct using the template function and display the meta data in a gui:
session = sessionTemplate(pwd,'showGUI',true);

% You can also inspect the session struct by calling the GUI directly:
% session = gui_session(session);

% Now validate the required and optional fields
validateSessionStruct(session);

%% 3. Run the cell metrics pipeline 'ProcessCellMetrics' using the session struct as input
cell_metrics = ProcessCellMetrics('session', session,'showGUI',true);

%% 4. Visualize the cell metrics in CellExplorer
cell_metrics = CellExplorer('metrics',cell_metrics); 

%% 5. Export cell_metrics to NWB

% nwb file name following the CellExplorer filename convention
nwb_file = [cell_metrics.general.basename,'.cell_metrics.cellinfo.nwb'];

% Generate the nwb file
nwb = saveCellMetrics2nwb(cell_metrics,nwb_file);

% Load cell_metrics from NWB
cell_metrics = loadNwbCellMetrics(nwb_file);

% Now you may run CellExplorer: 
cell_metrics = CellExplorer('metrics',cell_metrics);

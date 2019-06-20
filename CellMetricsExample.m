% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Cell metrics examples
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%
% This script shows a couple of examples for how to:
% 1. Calculating cell metrics
% 2. Launch the Cell Explorer from calculated cell metrics
% 3. Getting subset/filter cell metrics

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 18-06-2019

%%  % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Calculating cell metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

%% Batch Cell metrics from DB
sessionNames = {'20190402_RF_EphysU_R02_session01'}; % Add further sessions if needed
for iii = 1:length(sessionNames)
    disp(['*** Processing cells metrics: ', num2str(iii),'/', num2str(length(sessionNames)),' sessions: ' sessionNames{iii}])
    cell_metrics = calc_CellMetrics('session',sessionNames{iii},'submitToDatabase', true,'plots',false,'useNeurosuiteWaveforms',false);
end

%% % Cell metrics for single session
cd('Z:\valerm05\fNos6\fNos6_190210_sess4')
cell_metrics = calc_CellMetrics('sessionStruct',sessionTemplate);


%%  % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Launch the Cell Explorer from calculated cell metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% Launch the CellExplorer from a list of sessions (using the database)
sessionNames = {'YMV01_170818','YMV02_170815','YMV03_170818','YMV04_170907','YMV05_170912','YMV06_170913','YMV07_170914','YMV08_170922','YMV09_171204','YMV10_171213','YMV11_171208','YMV12_171211','YMV13_180127','YMV14_180128','YMV15_180205','YMV16_180206','YMV17_180207','YMV18_180208','YMV19_180209'};
cell_metrics = LoadCellMetricBatch('sessions',sessionNames);
cell_metrics = CellExplorer('metrics',cell_metrics);

%% % Launch the CellExplorer from a list of paths
clusteringpaths = {'path1','path2','path3'}
cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths);
cell_metrics = CellExplorer('metrics',cell_metrics);


%%  % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Getting subset/filter cell metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Get a subset of units fullfilling multiple of criterium
cell_metrics_idxs = get_CellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Pyramidal'});

%% % Get list of cell from a session labeled as Pyramidal cells
sessionNames = {'20190402_RF_EphysU_R02_session01'};
cell_metrics = LoadCellMetricBatch('sessions',sessionNames);
PyramidalIndexes = find(contains(cell_metrics.putativeCellType,'Pyramidal'));

%% % Finally you can do 1) load cell_metrics and 2) apply filter operation in one line
sessionNames = {'20190402_RF_EphysU_R02_session01'};
[cell_metrics_idxs, cell_metrics] =  get_CellMetrics('sessions',sessionNames,'putativeCellType',{'Pyramidal'});

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Calculating cell metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

sessionNames = {'20190402_RF_EphysU_R02_session01'};

%% Batch Cell metrics from DB
for iii = 1:length(sessionNames)
    disp(['*** Processing cells metrics: ', num2str(iii),'/', num2str(length(sessionNames)),' sessions: ' sessionNames{iii}])
    cell_metrics = calc_CellMetrics('session',sessionNames{iii},'submitToDatabase', true,'plots',false,'useNeurosuiteWaveforms',false); % ,'submitToDatabase', true, 'metrics','ACG_metrics','forceReload',true
end


%% % Cell metrics for single session
calc_CellMetrics_sessionStruct
cell_metrics = calc_CellMetrics('sessionStruct',calc_CellMetrics_sessionStruct,'metrics','DeepSuperficial','forceReload',true); % ,'plots',false,'forceReload',true


%%  % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Launch the Cell Explorer from calculated cell metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

sessionNames = {'YMV01_170818','YMV02_170815','YMV03_170818','YMV04_170907','YMV05_170912','YMV06_170913','YMV07_170914','YMV08_170922','YMV09_171204','YMV10_171213','YMV11_171208','YMV12_171211','YMV13_180127','YMV14_180128','YMV15_180205','YMV16_180206','YMV17_180207','YMV18_180208','YMV19_180209'};
cell_metrics = LoadCellMetricBatch('sessions',sessionNames);
cell_metrics = CellExplorer('metrics',cell_metrics);

%%  % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Getting subset/filter cell metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Get a subset of units fullfilling multiple of criterium
cell_metrics_idxs = get_CellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Inter','Pyr'});

%% % Get list of cell from a session labeled as Pyramidal cells
cell_metrics = LoadCellMetricBatch('sessions',{recording.name});
PyramidalIndexes = find(contains(cell_metrics.putativeCellType,'Pyramidal'));

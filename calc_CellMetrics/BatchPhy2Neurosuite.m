% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Preprocess and calculate cell metrics from KiloSort processed data using the KiloSortWrapper
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

%% % Batch Phy2Neurosuite from DB
sessionNames = {'PeterP-2013-09-04'};
for iii = 1:length(sessionNames)
    disp(['*** Phy2Neurosuite: ', num2str(iii),' of ', num2str(length(sessionNames)),' sessions'])
    [session, basename, basepath, clusteringpath] = db_set_path('session',sessionNames{iii});
%     cd(basepath)
    Phy2Neurosuite(basepath,clusteringpath)
end

%% Batch Cell metrics from DB
for iii = 1:length(sessionNames)
    disp(['*** Processing cells metrics: ', num2str(iii),'/', num2str(length(sessionNames)),' sessions: ' sessionNames{iii}])
    cell_metrics = calc_CellMetrics('session',sessionNames{iii}); % ,'plots',false,'submitToDatabase', true, 'metrics','ACG_metrics','forceReload',true
%     close all
end

%% % Single session Phy2Neurosuite from path
basepath = 'Z:\Buzsakilabspace\PeterPetersen\IntanData\MS21\Peter_MS21_180808_115125_concat';
clusteringpath = 'Z:\Buzsakilabspace\PeterPetersen\IntanData\MS21\Peter_MS21_180808_115125_concat\Kilosort_2018-08-09_143633';
cd(basepath)
Phy2Neurosuite(basepath,clusteringpath)

%% % Cell metrics for single session
calc_CellMetrics_sessionStruct
cell_metrics = calc_CellMetrics('sessionStruct',calc_CellMetrics_sessionStruct,'metrics','DeepSuperficial','forceReload',true); % ,'plots',false,'forceReload',true

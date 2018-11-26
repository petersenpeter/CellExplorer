% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Preprocess and calculate cell metrics from KiloSort processed data using the KiloSortWrapper

%% % Batch session from DB
bz_database = db_credentials;
sessionNames = {'ham31_103-110_amp'};
for iii = 1:length(sessionNames)
    disp(['*** Phy2Neurosuite: ', num2str(iii),' of ', num2str(length(sessionNames)),' sessions'])
    [session, basename, basepath, clusteringpath] = db_set_path('session',sessionNames{iii});
%     cd(basepath)
    Phy2Neurosuite(basepath,clusteringpath)
end

%% Batch update unit metrics
for iii = 1:length(sessionNames)
    disp(['*** Processing cells metrics: ', num2str(iii),' of ', num2str(length(sessionNames)),' sessions'])
    cell_metrics = calc_CellMetrics('session',sessionNames{iii},'metrics','all'); % ,'plots',false,'forceReload',true
end

%% % Single session from paths
basepath = 'Z:\Buzsakilabspace\PeterPetersen\IntanData\MS21\Peter_MS21_180808_115125_concat';
clusteringpath = 'Z:\Buzsakilabspace\PeterPetersen\IntanData\MS21\Peter_MS21_180808_115125_concat\Kilosort_2018-08-09_143633';
cd(basepath)
Phy2Neurosuite(basepath,clusteringpath)

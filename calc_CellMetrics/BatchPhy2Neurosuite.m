% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Preprocess and calculate cell metrics from KiloSort processed data using the KiloSortWrapper
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

%% % Batch Phy2Neurosuite from DB
sessionNames = {'Peter_MS10_170317_153237_concat','Peter_MS10_170314_163038','Peter_MS10_170315_123936','Peter_MS10_170307_154746_concat'};
% TODO: % MS10: 61 (Peter_MS10_170317_153237_concat), 62 (Peter_MS10_170314_163038), 63 (Peter_MS10_170315_123936), 64 (Peter_MS10_170307_154746_concat), 

sessionNames = {'20190402_RF_EphysU_R02_session01'};

for iii = 1:length(sessionNames)
    disp(['*** Phy2Neurosuite: ', num2str(iii),' of ', num2str(length(sessionNames)),' sessions'])
    [session, basename, basepath, clusteringpath] = db_set_session('sessionName',sessionNames{iii});
    Phy2Neurosuite(basepath,clusteringpath)
end

%% % Single session Phy2Neurosuite from path
basepath = 'Z:\Buzsakilabspace\PeterPetersen\IntanData\MS21\Peter_MS21_180808_115125_concat';
clusteringpath = 'Z:\Buzsakilabspace\PeterPetersen\IntanData\MS21\Peter_MS21_180808_115125_concat\Kilosort_2018-08-09_143633';
cd(basepath)
Phy2Neurosuite(basepath,clusteringpath)

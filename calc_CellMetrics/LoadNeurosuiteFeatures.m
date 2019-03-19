function PCA_features = LoadNeurosuiteFeatures(spikes,session,timeRestriction)%(,basename,sr,timeRestriction)
disp('Loading Neurosuite waveforms')
% clusteringpath = 'Z:\Buzsakilabspace\PeterPetersen\IntanData\MS21\Peter_MS21_180718_103455_concat\Kilosort_2018-08-29_165108';
% basename = 'Peter_MS21_180718_103455_concat';


% spike_cluster_index = double(readNPY(fullfile(clusteringpath, 'spike_clusters.npy')));
% spike_clusters = unique(spike_cluster_index);
% if exist(fullfile(clusteringpath, 'cluster_ids.npy'))
%     cluster_ids = readNPY(fullfile(clusteringpath, 'cluster_ids.npy'));
%     unit_shanks = readNPY(fullfile(clusteringpath, 'shanks.npy'));
% end
% spikeGroups = unique(unit_shanks);

% fileID = fopen(fullfile(clusteringpath, 'cluster_group.tsv'));
% good_units = textscan(fileID,'%d %s','Delimiter','\t','HeaderLines',1);
% fclose(fileID);
% accepted_units = good_units{1}(find(strcmp({good_units{2}{:}},'good')));
% 

sr = session.extracellular.sr;
basename = session.general.baseName;
clusteringpath = session.general.clusteringPath;
spikeGroups = unique(spikes.shankID);


SpikeFeatures = [];
isolationDistance = [];
lRatio = [];
cluID = [];
UID = [];

for i = 1:length(spikeGroups)
    spikeGroup = spikeGroups(i);
    accepted_units = spikes.cluID(spikes.shankID ==spikeGroup);
    accepted_units2 = spikes.UID(spikes.shankID ==spikeGroup);
    disp(['Loading spike group ' num2str(spikeGroup)])
    cluster_index = load(fullfile(clusteringpath, [basename '.clu.' num2str(spikeGroup)]));
    cluster_index = cluster_index(2:end);

   % Load .fet file
    filename = fullfile(clusteringpath,[basename '.fet.' num2str(spikeGroup)]);
    if ~exist(filename)
        error(['File ''' filename ''' not found.']);
    end
    file = fopen(filename,'r');
    if file == -1
        error(['Cannot open file ''' filename '''.']);
    end
    nFeatures = fscanf(file,'%d',1);
    fet = fscanf(file,'%f',[nFeatures,inf])';
    fclose(file);

    if ~isempty(timeRestriction)
        time_stamps = load(fullfile(clusteringpath,[basename '.res.' num2str(spikeGroup)]));
        indeces2keep = find(any(time_stamps./sr >= timeRestriction(:,1)' & time_stamps./sr <= timeRestriction(:,2)', 2));
%         time_stamps = time_stamps(indeces2keep);
        cluster_index = cluster_index(indeces2keep);
        fet = fet(indeces2keep,:);
    end
    
    clusters = unique(cluster_index);
    clusters = accepted_units(find(ismember(accepted_units,clusters)));
    clusters2 = accepted_units2(find(ismember(accepted_units,clusters)));
    indexes = find(ismember(cluster_index, clusters));
    SpikeFeatures = fet(indexes,1:end-1);
    cluster_index = cluster_index(indexes);
    
    [isolation_distance1,isolation_distance_accepted] = calc_IsolationDistance(SpikeFeatures,cluster_index,-1);
    [L_ratio1,L_ratio_accepted] = L_ratio_calc(SpikeFeatures,cluster_index,-1);
    
    isolationDistance = [isolationDistance;isolation_distance1];
    lRatio = [lRatio;L_ratio1];
    cluID = [cluID,clusters];
    UID = [UID,clusters2];
end
PCA_features = [];
PCA_features.isolationDistance = isolationDistance;
PCA_features.lRatio = lRatio;
PCA_features.cluID = cluID;
PCA_features.UID = UID;
            
figure, subplot(2,1,1)
histogram(isolationDistance,[2:2:100]),xlabel('Isolation distance'), ylabel('Count'), hold on, gridxy(25)
subplot(2,1,2)
histogram(lRatio,[0:0.2:5]),xlabel('L ratio'), ylabel('Count'), hold on, gridxy(0.5)

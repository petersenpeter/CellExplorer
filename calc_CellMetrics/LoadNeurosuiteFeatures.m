function [IsolationDistance,LRatio,ClusterID] = LoadNeurosuiteFeatures(clustering_path,basename,sr,TimeRestriction)
disp('Loading Neurosuite waveforms')
% clustering_path = 'Z:\Buzsakilabspace\PeterPetersen\IntanData\MS21\Peter_MS21_180718_103455_concat\Kilosort_2018-08-29_165108';
% basename = 'Peter_MS21_180718_103455_concat';
spike_cluster_index = double(readNPY(fullfile(clustering_path, 'spike_clusters.npy')));
spike_clusters = unique(spike_cluster_index);
if exist(fullfile(clustering_path, 'cluster_ids.npy'))
    cluster_ids = readNPY(fullfile(clustering_path, 'cluster_ids.npy'));
    unit_shanks = readNPY(fullfile(clustering_path, 'shanks.npy'));
end
kcoords2 = unique(unit_shanks);

fileID = fopen(fullfile(clustering_path, 'cluster_group.tsv'));
good_units = textscan(fileID,'%d %s','Delimiter','\t','HeaderLines',1);
fclose(fileID);
accepted_units = good_units{1}(find(strcmp({good_units{2}{:}},'good')));

SpikeFeatures = [];
IsolationDistance = [];
LRatio = [];
ClusterID = [];
for i = 1:length(kcoords2)
    kcoords3 = kcoords2(i);
    
    disp(['Loading spike group ' num2str(kcoords3)])
    cluster_index = load(fullfile(clustering_path, [basename '.clu.' num2str(kcoords3)]));
    cluster_index = cluster_index(2:end);

   % Load .fet file
    filename = fullfile(clustering_path,[basename '.fet.' num2str(kcoords3)]);
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

    if ~isempty(TimeRestriction)
        time_stamps = load(fullfile(clustering_path,[basename '.res.' num2str(kcoords3)]));
        indeces2keep = find(any(time_stamps./sr >= TimeRestriction(:,1)' & time_stamps./sr <= TimeRestriction(:,2)', 2));
%         time_stamps = time_stamps(indeces2keep);
        cluster_index = cluster_index(indeces2keep);
        fet = fet(indeces2keep,:);
    end
    
    clusters = unique(cluster_index);
    clusters = accepted_units(find(ismember(accepted_units,clusters)));
    indexes = find(ismember(cluster_index, clusters));
    SpikeFeatures = fet(indexes,1:end-1);
    cluster_index = cluster_index(indexes);
    
    [isolation_distance1,isolation_distance_accepted] = IsolationDistance_calc(SpikeFeatures,cluster_index,-1);
    [L_ratio1,L_ratio_accepted] = L_ratio_calc(SpikeFeatures,cluster_index,-1);
    
    IsolationDistance = [IsolationDistance;isolation_distance1];
    LRatio = [LRatio;L_ratio1];
    ClusterID = [ClusterID;clusters];
end

figure, subplot(2,1,1)
histogram(IsolationDistance,[2:2:100]),xlabel('Isolation distance'), ylabel('Count'), hold on, gridxy(25)
subplot(2,1,2)
histogram(LRatio,[0:0.2:5]),xlabel('L ratio'), ylabel('Count'), hold on, gridxy(0.5)

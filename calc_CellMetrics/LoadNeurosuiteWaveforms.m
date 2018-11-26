function [SpikeWaveforms,SpikeWaveforms_std,PeakVoltage,ClusterID] = LoadNeurosuiteWaveforms(clustering_path,basename,sr,TimeRestriction)
disp('   Loading Neurosuite waveforms')
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

SpikeWaveforms = [];
SpikeWaveforms_std = [];
PeakVoltage = [];
ClusterID = [];
k = 1;

for i = 1:length(kcoords2)
    kcoords3 = kcoords2(i);
    disp(['   Loading spike group ' num2str(kcoords3)])
    cluster_index = load(fullfile(clustering_path, [basename '.clu.' num2str(kcoords3)]));
    cluster_index = cluster_index(2:end);
    time_stamps = load(fullfile(clustering_path,[basename '.res.' num2str(kcoords3)]));
    fname = fullfile(clustering_path,[basename '.spk.' num2str(kcoords3)]);
    f = fopen(fname,'r');
    waveforms =  0.195 * double(fread(f,'int16'));
    xml = LoadXml(fullfile(clustering_path,[basename, '.xml']));
    samples = size(waveforms,1)/size(time_stamps,1);
    electrodes = size(xml.ElecGp{kcoords3},2);
    waveforms = reshape(waveforms, [electrodes,samples/electrodes,length(waveforms)/samples]);
    
    if ~isempty(TimeRestriction)  && ~isempty(cluster_index)
        indeces2keep = find(any(time_stamps./sr >= TimeRestriction(:,1)' & time_stamps./sr <= TimeRestriction(:,2)', 2));
        time_stamps = time_stamps(indeces2keep);
        cluster_index = cluster_index(indeces2keep);
        waveforms = waveforms(:,:,indeces2keep);
    end

    clusters = unique(cluster_index);
    clusters = accepted_units(find(ismember(accepted_units,clusters)));
    for ii = 1:length(clusters)
        indexes = find(cluster_index == clusters(ii));
        temp_waveforms = mean(waveforms(:,:,indexes),3);
        [PeakVoltage(k),max_channel] = max(max(temp_waveforms') - min(temp_waveforms'));
        SpikeWaveforms(k,:) = temp_waveforms(max_channel,:);
        SpikeWaveforms_std(k,:) = std(permute(waveforms(max_channel,:,indexes),[3,2,1]));
        ClusterID(k) = clusters(ii);
        k = k + 1;
    end
end
disp('   Waveforms completely loaded')
figure, plot(SpikeWaveforms'), title('Waveforms')

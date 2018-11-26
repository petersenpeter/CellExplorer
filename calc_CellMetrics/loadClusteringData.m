function spikes = loadClusteringData(recording,clustering_method,clustering_path,shanks,raw_clusters)
% load clustered data from multiple pipelines [Phy, KlustaViewa, Klustakwik/Neurosuite]
% Buzcode compatible output

% by Peter Petersen
% petersen.peter@gmail.com

switch nargin
    case 3
        shanks = 1;
    case 2
        shanks = 1;
        clustering_path = pwd;
end
if ~exist('raw_clusters')
    raw_clusters = 0;
end

switch lower(clustering_method)
    case {'klustakwik', 'neurosuite'}
        disp('Loading Klustakwik clustered data')
        unit_nb = 0;
        spikes = [];
        for shank = shanks;
            if raw_clusters == 0
                cluster_index = load(fullfile(clustering_path, [recording '.clu.' num2str(shank)]));
                time_stamps = load(fullfile(clustering_path,[recording '.res.' num2str(shank)]));
                %             fname = fullfile(clustering_path,[recording '.spk.' num2str(shank)]);
                %             f = fopen(fname,'r');
                %             waveforms = 0.000050354 * double(fread(f,'int16'));
                %             xml = LoadXml(fullfile(clustering_path,[recording, '.xml']));
                %             samples = size(waveforms,1)/size(time_stamps,1);
                %             electrodes = size(xml.ElecGp{shank},2);
                %             waveforms = reshape(waveforms, [electrodes,samples/electrodes,length(waveforms)/samples]);
            else
                cluster_index = load(fullfile(clustering_path, 'OriginalClus', [recording '.clu.' num2str(shank)]));
                time_stamps = load(fullfile(clustering_path, 'OriginalClus', [recording '.res.' num2str(shank)]));
                %             fname = fullfile(clustering_path, 'OriginalClus', [recording '.spk.' num2str(shank)]);
                %             f = fopen(fname,'r');
                %             waveforms = reshape(waveforms, [size(xml.ElecGp{shank},2),samples,length(waveforms)/(samples*size(xml.ElecGp{shank},2))])';
            end
            cluster_index = cluster_index(2:end);
            nb_clusters = unique(cluster_index);
            nb_clusters2 = nb_clusters(nb_clusters > 1);
            for i = 1:length(nb_clusters2)
                unit_nb = unit_nb +1;
                for j=0:log10(unit_nb-1)
                    fprintf('\b'); % delete previous counter display
                end
                fprintf('%d', unit_nb);
                spikes.ts{unit_nb} = time_stamps(cluster_index == nb_clusters2(i))';
                spikes.times{unit_nb} = spikes.ts{unit_nb}/20000;
                spikes.shankID(unit_nb) = shank;
                spikes.UID(unit_nb) = nb_clusters2(i);
                spikes.cluID(unit_nb) = nb_clusters2(i);
                spikes.cluster_index(unit_nb) = nb_clusters2(i);
                spikes.total(unit_nb) = length(spikes.ts{unit_nb});
                
                %             % Average waveform and std
                %             units(unit_nb).waveforms = mean(waveforms(:,:,cluster_index == nb_clusters2(i)),3);
                %             units(unit_nb).waveforms_std = permute(std(permute(waveforms(:,:,cluster_index == nb_clusters2(i)),[3,1,2])),[2,3,1]);
                %
                %             % Amplitudes
                %             [~,index1] = max(max(units(unit_nb).waveforms') - min(units(unit_nb).waveforms'));
                %             units(unit_nb).amplitudes = permute((max(waveforms(index1,:,cluster_index == nb_clusters2(i)),[],2)-min(waveforms(index1,:,cluster_index == nb_clusters2(i)),[],2)),[1,3,2]);
                %             units(unit_nb).peak_channel = index1;
                
            end
            
        end
        clear cluster_index time_stamps
        
    case 'phy'
        disp('Loading Phy clustered data')
        spike_cluster_index = readNPY(fullfile(clustering_path, 'spike_clusters.npy'));
        spike_times = readNPY(fullfile(clustering_path, 'spike_times.npy'));
        spike_amplitudes = readNPY(fullfile(clustering_path, 'amplitudes.npy'));
        spike_clusters = unique(spike_cluster_index);
        filename1 = fullfile(clustering_path,'cluster_group.tsv');
        filename2 = fullfile(clustering_path,'cluster_groups.csv');
        if exist(fullfile(clustering_path, 'cluster_ids.npy'))
            cluster_ids = readNPY(fullfile(clustering_path, 'cluster_ids.npy'));
            unit_shanks = readNPY(fullfile(clustering_path, 'shanks.npy'));
            peak_channel = readNPY(fullfile(clustering_path, 'peak_channel.npy'))+1;
        end

        if exist(filename1) == 2
            filename = filename1;
        elseif exist(filename2) == 2
            filename = filename2;
        else
            disp('Phy: No cluster group file found')
        end
        delimiter = '\t';
        startRow = 2;
        formatSpec = '%f%s%[^\n\r]';
        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
        fclose(fileID);
        spikes = [];
        j = 1;
        for i = 1:length(dataArray{1})
            if raw_clusters == 0
                if strcmp(dataArray{2}{i},'good')
                    if sum(spike_cluster_index == dataArray{1}(i))>0
                        spikes.ids{j} = find(spike_cluster_index == dataArray{1}(i));
                        spikes.ts{j} = double(spike_times(spikes.ids{j}));
                        spikes.times{j} = spikes.ts{j}/20000;
                        spikes.cluID(j) = dataArray{1}(i);
                        spikes.UID(j) = j;
                        if exist('cluster_ids')
                            cluster_id = find(cluster_ids == spikes.cluID(j));
                            spikes.shankID(j) = double(unit_shanks(cluster_id));
                            spikes.maxWaveformCh(j) = double(peak_channel(cluster_id));
                        end
                        spikes.total(j) = length(spikes.ts{j});
                        spikes.amplitudes{j} = double(spike_amplitudes(spikes.ids{j}));
                        j = j+1;
                    end
                end
            else
                spikes.ids{j} = find(spike_cluster_index == dataArray{1}(i));
                spikes.ts{j} = double(spike_times(spikes.ids{j}));
                spikes.cluID(j) = dataArray{1}(i);
                spikes.UID(j) = j;
                spikes.amplitudes{j} = double(spike_amplitudes(spikes.ids{j}))';
                j = j+1;
            end
        end
    case 'klustaViewa'
        disp('Loading KlustaViewa clustered data')
        units_to_exclude = [];
        [spikes,~] = ImportKwikFile(recording,clustering_path,shanks,0,units_to_exclude);
    case 'klustaViewa2'
        disp('Loading KlustaViewa2 clustered data')
        units_to_exclude = [];
        [spikes,~] = ImportKwikFile(recording,clustering_path,shanks,0,units_to_exclude);
end

spikes.sessionName = recording;

% Generate spindices matrics
spikes.numcells = length(spikes.UID);
for cc = 1:spikes.numcells
    groups{cc}=spikes.UID(cc).*ones(size(spikes.times{cc}));
end
if spikes.numcells>0
    alltimes = cat(1,spikes.times{:}); groups = cat(1,groups{:}); %from cell to array
    [alltimes,sortidx] = sort(alltimes); groups = groups(sortidx); %sort both
    spikes.spindices = [alltimes groups];
end
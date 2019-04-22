function spikes = loadClusteringData(baseName,clusteringMethod,clusteringPath,varargin)
% load clustered data from multiple pipelines [Phy, Klustakwik/Neurosuite]
% Buzcode compatible output. Saves output to a basename.spikes.cellinfo.mat file
% baseName: basename of the recording
% clusteringMethod: clustering method to handle different pipelines: ['phy','klustakwik'/'neurosuite']
% clusteringPath: path to the clustered data
% See description of varargin below

% by Peter Petersen
% petersen.peter@gmail.com
%
% Version history
% 3.2 waveforms for phy data extracted from the raw dat

p = inputParser;
addParameter(p,'shanks',nan,@isnumeric); % shanks: Loading only a subset of shanks (only applicable to Klustakwik)
addParameter(p,'raw_clusters',false,@islogical); % raw_clusters: Load only a subset of clusters (might not work anymore as it has not been tested for a long time)
addParameter(p,'forceReload',false,@islogical); % Reload spikes from original format and resave the .spikes.mat file?
addParameter(p,'saveMat',true,@islogical); % Save spikes to mat file?
addParameter(p,'getWaveforms',true,@islogical); % Get average waveforms? Only in effect for neurosuite/klustakwik format
parse(p,varargin{:})

shanks = p.Results.shanks;
raw_clusters = p.Results.raw_clusters;
forceReload = p.Results.forceReload;
saveMat = p.Results.saveMat;
getWaveforms = p.Results.getWaveforms;

if exist(fullfile(clusteringPath,[baseName,'.spikes.cellinfo.mat'])) & ~forceReload
    load(fullfile(clusteringPath,[baseName,'.spikes.cellinfo.mat']))
    if isfield(spikes,'ts') && (~isfield(spikes,'processinginfo') || (isfield(spikes,'processinginfo') && spikes.processinginfo.version < 3 && strcmp(spikes.processinginfo.function,'loadClusteringData') ))
        forceReload = true;
        disp('spikes.mat structure not up to date. Reloading spikes.')
    else
        disp('Loading existing spikes file')
    end
else
    forceReload = true;
end

if forceReload
    switch lower(clusteringMethod)
        case {'klustakwik', 'neurosuite'}
            disp('Loading Klustakwik clustered data')
            unit_nb = 0;
            spikes = [];
            shanks_new = [];
            if isnan(shanks)
                fileList = dir(fullfile(clusteringPath,[baseName,'.res.*']));
                fileList = {fileList.name};
                for i = 1:length(fileList)
                    temp = strsplit(fileList{i},'.res.');
                    shanks_new = [shanks_new,str2num(temp{2})];
                end
                shanks = sort(shanks_new);
            end
            for shank = shanks
                disp(['Loading shank #' num2str(shank) '/' num2str(length(shanks)) ])
                if ~raw_clusters
                    xml = LoadXml(fullfile(clusteringPath,[baseName, '.xml']));
                    cluster_index = load(fullfile(clusteringPath, [baseName '.clu.' num2str(shank)]));
                    time_stamps = load(fullfile(clusteringPath,[baseName '.res.' num2str(shank)]));
                    if getWaveforms
                        fname = fullfile(clusteringPath,[baseName '.spk.' num2str(shank)]);
                        f = fopen(fname,'r');
                        waveforms = 0.000195 * double(fread(f,'int16'));
                        samples = size(waveforms,1)/size(time_stamps,1);
                        electrodes = size(xml.ElecGp{shank},2);
                        waveforms = reshape(waveforms, [electrodes,samples/electrodes,length(waveforms)/samples]);
                    end
                else
                    cluster_index = load(fullfile(clusteringPath, 'OriginalClus', [baseName '.clu.' num2str(shank)]));
                    time_stamps = load(fullfile(clusteringPath, 'OriginalClus', [baseName '.res.' num2str(shank)]));
                end
                cluster_index = cluster_index(2:end);
                nb_clusters = unique(cluster_index);
                nb_clusters2 = nb_clusters(nb_clusters > 1);
                for i = 1:length(nb_clusters2)
                    unit_nb = unit_nb +1;
                    spikes.ts{unit_nb} = time_stamps(cluster_index == nb_clusters2(i));
                    spikes.times{unit_nb} = spikes.ts{unit_nb}/xml.SampleRate;
                    spikes.shankID(unit_nb) = shank;
                    spikes.UID(unit_nb) = unit_nb;
                    spikes.cluID(unit_nb) = nb_clusters2(i);
                    spikes.cluster_index(unit_nb) = nb_clusters2(i);
                    spikes.total(unit_nb) = length(spikes.ts{unit_nb});
                    if getWaveforms
                        spikes.filtWaveform_all{unit_nb} = mean(waveforms(:,:,cluster_index == nb_clusters2(i)),3);
                        spikes.filtWaveform_all_std{unit_nb} = permute(std(permute(waveforms(:,:,cluster_index == nb_clusters2(i)),[3,1,2])),[2,3,1]);
                        [~,index1] = max(max(spikes.filtWaveform_all{unit_nb}') - min(spikes.filtWaveform_all{unit_nb}'));
                        spikes.maxWaveformCh(unit_nb) = xml.ElecGp{shank}(index1); % index 0;
                        spikes.maxWaveformCh1(unit_nb) = xml.ElecGp{shank}(index1)+1; % index 1;
                        spikes.filtWaveform{unit_nb} = spikes.filtWaveform_all{unit_nb}(index1,:);
                        spikes.filtWaveform_std{unit_nb} = spikes.filtWaveform_all_std{unit_nb}(index1,:);
                        spikes.peakVoltage(unit_nb) = max(spikes.filtWaveform{unit_nb}) - min(spikes.filtWaveform{unit_nb});
                    end
                end
            end
            
            clear cluster_index time_stamps
            
        case 'phy'
            disp('Loading Phy clustered data')
            xml = LoadXml(fullfile(clusteringPath,[baseName, '.xml']));
            spike_cluster_index = readNPY(fullfile(clusteringPath, 'spike_clusters.npy'));
            spike_times = readNPY(fullfile(clusteringPath, 'spike_times.npy'));
            spike_amplitudes = readNPY(fullfile(clusteringPath, 'amplitudes.npy'));
            spike_clusters = unique(spike_cluster_index);
            filename1 = fullfile(clusteringPath,'cluster_group.tsv');
            filename2 = fullfile(clusteringPath,'cluster_groups.csv');
            if exist(fullfile(clusteringPath, 'cluster_ids.npy'))
                cluster_ids = readNPY(fullfile(clusteringPath, 'cluster_ids.npy'));
                unit_shanks = readNPY(fullfile(clusteringPath, 'shanks.npy'));
                peak_channel = readNPY(fullfile(clusteringPath, 'peak_channel.npy'))+1;
                if exist(fullfile(clusteringPath, 'rez.mat'))
                    load(fullfile(clusteringPath, 'rez.mat'))
                    temp = find(rez.connected);
                    peak_channel = temp(peak_channel);
                    clear rez temp
                end
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
                            spikes.times{j} = spikes.ts{j}/xml.SampleRate;
                            spikes.cluID(j) = dataArray{1}(i);
                            spikes.UID(j) = j;
                            if exist('cluster_ids')
                                cluster_id = find(cluster_ids == spikes.cluID(j));
                                spikes.shankID(j) = double(unit_shanks(cluster_id));
                                spikes.maxWaveformCh1(j) = double(peak_channel(cluster_id)); % index 1;
                                spikes.maxWaveformCh(j) = double(peak_channel(cluster_id))-1; % index 0;
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
            
            if getWaveforms % get waveforms
                timerVal = tic;
                nPull = 1000; % number of spikes to pull out
                wfWin = 0.006; % Larger size of waveform windows for filterning
                wfWinKeep = 0.001;
                filtFreq = 500;
                hpFilt = designfilt('highpassiir','FilterOrder',3, 'PassbandFrequency',filtFreq,'PassbandRipple',0.1, 'SampleRate',xml.SampleRate);
                [b1, a1] = butter(3, filtFreq/xml.SampleRate*2, 'high');
                
                f = waitbar(0,'Getting waveforms...');
                wfWin = round((wfWin * xml.SampleRate)/2);
                
                for ii = 1 : size(spikes.times,2)
                    waitbar(ii/size(spikes.times,2),f,['Pulling out waveforms (',num2str(ii),'/',num2str(size(spikes.times,2)),')']);
                    spkTmp = spikes.ts{ii};
                    if length(spkTmp) > nPull
                        spkTmp = spkTmp(randperm(length(spkTmp)));
                        spkTmp = sort(spkTmp(1:nPull));
                    end
                    
                    
                    % Determines the maximum waveform channel
                    wf = zeros((wfWin * 2)+1,xml.nChannels,100);
                    wfF = zeros((wfWin * 2)+1,xml.nChannels);
                    for jj = 1 : 100
                        wf(:,:,jj) = double(LoadBinary([baseName '.dat'],'offset',spkTmp(jj) - wfWin,'nChannels',xml.nChannels,'precision','int16','frequency',xml.SampleRate,'samples',(wfWin * 2)+1));
                        %                             wf(:,:,jj) = double(bz_LoadBinary([baseName '.dat'],'offset',spkTmp(jj) - (wfWin), 'samples',(wfWin * 2)+1,'frequency',xml.SampleRate,'nChannels',xml.nChannels));
                    end
                    wf =  0.195 * mean(wf,3);
                    
                    for jj = 1 : size(wf,2)
                        wfF(:,jj) = filtfilt(b1, a1, wf(:,jj));
                    end
                    [~, spikes.maxWaveformCh1(ii)] = max(abs(wfF(wfWin,:)));
                    spikes.maxWaveformCh(ii) = spikes.maxWaveformCh1(ii)-1;
                    
                    % Assigning shankID to the unit
                    for jj = 1:size(xml.AnatGrps,2)
                        if xml.AnatGrps(jj).Channels == spikes.maxWaveformCh(ii)
                            spikes.shankID(ii) = jj;
                        end
                    end
                    
                    % Pulls the waveforms from the dat
                    wf = zeros((wfWin * 2)+1,length(spkTmp));
                    wfF = zeros((wfWin * 2)+1,length(spkTmp));
                    for jj = 1 : length(spkTmp)
                        wf(:,jj) = double(LoadBinary([baseName '.dat'],'offset',spkTmp(jj) - wfWin,'nChannels',xml.nChannels,'channels',spikes.maxWaveformCh1(ii),'precision','int16','frequency',xml.SampleRate,'samples',(wfWin * 2)+1));
                        wfF(:,jj) = filtfilt(b1, a1, wf(:,jj));
                    end
                    wf2 = mean(0.195 * wf,2);
                    rawWaveform{ii} = detrend(wf2 - mean(wf2))';
                    rawWaveform_std{ii} = std(0.195 * (wf-mean(wf))');
                    filtWaveform{ii} = mean(0.195 * wfF,2)';
                    filtWaveform_std{ii} = std(0.195 * wfF');
                    
                    spikes.rawWaveform{ii} = rawWaveform{ii}(wfWin-(wfWinKeep*xml.SampleRate):wfWin+(wfWinKeep*xml.SampleRate)); % keep only +- 1ms of waveform
                    spikes.rawWaveform_std{ii} = rawWaveform_std{ii}(wfWin-(wfWinKeep*xml.SampleRate):wfWin+(wfWinKeep*xml.SampleRate));
                    spikes.filtWaveform{ii} = filtWaveform{ii}(wfWin-(wfWinKeep*xml.SampleRate):wfWin+(wfWinKeep*xml.SampleRate));
                    spikes.filtWaveform_std{ii} = filtWaveform_std{ii}(wfWin-(wfWinKeep*xml.SampleRate):wfWin+(wfWinKeep*xml.SampleRate));
                    spikes.timeWaveform{ii} = (-wfWinKeep:1/xml.SampleRate:wfWinKeep)*1000;
                    spikes.peakVoltage(ii) = max(spikes.filtWaveform{ii})-min(spikes.filtWaveform{ii});
                end
                close(f)
                toc(timerVal)
            end
            
        case 'klustaViewa'
            disp('Loading KlustaViewa clustered data')
            units_to_exclude = [];
            [spikes,~] = ImportKwikFile(baseName,clusteringPath,shanks,0,units_to_exclude);
    end
    
    spikes.sessionName = baseName;
    
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
    
    % Attaching info about how the spikes structure was generated
    spikes.processinginfo.function = 'loadClusteringData';
    spikes.processinginfo.version = 3.2;
    spikes.processinginfo.date = now;
    spikes.processinginfo.params.forceReload = forceReload;
    spikes.processinginfo.params.shanks = shanks;
    spikes.processinginfo.params.raw_clusters = raw_clusters;
    spikes.processinginfo.params.getWaveforms = getWaveforms;
    
    % Saving output to a buzcode compatible spikes file.
    if saveMat
        save(fullfile(clusteringPath,[baseName,'.spikes.cellinfo.mat']),'spikes')
    end
end

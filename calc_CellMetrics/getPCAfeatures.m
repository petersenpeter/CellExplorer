function PCA_features = getPCAfeatures(session)
% The script has a high memory usage as all waveforms are loaded into memory at the same time. 
% If you experience a memory error, increase your swap/cashe file, and increase the amount of 
% memory MATLAB can use.
%
% 1) Waveforms are extracted from the dat file via GPU enabled filters.
% 2) Features are calculated in parfor loops.
%
% Inputs
% basepath -  location of your data / dat file. rez structure from Kilosort
% clustering_path - location of your kilosort output. 
%
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 02-12-2019

t1 = tic;

% Parameters (cleaned)
switch lower(session.spikeSorting{1}.format)
    case 'phy'
        fprintf(['Getting PCA features from phy clustered data...\n'])
        clusteringpath_full = fullfile(session.general.basePath,session.general.clusteringPath);
        ops.spikeClusterIDs = double(readNPY(fullfile(clusteringpath_full, 'spike_clusters.npy'))); % spike cluIDs
        cluster_ids = unique(ops.spikeClusterIDs); % List of cluster ids
        ops.spikeTimes = readNPY(fullfile(clusteringpath_full, 'spike_times.npy')); % Timestamps
        ops.templates = permute(readNPY(fullfile(clusteringpath_full, 'templates.npy')),[3,2,1]); % templates
        ops.spike_templates = 1+readNPY(fullfile(clusteringpath_full, 'spike_templates.npy')); % templates
        for i = 1:size(ops.templates,3)
            [~,ops.templatePeakChannel(i)] = max(range(ops.templates(:,:,i),2));
        end
        
        % Pulling info from chanMap.mat
        temp1 = load(fullfile(session.general.basePath,'chanMap.mat'));
        ops.chanMap = temp1.chanMap;
        ops.connected = temp1.connected';
        chanMapConn = ops.chanMap(ops.connected);
        ops.Nchan = sum(ops.connected>1e-6);
        ops.kcoords = temp1.kcoords;
        
        ops.template_kcoords = ops.kcoords(ops.templatePeakChannel); % Shank id for each template
        % Shank id for each cluster
        for i = 1:length(cluster_ids)
            ter = mode(ops.spike_templates(find(ops.spikeClusterIDs==cluster_ids(i))));
            cluster_kcoords(i) = ops.template_kcoords(ter);
        end
        ops.kcoords2 = unique(cluster_kcoords);
        
    otherwise
%         % Parameters (Needs cleaning)
%         ops.connected = true(ops.NchanTOT, 1);
%         ops.Nchan = sum(ops.connected>1e-6); % number of active channels
%         ops.chanMap = 1:ops.NchanTOT; % readNPY(fullfile('channel_map.npy'))+1;
%         chanMapConn = ops.chanMap(ops.connected);
%         ops.kcoords = zeros(1,Nchannels);
%         for a = 1:session.extracellular.nElectrodeGroups
%             ops.kcoords(ops.electrodeGroups{a}+1) = a;
%         end
%         ops.kcoords2 = unique(cluster_kcoords); % ops.kcoords
end
ops.electrodeGroups = session.extracellular.electrodeGroups.channels; % Electrode groups
ops.binaryFile = fullfile(session.general.basePath,[session.general.name,'.dat']); % Path to binary dat file
ops.NchanTOT = session.extracellular.nChannels;
ops.GPU = 1; % whether to run this code on an Nvidia GPU (much faster, mexGPUall first)
ops.ntbuff = 64; % samples of symmetrical buffer for whitening and spike detection
ops.NT = 32*1028+ ops.ntbuff; % ops.NT;
ops.fs = session.extracellular.sr;
ops.nt0 = round(1.6*ops.fs/1000); % window width in samples. 1.6ms at 20kH corresponds to 32 samples
ops.ForceMaxRAMforDat = 15000000000; % maximum RAM the algorithm will try to use; on Windows it will autodetect.
ops.fslow = 8000;
ops.fshigh = 500;

ia = [];
for i = 1:length(ops.kcoords2)
    kcoords3 = ops.kcoords2(i);
    if mod(i,4)==1; fprintf('\n'); end
    fprintf(['Loading data for spike group ', num2str(kcoords3),'. '])
    template_index = cluster_ids(find(ops.kcoords == kcoords3));
    ia{i} = find(ismember(cluster_kcoords,template_index));
end
ops.ia = ia;

% Declaring variables
isolationDistance = [];
lRatio = [];

% Running pipeline
fprintf('\nExtracting waveforms\n')
waveforms_all = Kilosort_ExtractWaveforms;

fprintf('\n'); toc(t1)
fprintf('\nComputing PCAs')

% Starting parpool if stated in the Kilosort settings
if (rez.ops.parfor & isempty(gcp('nocreate'))); parpool; end
for i = 1:length(ops.kcoords2)
    kcoords3 = ops.kcoords2(i);
    if mod(i,2)==1; fprintf('\n'); end
    fprintf(['Computing PCAs for group ', num2str(kcoords3),'. '])
    PCAs_global = zeros(3,sum(ops.kcoords==kcoords3),length(ops.ia{i}));
    waveforms = waveforms_all{i};
    
    waveforms2 = reshape(waveforms,[size(waveforms,1)*size(waveforms,2),size(waveforms,3)]);
    wranges = int64(range(waveforms2,1));
    wpowers = int64(sum(waveforms2.^2,1)/size(waveforms2,1)/100);
    
    % Calculating PCAs in parallel if stated in ops.parfor
    if ops.GPU % isempty(gcp('nocreate'))
        for k = 1:size(waveforms,1)
            PCAs_global(:,k,:) = pca(zscore(permute(waveforms(k,:,:),[2,3,1]),[],2),'NumComponents',3)';
        end
    else
        parfor k = 1:size(waveforms,1)
            PCAs_global(:,k,:) = pca(zscore(permute(waveforms(k,:,:),[2,3,1]),[],2),'NumComponents',3)';
        end
    end
    
    % Calculate L-ratio and Isolation distance from global space
    [isolation_distance1,isolation_distance_accepted] = calc_IsolationDistance(SpikeFeatures,cluster_index,-1);
    [L_ratio1,L_ratio_accepted] = L_ratio_calc(SpikeFeatures,cluster_index,-1);
    
    isolationDistance = [isolationDistance;isolation_distance1];
    lRatio = [lRatio;L_ratio1];
    
    % Calculating metrics from 4,8 and 16 channel subsets
    % isolationDistance_4
    % lRatio_4
    
    % isolationDistance_8
    % lRatio_8
    
    % isolationDistance_16
    % lRatio_16
    
end

PCA_features.isolationDistance = isolationDistance;
PCA_features.lRatio = lRatio;

fprintf('\n'); toc(t1)
fprintf('\nComplete!')

	function waveforms_all = Kilosort_ExtractWaveforms()
        % Extracts waveforms from a dat file using GPU enable filters.
        % Based on the GPU enable filter from Kilosort.
        % All settings and content are extracted from the rez input structure
        %
        % Outputs:
        %   waveforms_all - structure with extracted waveforms
        
        if exist(ops.binaryFile) == 0
            warning(['Binary file does not exist: ', ops.binaryFile])
        end
        d = dir(ops.binaryFile);
        
        if ispc
            dmem         = memory;
            memfree      = dmem.MemAvailableAllArrays/8;
            memallocated = min(ops.ForceMaxRAMforDat, dmem.MemAvailableAllArrays) - memfree;
            memallocated = max(0, memallocated);
        else
            memallocated = ops.ForceMaxRAMforDat;
        end

        nint16s      = memallocated/2;
        
        ops.NTbuff  = ops.NT + 4*ops.ntbuff;
        Nbatch      = ceil(d.bytes/2/ops.NchanTOT /(ops.NT-ops.ntbuff));
        Nbatch_buff = floor(4/5 * nint16s/ops.Nchan /(ops.NT-ops.ntbuff)); % factor of 4/5 for storing PCs of spikes
        Nbatch_buff = min(Nbatch_buff, Nbatch);
        
        DATA =zeros(ops.NT, ops.NchanTOT,Nbatch_buff,'int16');
        
        if isfield(ops,'fslow') && ops.fslow < ops.fs/2
            [b1, a1] = butter(3, [ops.fshigh/ops.fs,ops.fslow/ops.fs]*2, 'bandpass');
        else
            [b1, a1] = butter(3, ops.fshigh/ops.fs*2, 'high');
        end
        fid = fopen(ops.binaryFile, 'r');
        
        waveforms_all = [];
        channel_order = {};
        indicesTokeep = {};
        
        for i = 1:length(ops.kcoords2)
            kcoords3 = ops.kcoords2(i);
            if i<=length(ops.ia) % case where no clus in last group... like if last group was non-ephys
                waveforms_all{i} = zeros(sum(ops.kcoords==kcoords3),ops.nt0,size(ops.ia{i},1));
                [channel_order,channel_index] = sort(ops.electrodeGroups{ops.kcoords2(i)});
                [~,indicesTokeep{i},~] = intersect(chanMapConn,channel_order);
            else
                ops.kcoords2(i) = [];
            end
        end
        
        fprintf('Extraction of waveforms begun \n')
        for ibatch = 1:Nbatch
            if mod(ibatch,10)==0
                if ibatch~=10
                    fprintf(repmat('\b',[1 length([num2str(round(100*(ibatch-10)/Nbatch)), ' percent complete'])]))
                end
                fprintf('%d percent complete', round(100*ibatch/Nbatch));
            end
            
            offset = max(0, 2*ops.NchanTOT*((ops.NT - ops.ntbuff) * (ibatch-1) - 2*ops.ntbuff));
            if ibatch==1
                ioffset = 0;
            else
                ioffset = ops.ntbuff;
            end
            fseek(fid, offset, 'bof');
            buff = fread(fid, [ops.NchanTOT ops.NTbuff], '*int16');
            
            if isempty(buff)
                break;
            end
            nsampcurr = size(buff,2);
            if nsampcurr<ops.NTbuff
                buff(:, nsampcurr+1:ops.NTbuff) = repmat(buff(:,nsampcurr), 1, ops.NTbuff-nsampcurr);
            end
            if ops.GPU
                try % control for if gpu is busy
                    dataRAW = gpuArray(buff);
                catch
                    dataRAW = buff;
                end
            else
                dataRAW = buff;
            end
            
            dataRAW = dataRAW';
            dataRAW = single(dataRAW);
            dataRAW = dataRAW(:, chanMapConn);
            dataRAW = dataRAW-median(dataRAW,2);
            datr = filter(b1, a1, dataRAW);
            datr = flipud(datr);
            datr = filter(b1, a1, datr);
            datr = flipud(datr);
            DATA = gather_try(int16( datr(ioffset + (1:ops.NT),:)));
            dat_offset = offset/ops.NchanTOT/2+ioffset;
            
            % Saves the waveforms occuring within each batch
            for i = 1:length(ops.kcoords2)
                kcoords3 = ops.kcoords2(i);
                temp = find(ismember(ops.spikeTimes(ops.ia{i}), [ops.nt0/2+1:size(DATA,1)-ops.nt0/2] + dat_offset));
                temp2 = ops.spikeTimes(ops.ia{i}(temp))-dat_offset;
                
                startIndicies = temp2-ops.nt0/2+1;
                stopIndicies = temp2+ops.nt0/2;
                X = cumsum(accumarray(cumsum([1;stopIndicies(:)-startIndicies(:)+1]),[startIndicies(:);0]-[0;stopIndicies(:)]-1)+1);
                X = X(1:end-1);
                waveforms_all{i}(:,:,temp) = reshape(DATA(X,indicesTokeep{i})',size(indicesTokeep{i},1),ops.nt0,[]);
            end
        end
    end
end

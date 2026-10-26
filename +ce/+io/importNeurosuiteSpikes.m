function [spikes, electrodeGroups] = importNeurosuiteSpikes(session, varargin)
%IMPORTNEUROSUITESPIKES Read .clu/.res and optional .spk without UI or writes.
% Session supplies general.basePath/name and extracellular.sr. Source waveform
% import also needs nChannels and electrodeGroups.channels (one-based channels).
% clusteringpath is relative to basePath; its default is spikeSorting{1}.relativePath.
% The output keeps legacy group/cluster ordering, sequential UIDs, sample-to-second
% conversion and 0.5 ms uniquetol. Waveform averages use all assigned source spikes,
% including spikes whose timestamps are collapsed, as in the original importer.
plan = ce.io.neurosuiteImportPlan(session,varargin{:});
folder=plan.folder; basename=plan.basename; electrodeGroups=plan.electrodeGroups;
scale=plan.scale; options=plan.options;

spikes = struct(); UID = 0;
for group = electrodeGroups
    clusterFile = fullfile(folder,sprintf('%s.clu.%d',basename,group));
    timeFile = fullfile(folder,sprintf('%s.res.%d',basename,group));
    clusters = readIntegerColumn(clusterFile);
    time_stamps = readIntegerColumn(timeFile);
    if isempty(clusters) || clusters(1)<1
        error('ce:io:InvalidSortingData','%s needs a positive cluster-count header.',clusterFile);
    end
    cluster_index = clusters(2:end);
    if numel(cluster_index)~=numel(time_stamps)
        error('ce:io:SortingLengthMismatch','Cluster assignments and sample timestamps differ in length for electrode group %d.',group);
    end
    if options.getWaveformsFromSource
        channels = session.extracellular.electrodeGroups.channels{group};
        file = fullfile(folder,sprintf('%s.spk.%d',basename,group));
        waveforms = readWaveforms(file,numel(channels),numel(time_stamps),scale);
    end
    nb_clusters = unique(cluster_index);
    nb_clusters2 = nb_clusters(nb_clusters > 1);
    tol_samples = session.extracellular.sr*5e-4;
    for index = 1:length(nb_clusters2)
        UID = UID+1;
        selected = cluster_index == nb_clusters2(index);
        spikes.ts{UID} = time_stamps(selected);
        [spikes.ts{UID},~] = uniquetol(spikes.ts{UID},tol_samples,'DataScale',1);
        spikes.times{UID} = spikes.ts{UID}/session.extracellular.sr;
        spikes.shankID(UID) = group;
        spikes.cluID(UID) = nb_clusters2(index);
        spikes.cluster_index(UID) = nb_clusters2(index);
        spikes.total(UID) = length(spikes.ts{UID});
        if options.getWaveformsFromSource
            spikes.filtWaveform_all{UID} = mean(waveforms(:,:,selected),3);
            spikes.filtWaveform_all_std{UID} = permute(std(permute(waveforms(:,:,selected),[3,1,2])),[2,3,1]);
            [~,index1] = max(max(spikes.filtWaveform_all{UID}') - min(spikes.filtWaveform_all{UID}'));
            spikes.maxWaveformCh(UID) = channels(index1)-1;
            spikes.maxWaveformCh1(UID) = channels(index1);
            spikes.filtWaveform{UID} = spikes.filtWaveform_all{UID}(index1,:);
            spikes.peakVoltage(UID) = max(spikes.filtWaveform{UID}) - min(spikes.filtWaveform{UID});
        end
    end
end
if UID==0, error('ce:io:NoSortedUnits','No clusters above the legacy noise IDs 0 and 1 were found.'); end
spikes.basename = basename;
spikes.numcells = numel(spikes.times);
spikes.UID = 1:spikes.numcells;
spikes.sr = session.extracellular.sr;
end

function data = readIntegerColumn(file)
try
    data = load(file,'-ascii');
catch exception
    error('ce:io:InvalidSortingData','Cannot read numeric sorting input %s: %s',file,exception.message);
end
if ~isempty(data) && (~iscolumn(data) || ~isreal(data) || any(~isfinite(data) | data<0 | data~=fix(data) | data>flintmax))
    error('ce:io:InvalidSortingData','%s must contain one nonnegative, exactly representable integer per line.',file);
end
data = data(:);
end

function waveforms = readWaveforms(file,channelCount,spikeCount,scale)
info = dir(file);
if spikeCount==0
    if info.bytes~=0, error('ce:io:InvalidWaveformFile','Nonempty waveform file for an empty spike group: %s.',file); end
    waveforms = zeros(channelCount,0,0); return
end
if info.bytes==0 || rem(info.bytes,2*channelCount*spikeCount)~=0
    error('ce:io:InvalidWaveformFile','%s must contain complete int16 channel/sample/spike frames.',file);
end
handle = fopen(file,'rb');
if handle<0, error('ce:io:UnreadableWaveformFile','Cannot open %s.',file); end
cleanup = onCleanup(@() fclose(handle));
waveforms = scale * double(fread(handle,'int16'));
if numel(waveforms)~=info.bytes/2
    error('ce:io:InvalidWaveformFile','Waveform file changed or could not be read completely: %s.',file);
end
samples = size(waveforms,1)/spikeCount;
waveforms = reshape(waveforms,[channelCount,samples/channelCount,length(waveforms)/samples]);
end

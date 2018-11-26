function [RippleModulationIndex,RipplePeakDelay,RippleCorrelogram] = calc_RippleModulationIndex(ripples,clustering_path,sr,TimeRestriction)
%% Ripple modulation index
% sr = 20000;
RippleModulationIndex = [];
RippleCorrelogram = [];

fileID = fopen(fullfile(clustering_path, 'cluster_group.tsv'));
good_units = textscan(fileID,'%d %s','Delimiter','\t','HeaderLines',1);
fclose(fileID);
accepted_units = good_units{1}(find(strcmp({good_units{2}{:}},'good')));

spike_times = double(readNPY(fullfile(clustering_path, 'spike_times.npy')));
spike_cluster_index = double(readNPY(fullfile(clustering_path, 'spike_clusters.npy')));

if ~isempty(TimeRestriction)
	indeces2keep = find(any(spike_times./sr >= TimeRestriction(:,1)' & spike_times./sr <= TimeRestriction(:,2)', 2));
	spike_times = spike_times(indeces2keep);
	spike_cluster_index = spike_cluster_index(indeces2keep);
end

ia = find(ismember(spike_cluster_index,accepted_units));
[spike_times,index] = sort([spike_times(ia)./sr;ripples.peaks]);
spike_cluster_index = spike_cluster_index(ia);
spike_cluster_index = [spike_cluster_index;zeros(size(ripples.peaks,1),1)];
spike_cluster_index = spike_cluster_index(index);

[~, ~, spike_cluster_index] = unique(spike_cluster_index);
conv_length1 = 5;
conv_length2 = 40;
[ccg,time] = CCG(spike_times,spike_cluster_index,'binSize',0.001,'duration',0.4,'norm','rate');
RippleCorrelogram = nanconv(ccg(:,2:end,1),ones(1,conv_length1)/conv_length1,'edge');
RippleCorrelogram2 = nanconv(ccg(:,2:end,1),ones(1,conv_length2)/conv_length2,'edge');


[~,RipplePeakDelay] = max(RippleCorrelogram2);
RipplePeakDelay = RipplePeakDelay-201;
RippleBaseline = 1:100;
RippleRipple = 161:241;
RipplePost = 161:241;
RipplePeak = 195:210;
RippleModulationIndex = mean(RippleCorrelogram(RipplePeak,:))./mean(RippleCorrelogram(RippleBaseline,:));
[~,index2] = sort(RippleModulationIndex,'descend');
[~,index3] = sort(RipplePeakDelay);

figure,
subplot(2,2,1), histogram(RippleModulationIndex,40), title('RippleModulationIndex'), xlabel('Ratio')
subplot(2,2,2), histogram(RipplePeakDelay,40), title('RipplePeakDelay'), xlabel('Time (ms)')
subplot(2,2,3), imagesc((RippleCorrelogram(100:300,index2))'), title('Ripple Correlograms'), ylabel('Sorted by RippleModulationIndex')
subplot(2,2,4), imagesc((RippleCorrelogram(100:300,index3))'), title('Ripple Correlograms'), ylabel('Sorted by RipplePeakDelay')


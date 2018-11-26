function [ACG,ACG2,ThetaModulationIndex,BurstIndex_Royer2012,BurstIndex_Doublets] = calc_ACG_metrics(clustering_path,sr,TimeRestriction)
% theta modulation index (TMI) % The TMI was computed as the difference 
% between the theta modulation trough (defined as mean of autocorrelogram 
% bins 50-70 ms) and the theta modulation peak (mean of autocorrelogram 
% bins 100-140ms) over their sum
%
% GPU accellerated code (10x faster)
%
% By Peter Petersen
% petersen.peter@gmail.com

% gpuDevice(1);
max_lags = 1;
bin_size = 0.001; % 1 ms
lags = [-max_lags:bin_size:max_lags];

ThetaModulationIndex = [];
BurstIndex_Royer2012 = [];
BurstIndex_Doublets = [];
tic
fileID = fopen(fullfile(clustering_path, 'cluster_group.tsv'));
good_units = textscan(fileID,'%d %s','Delimiter','\t','HeaderLines',1);
fclose(fileID);
accepted_units = good_units{1}(find(strcmp({good_units{2}{:}},'good')));

spike_times = double(readNPY(fullfile(clustering_path, 'spike_times.npy')));
spike_cluster_index = double(readNPY(fullfile(clustering_path, 'spike_clusters.npy')));
ia = find(ismember(spike_cluster_index,accepted_units));
spike_times = spike_times(ia);
spike_cluster_index = spike_cluster_index(ia);
[~, ~, spike_cluster_index] = unique(spike_cluster_index);

if ~isempty(TimeRestriction)
	indeces2keep = find(any(spike_times./sr >= TimeRestriction(:,1)' & spike_times./sr <= TimeRestriction(:,2)', 2));
	spike_times = spike_times(indeces2keep);
	spike_cluster_index = spike_cluster_index(indeces2keep);
end

[ccg,time] = CCG(spike_times./sr,spike_cluster_index,'binSize',0.001,'duration',1,'norm','rate');
[ccg2,time2] = CCG(spike_times./sr,spike_cluster_index,'binSize',0.0005,'duration',0.100,'norm','rate');
max_lags = (length(time)-1)/2;
max_lags2 = (length(time2)-1)/2;
for ii = 1:size(ccg,2)
    xc = ccg(:,ii,ii);
    xc2 = ccg2(:,ii,ii);
    ThetaModulationIndex(ii) = (mean(xc(max_lags+1+50:max_lags+1+70))-mean(xc(max_lags+1+100:max_lags+1+140)))/(mean(xc(max_lags+1+50:max_lags+1+70))+mean(xc(max_lags+1+100:max_lags+1+140)));
    BurstIndex_Royer2012(ii) = sum(xc(max_lags+1+3:max_lags+1+5))/mean(xc(max_lags+1+200:max_lags+1+300));
    BurstIndex_Doublets(ii) = max(xc2(max_lags2+1+5:max_lags2+1+16))/mean(xc2(max_lags2+1+16:max_lags2+1+23));
    ACG(:,ii) = xc;
    ACG2(:,ii) = ccg2(:,ii,ii);
end
toc

figure, subplot(3,1,1)
histogram(ThetaModulationIndex,40),xlabel('Theta modulation index'), ylabel('Count')
subplot(3,1,2)
histogram(BurstIndex_Royer2012,40),xlabel('BurstIndex Royer2012'), ylabel('Count')
subplot(3,1,3)
histogram(BurstIndex_Doublets,40),xlabel('BurstIndex Doublets'), ylabel('Count')
% for ii = 1:length(units)
%     x_spikes = round(units(ii).ts/sr/bin_size);
%     x = zeros(1,max([x_spikes]));
%     x(x_spikes) = 1;
%     X = gpuArray(x);
%     
%     [xc,~] = xcorr(X,max_lags,'coeff');
%     xc = gather(xc);
%     xc(max_lags+1) = 0;
% 
%     ThetaModulationIndex(ii) = (mean(xc(max_lags+1+50:max_lags+1+70))-mean(xc(max_lags+1+100:max_lags+1+140)))/(mean(xc(max_lags+1+50:max_lags+1+70))+mean(xc(max_lags+1+100:max_lags+1+140)));
%     Burstiness_Royer2012(ii) = sum(xc(max_lags+1+3:max_lags+1+10))/sum(xc(max_lags+1+200:max_lags+1+300));
% end
% toc

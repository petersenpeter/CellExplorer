function acg_metrics = calc_ACG_metrics(spikes)%(clustering_path,sr,TimeRestriction)
% theta modulation index (TMI) % The TMI was computed as the difference 
% between the theta modulation trough (defined as mean of autocorrelogram 
% bins 50-70 ms) and the theta modulation peak (mean of autocorrelogram 
% bins 100-140ms) over their sum

% By Peter Petersen
% petersen.peter@gmail.com

max_lags = 1;
bin_size = 0.001; % 1 ms
lags = [-max_lags:bin_size:max_lags];

ThetaModulationIndex = [];
BurstIndex_Royer2012 = [];
BurstIndex_Doublets = [];
tic
% fileID = fopen(fullfile(clustering_path, 'cluster_group.tsv'));
% good_units = textscan(fileID,'%d %s','Delimiter','\t','HeaderLines',1);
% fclose(fileID);
% accepted_units = good_units{1}(find(strcmp({good_units{2}{:}},'good')));
% 
% spike_times = double(readNPY(fullfile(clustering_path, 'spike_times.npy')));
% spike_cluster_index = double(readNPY(fullfile(clustering_path, 'spike_clusters.npy')));
% ia = find(ismember(spike_cluster_index,accepted_units));


spike_times = spikes.spindices(:,1);
spike_cluster_index = spikes.spindices(:,2);
[~, ~, spike_cluster_index] = unique(spike_cluster_index);

% if ~isempty(TimeRestriction)
% 	indeces2keep = find(any(spike_times./sr >= TimeRestriction(:,1)' & spike_times./sr <= TimeRestriction(:,2)', 2));
% 	spike_times = spike_times(indeces2keep);
% 	spike_cluster_index = spike_cluster_index(indeces2keep);
% end

[ccg,time] = CCG(spike_times,spike_cluster_index,'binSize',0.001,'duration',1,'norm','rate');
[ccg2,time2] = CCG(spike_times,spike_cluster_index,'binSize',0.0005,'duration',0.100,'norm','rate');
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

acg_metrics.acg = ACG;
acg_metrics.acg2 = ACG2;
acg_metrics.thetaModulationIndex = ThetaModulationIndex;
acg_metrics.burstIndex_Royer2012 = BurstIndex_Royer2012;
acg_metrics.burstIndex_Doublets = BurstIndex_Doublets;
acg_metrics.ccg = ccg2;
acg_metrics.ccg_time = time2;

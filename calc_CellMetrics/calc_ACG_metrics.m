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

ThetaModulationIndex = nan(1,spikes.numcells);
BurstIndex_Royer2012 = nan(1,spikes.numcells);
BurstIndex_Doublets = nan(1,spikes.numcells);


tic

spike_times = spikes.spindices(:,1);
spike_cluster_index = spikes.spindices(:,2);
[~, ~, spike_cluster_index] = unique(spike_cluster_index);

[ccg,time] = CCG(spike_times,spike_cluster_index,'binSize',0.001,'duration',1,'norm','rate');
[ccg2,time2] = CCG(spike_times,spike_cluster_index,'binSize',0.0005,'duration',0.100,'norm','rate');
max_lags = (length(time)-1)/2;
max_lags2 = (length(time2)-1)/2;

ACG = nan(length(time),spikes.numcells);
ACG2 = nan(length(time2),spikes.numcells);

if any(spikes.total==0)
    idx2 = find(spikes.total>0);
else
    idx2 = 1:spikes.numcells;
end

for ii = 1:size(ccg,2)
    xc = ccg(:,ii,ii);
    xc2 = ccg2(:,ii,ii);
    idx = idx2(ii);
    ThetaModulationIndex(idx) = (mean(xc(max_lags+1+50:max_lags+1+70))-mean(xc(max_lags+1+100:max_lags+1+140)))/(mean(xc(max_lags+1+50:max_lags+1+70))+mean(xc(max_lags+1+100:max_lags+1+140)));
    BurstIndex_Royer2012(idx) = sum(xc(max_lags+1+3:max_lags+1+5))/mean(xc(max_lags+1+200:max_lags+1+300));
    BurstIndex_Doublets(idx) = max(xc2(max_lags2+1+5:max_lags2+1+16))/mean(xc2(max_lags2+1+16:max_lags2+1+23));
    ACG(:,idx) = xc;
    ACG2(:,idx) = ccg2(:,ii,ii);
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

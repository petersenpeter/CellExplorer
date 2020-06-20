function acg_metrics = calc_ACG_metrics(spikes)%(clustering_path,sr,TimeRestriction)
% theta modulation index (TMI) % The TMI was computed as the difference 
% between the theta modulation trough (defined as mean of autocorrelogram 
% bins 50-70 ms) and the theta modulation peak (mean of autocorrelogram 
% bins 100-140ms) over their sum

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 16-06-2020

ThetaModulationIndex = nan(1,spikes.numcells);
BurstIndex_Royer2012 = nan(1,spikes.numcells);
BurstIndex_Doublets = nan(1,spikes.numcells);

if any(spikes.total==0)
    cell_indexes = find(spikes.total>0);
else
    cell_indexes = 1:spikes.numcells;
end

bins_wide = 500;
acg_wide = zeros(bins_wide*2+1,numel(spikes.times));
bins_narrow = 100;
acg_narrow = zeros(bins_narrow*2+1,numel(spikes.times));
disp('Calculating narrow CCGs (100ms, 0.5ms bins) and wide CCGs (1s, 1ms bins)')
tic
for i = cell_indexes
    acg_wide(:,i) = CCG(spikes.times{i},ones(size(spikes.times{i})),'binSize',0.001,'duration',1,'norm','rate');
    acg_narrow(:,i) = CCG(spikes.times{i},ones(size(spikes.times{i})),'binSize',0.0005,'duration',0.100,'norm','rate');
    % Metrics from narrow
    BurstIndex_Doublets(i) = max(acg_narrow(bins_narrow+1+5:bins_narrow+1+16,i))/mean(acg_narrow(bins_narrow+1+16:bins_narrow+1+23,i));
    % Metrics from wide
    ThetaModulationIndex(i) = (mean(acg_wide(bins_wide+1+50:bins_wide+1+70,i))-mean(acg_wide(bins_wide+1+100:bins_wide+1+140,i)))/(mean(acg_wide(bins_wide+1+50:bins_wide+1+70,i))+mean(acg_wide(bins_wide+1+100:bins_wide+1+140,i)));
    BurstIndex_Royer2012(i) = sum(acg_wide(bins_wide+1+3:bins_wide+1+5,i))/mean(acg_wide(bins_wide+1+200:bins_wide+1+300,i));
end
toc

figure, subplot(3,1,1)
histogram(ThetaModulationIndex,40),xlabel('Theta modulation index'), ylabel('Count')
subplot(3,1,2)
histogram(BurstIndex_Royer2012,40),xlabel('BurstIndex Royer2012'), ylabel('Count')
subplot(3,1,3)
histogram(BurstIndex_Doublets,40),xlabel('BurstIndex Doublets'), ylabel('Count')

acg_metrics.acg_wide = acg_wide;
acg_metrics.acg_narrow = acg_narrow;
acg_metrics.thetaModulationIndex = ThetaModulationIndex;
acg_metrics.burstIndex_Royer2012 = BurstIndex_Royer2012;
acg_metrics.burstIndex_Doublets = BurstIndex_Doublets;

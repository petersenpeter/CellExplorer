function acg_metrics = calc_ACG_metrics(spikes,sr,varargin)%(clustering_path,sr,TimeRestriction)
% Two autocorrelograms are calculated:  narrow (100ms, 0.5ms bins) and wide (1s, 1ms bins) using the CCG function (for speed)
%
% Further three metrics are derived from these:
%
% Theta modulation index:
%    Computed as the difference between the theta modulation trough (defined as mean of autocorrelogram bins 50-70 ms)
%    and the theta modulation peak (mean of autocorrelogram  bins 100-140ms) over their sum
%    Originally defined in Cacucci et al., JNeuro 2004
%
% BurstIndex_Doublets:
%    max bin count from 2.5-8ms normalized by the average number of spikes in the 8-11.5ms bins
%
% BurstIndex_Royer2012:
%    Burst index is determined by calculating the average number of spikes in the 3-5 ms bins of the spike
%    autocorrelogram divided by the average number of spikes in the 200-300 ms bins.
%    Metrics introduced in Royer et al. Nature Neuroscience 2012, and adjusted in Senzai & Buzsaki, Neuron 2017.

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 06-10-2020
p = inputParser;
addParameter(p,'showFigures',true,@islogical);
parse(p,varargin{:})

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
disp('Calculating narrow ACGs (100ms, 0.5ms bins) and wide ACGs (1s, 1ms bins)')
tic
for i = cell_indexes
    acg_wide(:,i) = CCG(spikes.times{i},ones(size(spikes.times{i})),'binSize',0.001,'duration',1,'norm','rate','Fs',1/sr);
    acg_narrow(:,i) = CCG(spikes.times{i},ones(size(spikes.times{i})),'binSize',0.0005,'duration',0.100,'norm','rate','Fs',1/sr);
    % Metrics from narrow
    BurstIndex_Doublets(i) = max(acg_narrow(bins_narrow+1+5:bins_narrow+1+16,i))/mean(acg_narrow(bins_narrow+1+16:bins_narrow+1+23,i));
    % Metrics from wide
    ThetaModulationIndex(i) = (mean(acg_wide(bins_wide+1+100:bins_wide+1+140,i)) - mean(acg_wide(bins_wide+1+50:bins_wide+1+70,i)))/(mean(acg_wide(bins_wide+1+50:bins_wide+1+70,i))+mean(acg_wide(bins_wide+1+100:bins_wide+1+140,i)));
    BurstIndex_Royer2012(i) = mean(acg_wide(bins_wide+1+3:bins_wide+1+5,i))/mean(acg_wide(bins_wide+1+200:bins_wide+1+300,i));
end
toc

if p.Results.showFigures
figure, subplot(3,1,1)
histogram(ThetaModulationIndex,40),xlabel('Theta modulation index'), ylabel('Count')
subplot(3,1,2)
histogram(BurstIndex_Royer2012,40),xlabel('BurstIndex Royer2012'), ylabel('Count')
subplot(3,1,3)
histogram(BurstIndex_Doublets,40),xlabel('BurstIndex Doublets'), ylabel('Count')
end
acg_metrics.acg_wide = acg_wide;
acg_metrics.acg_narrow = acg_narrow;
acg_metrics.thetaModulationIndex = ThetaModulationIndex;
acg_metrics.burstIndex_Royer2012 = BurstIndex_Royer2012;
acg_metrics.burstIndex_Doublets = BurstIndex_Doublets;

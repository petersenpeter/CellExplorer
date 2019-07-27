function [PSTH_out,time] = calc_PSTH(events,spikes,varargin)
% PSTH general script
% Dependencies: CCG
% Input and output formats follows the buzcode standard

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited 08-07-2019

p = inputParser;
addParameter(p,'binSize',0.001,@isnumeric);
addParameter(p,'duration',0.4,@isnumeric);
addParameter(p,'smoothing',0,@isnumeric);

parse(p,varargin{:})

binSize = p.Results.binSize;
duration = p.Results.duration;
smoothing = p.Results.smoothing;

spike_times = spikes.spindices(:,1);
spike_cluster_index = spikes.spindices(:,2);
[spike_times,index] = sort([spike_times;events]);
spike_cluster_index = [spike_cluster_index;zeros(size(events,1),1)];
spike_cluster_index = spike_cluster_index(index);
[~, ~, spike_cluster_index] = unique(spike_cluster_index);

[ccg,time] = CCG(spike_times,spike_cluster_index,'binSize',binSize,'duration',duration,'norm','rate');
PSTH_out = flip(ccg(:,2:end,1),1);
if smoothing>0
    PSTH_out = nanconv(PSTH_out,gausswin(smoothing)/sum(gausswin(smoothing)),'edge');
end

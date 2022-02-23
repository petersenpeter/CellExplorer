% This tutorial shows how to add custom ACGs to CellExplorer using the built-on functions.
% In this case we will limit the ACG to manipulation intervals

basepath = pwd; % current folder, replace with your own basepath

% Loading spikes
spikes = loadSpikes('basepath',basepath);

% Generating a new spike struct, to limit the spikes to a defined interval
spikes2 = spikes;
stimIntervals = [0 100;200 4000]; % your manipulation intervals

% Limiting the spike times to the stimulation intervals
spikes_indices = cellfun(@(X) ~ce_InIntervals(X,double(stimIntervals)),spikes2.times,'UniformOutput',false);
spikes2.times = cellfun(@(X,Y) X(Y),spikes2.times,spikes_indices,'UniformOutput',false);
spikes2.total = cell2mat(cellfun(@(X,Y) length(X),spikes2.times,'UniformOutput',false)); % Updating total spike count
spikes2.spindices = generateSpinDices(spikes2.times); % Adding spike indices

% Calculating the ACGs
acg_metrics = calc_ACG_metrics(spikes2,spikes2.sr,'showFigures',false);

% Now add the extra ACGs and time-axis to the cell metrics
cell_metrics.acg.narrow_stim = acg_metrics.acg_narrow;
cell_metrics.general.acgs.narrow_stim = [-100:100]'; % Time axis (in ms)

cell_metrics.general.initialized = 0; % Making sure that the cell metrics will be initialized again

% Visualizing the cell metrics in CellExplorer. A new plot option will now be available called "ACGs (narrow_stim)"
cell_metrics = CellExplorer('metrics',cell_metrics);

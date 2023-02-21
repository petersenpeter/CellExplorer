function cell_metrics = swr_unit_metrics(cell_metrics,session,spikes,parameters)
% swr_unit_metrics: 
%
% INPUTS
% cell_metrics - cell_metrics struct
% session - session struct with session-level metadata
% spikes_intervalsExcluded - spikes struct filtered by (manipulation) intervals
% spikes - spikes cell struct
%   spikes{1} : all spikes
%   spikes{2} : spikes excluding manipulation intervals
% parameters - input parameters to ProcessCellExplorer
%
% OUTPUT
% cell_metrics - updated cell_metrics struct with:
%     cell_metrics.ripple_particip
%     cell_metrics.ripple_FRall
%     cell_metrics.ripple_FRparticip
%     cell_metrics.ripple_GainAll
%     cell_metrics.ripple_GainParticip
%     cell_metrics.ripple_nSpkAll
%     cell_metrics.ripple_nSpkParticip 
%
%     metrics for individual units will be calculated for each state as well
%
% By Ryan Harvey


basepath = session.general.basePath;
basename = basenameFromBasepath(basepath);

if exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file')
    
    load(fullfile(basepath,[basename,'.ripples.events.mat']))
    
    SWRunitMetrics = main(spikes{1},ripples);
    
    % single cell metrics to cell_metrics
    cell_metrics.ripple_particip = SWRunitMetrics.particip;
    cell_metrics.ripple_FRall = SWRunitMetrics.FRall;
    cell_metrics.ripple_FRparticip = SWRunitMetrics.FRparticip;
    cell_metrics.ripple_GainAll = SWRunitMetrics.GainAll;
    cell_metrics.ripple_GainParticip = SWRunitMetrics.GainParticip;
    cell_metrics.ripple_nSpkAll = SWRunitMetrics.nSpkAll;
    cell_metrics.ripple_nSpkParticip = SWRunitMetrics.nSpkParticip;
    
    if any(contains(parameters.metrics,{'state_metrics','all'})) &&...
            ~any(contains(parameters.excludeMetrics,{'state_metrics'}))
        
        spkExclu = setSpkExclu('state_metrics',parameters);
        
        statesFiles = dir(fullfile(basepath,[basename,'.*.states.mat']));
        statesFiles = {statesFiles.name};
        statesFiles(contains(statesFiles,parameters.ignoreStateTypes))=[];
        for iEvents = 1:length(statesFiles)
            statesName = strsplit(statesFiles{iEvents},'.');
            statesName = statesName{end-2};
            eventOut = load(fullfile(basepath,statesFiles{iEvents}));
            
            if isfield(eventOut.(statesName),'ints')
                states = eventOut.(statesName).ints;
                statenames = fieldnames(states);
                for iStates = 1:numel(statenames)
                    if ~size(states.(statenames{iStates}),1) > 0
                        continue
                    end
                    current_ripples = eventIntervals(ripples,states.(statenames{iStates}),true);
                    if isempty(current_ripples)
                        continue
                    end
                    SWRunitMetrics = main(spikes{spkExclu},...
                        current_ripples);
                    
                    % single cell metrics to cell_metrics
                    cell_metrics.(['ripple_particip_' statenames{iStates}]) = SWRunitMetrics.particip;
                    cell_metrics.(['ripple_FRall_' statenames{iStates}]) = SWRunitMetrics.FRall;
                    cell_metrics.(['ripple_FRparticip_' statenames{iStates}]) = SWRunitMetrics.FRparticip;
                    cell_metrics.(['ripple_GainAll_' statenames{iStates}]) = SWRunitMetrics.GainAll;
                    cell_metrics.(['ripple_GainParticip_' statenames{iStates}]) = SWRunitMetrics.GainParticip;
                    cell_metrics.(['ripple_nSpkParticip_' statenames{iStates}]) = SWRunitMetrics.nSpkParticip;
                end
            end
        end
    end
end
end

function spkExclu = setSpkExclu(metrics,parameters)
if ismember(metrics,parameters.metricsToExcludeManipulationIntervals)
    spkExclu = 2; % Spikes excluding times within exclusion intervals
else
    spkExclu = 1; % All spikes (can be restricted)
end
end

function SWRunitMetrics = main(spikes,ripples)

% add spikes and ripples to objects
st = SpikeArray(spikes.times);
ripple_epochs = IntervalArray(ripples.timestamps);

% baseline firing rate
firingRate = st.n_spikes / st.duration;

% bin spikes into ripples and get firing per event
bst = get_participation(st, ripple_epochs, 'firing_rate');

% calc participation prob
SWRunitMetrics.particip = mean(bst>0,2)';

% get ripple firing rate
st_rip = st(ripple_epochs);
SWRunitMetrics.FRall = (st_rip.n_spikes ./ ripple_epochs.duration)';

% get avg firing rate within ripples where the cell was active
for i = 1:size(bst,1)
    SWRunitMetrics.FRparticip(i) = mean(bst(i, bst(i,:) > 0));
end

% get firing rain
SWRunitMetrics.GainAll = (SWRunitMetrics.FRall' ./ firingRate)';

% get gain withing ripples where the cell was active
for i = 1:size(bst,1)
    SWRunitMetrics.GainParticip(i) = mean(bst(i,bst(i,:) > 0)) / firingRate(i);
end

% convert fr matrix to counts matrix by multiplying by ripple durations
counts = bst .* ripple_epochs.lengths';

% get avg number of spikes per event
SWRunitMetrics.nSpkAll = mean(counts,2)';

% get avg number of spikes where the cell was active
for i = 1:size(bst,1)
    SWRunitMetrics.nSpkParticip(i) = mean(counts(i,bst(i,:) > 0));
end
end


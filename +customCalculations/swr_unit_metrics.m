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
    
    SWRunitMetrics = main(basepath,spikes{1},ripples);
    
    % single cell metrics to cell_metrics
    cell_metrics.ripple_particip = SWRunitMetrics.particip';
    cell_metrics.ripple_FRall = SWRunitMetrics.FRall';
    cell_metrics.ripple_FRparticip = SWRunitMetrics.FRparticip';
    cell_metrics.ripple_GainAll = SWRunitMetrics.GainAll';
    cell_metrics.ripple_GainParticip = SWRunitMetrics.GainParticip';
    cell_metrics.ripple_nSpkAll = SWRunitMetrics.nSpkAll';
    cell_metrics.ripple_nSpkParticip = SWRunitMetrics.nSpkParticip';
    
%     % add (n ripple, n cell) metrics to cell_metrics general
%     cell_metrics.general.ripple_participation.ripple_nCellsEvent = SWRunitMetrics.nCellsEvent;
%     cell_metrics.general.ripple_participation.ripple_FReach = SWRunitMetrics.FReach';
%     cell_metrics.general.ripple_participation.ripple_GainEach = SWRunitMetrics.GainEach';
%     cell_metrics.general.ripple_participation.ripple_nSpkEach = SWRunitMetrics.nSpkEach';
%     cell_metrics.general.ripple_participation.ripple_nSpkEvent = SWRunitMetrics.nSpkEvent;
%     cell_metrics.general.ripple_participation.ripple_FRevent = SWRunitMetrics.FRevent;
    
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
                    SWRunitMetrics = main(basepath,...
                        spikes{spkExclu},...
                        current_ripples);
                    
                    % single cell metrics to cell_metrics
                    cell_metrics.(['ripple_particip_' statenames{iStates}]) = SWRunitMetrics.particip';
                    cell_metrics.(['ripple_FRall_' statenames{iStates}]) = SWRunitMetrics.FRall';
                    cell_metrics.(['ripple_FRparticip_' statenames{iStates}]) = SWRunitMetrics.FRparticip';
                    cell_metrics.(['ripple_GainAll_' statenames{iStates}]) = SWRunitMetrics.GainAll';
                    cell_metrics.(['ripple_GainParticip_' statenames{iStates}]) = SWRunitMetrics.GainParticip';
                    cell_metrics.(['ripple_nSpkParticip_' statenames{iStates}]) = SWRunitMetrics.nSpkParticip';
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

function SWRunitMetrics = main(basepath,spikes,ripples)
try
    ripSpk = getRipSpikes('basepath',basepath,...
        'spikes',spikes,...
        'events',ripples.timestamps,...
        'saveMat',false);
catch
    ripSpk = getRipSpikes(spikes,ripples,'saveMat',false);
end
firingRate = spikes.total / (spikes.spindices(end,1) - spikes.spindices(1,1));
SWRunitMetrics = unitSWRmetrics(ripSpk,spikes,'baseFR',firingRate');
end


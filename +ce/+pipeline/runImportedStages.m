function [metrics, results] = runImportedStages(metrics, spikes, session, parameters)
%RUNIMPORTEDSTAGES Import cell-identified maps/PSTHs without writing source files.
results = struct([]);
for kind = {'spatial_metrics','psth_metrics'}
    name = kind{1};
    if ~any(contains(parameters.metrics,{name,'all'})) || any(contains(parameters.excludeMetrics,{name}))
        results = [results,ce.pipeline.stageResult(name,'skipped','not_requested')];
        continue
    end
    inputs.records = ce.pipeline.importedCellFiles(session,name,spikes);
    inputs.UID = spikes.UID;
    if isfield(spikes,'cluID'), inputs.cluID = spikes.cluID; end
    definition = ce.pipeline.stageDefinition(name);
    retired = {};
    if strcmp(name,'spatial_metrics')
        operation = @() ce.pipeline.stages.spatialMetrics(inputs);
        if any(strcmp({inputs.records.name},'ratemap'))
            definition.requiredOutputs = definition.outputs;
        end
        % The original spatial block explicitly retired these legacy containers.
        retired = {'firingRateMap_CoolingStates','firingRateMap_LeftRight','firingRateMap', ...
            'firing_rate_map_states','firing_rate_map','placecell_stability','SpatialCoherence', ...
            'place_cell','placefield_count','placefield_peak_rate','FiringRateMap', ...
            'FiringRateMap_CoolingStates','FiringRateMap_StimStates','FiringRateMap_LeftRight'};
    else
        operation = @() ce.pipeline.stages.importedPsth(inputs);
        for record = inputs.records
            definition.outputs = [definition.outputs,{['psth.',record.name],['general.psth.',record.name]}];
        end
        definition.requiredOutputs = definition.outputs;
        previous = ce.pipeline.outputSnapshot(metrics,{'general.processinginfo.stages.psth_metrics.ownedOutputs'});
        if previous.present, retired = previous.value; end
    end
    % These files are already computed: changing spike intervals cannot recompute
    % their curves. Record only actual import settings, never imply recalculation.
    settings = struct('randomSeed',parameters.randomSeed);
    [metrics,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,operation,parameters.forceReload,retired);
    results = [results,result];
    if strcmp(result.status,'failed')
        error('ce:pipeline:StageFailed','Stage %s failed (%s): %s',result.name,result.error.identifier,result.error.message);
    end
end
end

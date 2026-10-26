function [metrics, results] = runIntervalStages(metrics, spikes, session, parameters, preferences)
%RUNINTERVALSTAGES Execute file-backed event, manipulation and state stages.
plans = ce.pipeline.intervalStagePlans(metrics,session,parameters,preferences);
results = struct([]);
for plan = plans
    if ~plan.selected
        results = [results,ce.pipeline.stageResult(plan.name,'skipped','not_requested')];
        continue
    end
    subset = 1;
    if ismember(plan.name,parameters.metricsToExcludeManipulationIntervals) && ~isempty(parameters.excludeIntervals)
        subset = 2;
    end
    selected = spikes{subset};
    inputs = struct();
    inputs.records = plan.records;
    inputs.spikes = struct('times',{selected.times},'UID',selected.UID,'sr',session.extracellular.sr);
    if isfield(selected,'cluID'), inputs.spikes.cluID = selected.cluID; end
    settings = ce.pipeline.stageSettings(parameters,plan.preferences,subset);
    definition = ce.pipeline.stageDefinition(plan.name);
    definition.outputs = plan.outputs;
    definition.requiredOutputs = plan.outputs;
    if strcmp(plan.name,'state_metrics')
        operation = @() ce.pipeline.stages.stateMetrics(inputs);
    else
        operation = @() ce.pipeline.stages.intervalResponses(inputs,settings,plan.name,parameters.showFigures);
    end
    [metrics,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,operation, ...
        parameters.forceReload,plan.retiredOutputs);
    results = [results,result];
    if strcmp(result.status,'failed')
        error('ce:pipeline:StageFailed','Stage %s failed (%s): %s',result.name,result.error.identifier,result.error.message);
    end
end
end

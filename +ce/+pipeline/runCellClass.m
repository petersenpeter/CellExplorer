function [metrics,result] = runCellClass(metrics, spikes, session, parameters)
%RUNCELLCLASS Always inspect the conventional source, matching legacy selection.
input = ce.pipeline.cellClassInput(session,spikes);
previous = ce.pipeline.outputSnapshot(metrics,{'general.processinginfo.stages.cell_class_import'});
if ~input.available && ~previous.present
    % Legacy values without a managed source are not ours to retire.
    result = ce.pipeline.stageResult('cell_class_import','skipped','source_absent');
    return
end
definition = ce.pipeline.stageDefinition('cell_class_import');
if input.available, definition.requiredOutputs = definition.outputs; end
settings = struct('randomSeed',parameters.randomSeed);
[metrics,result] = ce.pipeline.runStage(metrics,definition,input,settings, ...
    @() ce.pipeline.stages.cellClass(input),parameters.forceReload);
if strcmp(result.status,'failed')
    error('ce:pipeline:StageFailed','Stage %s failed (%s): %s',result.name,result.error.identifier,result.error.message);
end
end

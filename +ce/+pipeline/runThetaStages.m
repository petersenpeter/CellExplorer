function [metrics, results, theta, persistence] = runThetaStages(metrics, spikes, session, parameters, preferences)
%RUNTHETASTAGES Separate LFP preparation, cell metrics and optional plotting.
theta = struct(); persistence = [];
if ~any(contains(parameters.metrics,{'theta_metrics','all'})) || any(contains(parameters.excludeMetrics,{'theta_metrics'}))
    results = [ce.pipeline.stageResult('theta_signal','skipped','not_requested'), ...
        ce.pipeline.stageResult('theta_metrics','skipped','not_requested')];
    return
end
inputs.available = isfield(session,'channelTags') && isfield(session.channelTags,'Theta') && ...
    isfile(fullfile(session.general.basePath,[session.general.name,'.animal.behavior.mat']));
subset = 1;
if ismember('theta_metrics',parameters.metricsToExcludeManipulationIntervals) && ~isempty(parameters.excludeIntervals), subset = 2; end
definition = ce.pipeline.stageDefinition('theta_metrics');
if inputs.available
    recording = ce.pipeline.thetaRecording(session,false);
    inputs.spikes = ce.pipeline.thetaSpikes(spikes{subset},recording);
    inputs.behavior = ce.pipeline.thetaBehavior(session);
    [theta,result,persistence] = ce.pipeline.prepareTheta(session,parameters);
    fail(result);
    results = result;
    inputs.phase = theta.signal_phase{recording.channel};
    inputs.signalOrigin = result.provenance;
    inputs.sr = recording.sr; inputs.srLfp = recording.srLfp;
else
    results = ce.pipeline.stageResult('theta_signal','skipped','missing_behavior_or_channel');
    definition.requiredOutputs = {};
end
settings = ce.pipeline.stageSettings(parameters,preferences.theta,subset);
[metrics,result] = ce.pipeline.runStage(metrics,definition,inputs,settings, ...
    @() ce.pipeline.stages.thetaMetrics(inputs,settings),parameters.forceReload,{'thetaPhaseResponse'});
fail(result);
results = [results,result];
if inputs.available
    metrics.general.processinginfo.stages.theta_signal = results(1).provenance;
    if parameters.showFigures, ce.ui.plotThetaMetrics(metrics); end
end
end

function fail(result)
if strcmp(result.status,'failed')
    error('ce:pipeline:StageFailed','Stage %s failed (%s): %s',result.name,result.error.identifier,result.error.message);
end
end

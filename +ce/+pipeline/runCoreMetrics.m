function [metrics,result] = runCoreMetrics(metrics, spikes, parameters, preferences, subset)
%RUNCOREMETRICS Mandatory legacy final metrics, now independently reusable.
inputs.spikes = struct('times',{spikes.times},'total',spikes.total,'UID',spikes.UID,'cluID',spikes.cluID);
settings = ce.pipeline.stageSettings(parameters, ...
    struct('firingRateAcrossTime_binsize',preferences.other.firingRateAcrossTime_binsize),subset);
% Legacy core rate denominators subtract exclusions even for the full spike
% subset. Retain that convention explicitly; changing it requires a science audit.
settings.excludeIntervals = parameters.excludeIntervals;
[metrics,result] = ce.pipeline.runStage(metrics,ce.pipeline.stageDefinition('other_metrics'), ...
    inputs,settings,@() ce.pipeline.stages.coreMetrics(inputs,settings),parameters.forceReload,{'firingRateAcrossTime'});
if strcmp(result.status,'failed')
    error('ce:pipeline:StageFailed','Stage %s failed (%s): %s',result.name,result.error.identifier,result.error.message);
end
end

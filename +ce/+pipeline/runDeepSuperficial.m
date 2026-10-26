function [metrics,result] = runDeepSuperficial(metrics, spikes, session, parameters)
%RUNDEEPSUPERFICIAL Import channel assignments and preserve cell-level curation.
if ~any(contains(parameters.metrics,{'deepSuperficial','all'})) || any(contains(parameters.excludeMetrics,{'deepSuperficial'}))
    result = ce.pipeline.stageResult('deepSuperficial','skipped','not_requested');
    return
end
inputs.record = ce.pipeline.deepSuperficialInput(session);
if ~isfield(spikes,'UID') || ~isfield(spikes,'maxWaveformCh1') || ...
        ~isnumeric(spikes.UID) || ~isreal(spikes.UID) || ~isrow(spikes.UID) || isempty(spikes.UID) || ...
        numel(unique(spikes.UID)) ~= numel(spikes.UID) || any(~isfinite(spikes.UID))
    error('ce:pipeline:InvalidDeepSuperficialSpikes','Provide unique finite cell UIDs and one-based maxWaveformCh1 values.');
end
channels = spikes.maxWaveformCh1;
if ~isnumeric(channels) || ~isreal(channels) || ~isequal(size(channels),size(spikes.UID)) || ...
        any(~isfinite(channels) | channels < 1 | channels > session.extracellular.nChannels | mod(channels,1) ~= 0)
    error('ce:pipeline:InvalidDeepSuperficialSpikes','maxWaveformCh1 must identify one recording channel per cell, using one-based indices.');
end
inputs.cells = struct('UID',spikes.UID,'maxWaveformCh1',channels);
if isfield(spikes,'cluID')
    if ~isnumeric(spikes.cluID) || ~isreal(spikes.cluID) || ...
            ~isequal(size(spikes.cluID),size(spikes.UID)) || any(~isfinite(spikes.cluID))
        error('ce:pipeline:InvalidDeepSuperficialSpikes','cluID must identify one finite cluster per cell.');
    end
    inputs.cells.cluID = spikes.cluID;
end
inputs.nChannels = session.extracellular.nChannels;
% Classification is precomputed; spike-time restrictions do not regenerate it.
settings = struct('randomSeed',parameters.randomSeed);
previous = metrics;
% ProcessCellMetrics rebuilds its working struct on forceReload. Read only the
% previous annotation context so forcing calculations does not discard review.
if parameters.forceReload && ~isfield(metrics,'UID')
    file = fullfile(session.general.basePath,[session.general.name,'.',parameters.saveAs,'.cellinfo.mat']);
    if ~isfile(file), file = fullfile(session.general.basePath,[parameters.saveAs,'.mat']); end
    if isfile(file)
        loaded = load(file,'cell_metrics');
        if ~isfield(loaded,'cell_metrics') || ~isstruct(loaded.cell_metrics) || ~isscalar(loaded.cell_metrics)
            error('ce:curation:InvalidDeepSuperficial','Cannot recover previous annotations from %s.',file);
        end
        previous = loaded.cell_metrics;
    end
end
[metrics,result] = ce.pipeline.runStage(metrics,ce.pipeline.stageDefinition('deepSuperficial'), ...
    inputs,settings,@() ce.pipeline.stages.deepSuperficial(inputs),parameters.forceReload);
if strcmp(result.status,'failed')
    error('ce:pipeline:StageFailed','Stage %s failed (%s): %s',result.name,result.error.identifier,result.error.message);
end
metrics = ce.curation.reconcileDeepSuperficial(metrics,previous);
end

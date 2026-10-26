function [mono, result, persistence] = prepareMonoSyn(spikes, session, parameters, subset)
%PREPAREMONOSYN Read/verify detection and reconcile reviews without writing files.
file = fullfile(session.general.basePath,[session.general.name,'.mono_res', ...
    erase(parameters.saveAs,'cell_metrics'),'.cellinfo.mat']);
persistence = struct('file',file,'expectedHash','');
previous = struct(); cache = struct();
if isfile(file)
    persistence.expectedHash = ce.pipeline.fileFingerprint(file);
    loaded = load(file,'mono_res');
    if ~isfield(loaded,'mono_res') || ~isstruct(loaded.mono_res) || ~isscalar(loaded.mono_res)
        error('ce:pipeline:InvalidMonoSynFile','The monosynaptic file must contain a scalar mono_res struct.');
    end
    previous = loaded.mono_res;
    origin = ce.pipeline.outputSnapshot(previous,{'processinginfo.detection'});
    if origin.present
        try
            cache.data = ce.pipeline.monoSynAutomatic(previous);
            cache.general.processinginfo.stages.monosynaptic_detection = origin.value;
        catch exception
            if ~strcmp(exception.identifier,'ce:pipeline:InvalidMonoSynDetection'), rethrow(exception); end
            cache = struct(); % Missing automatic fields require a fresh detection.
        end
    end
end
if any(cellfun(@isempty,spikes.times))
    error('ce:pipeline:EmptyMonoSynUnit','Monosynaptic detection requires spikes from every selected unit; choose intervals that retain each unit or supply a consistent reduced session.');
end
% The detector uses positional IDs in spindices, not the session's UID values.
spikes.spindices = generateSpinDices(spikes.times);
spikes.total = cellfun(@numel,spikes.times);
inputs = struct('times',{spikes.times},'UID',spikes.UID,'cluID',spikes.cluID, ...
    'shankID',spikes.shankID,'sr',session.extracellular.sr);
resource = fullfile(fileparts(which('ce_MonoSynConvClick')),'ce_ProbSynMat.mat');
inputs.probabilityResource = struct('present',isfile(resource),'sha256','');
if isfile(resource), inputs.probabilityResource.sha256 = ce.pipeline.fileFingerprint(resource); end
settings = ce.pipeline.stageSettings(parameters,struct(),subset);
settings.includeInhibitoryConnections = parameters.includeInhibitoryConnections;
settings.binSize = .0004; settings.duration = .120; settings.epoch = [0 Inf];
settings.conv_w = .010; settings.alpha = .001; settings.sigWindow = .004;
[cache,result] = ce.pipeline.runStage(cache,ce.pipeline.stageDefinition('monosynaptic_detection'), ...
    inputs,settings,@() ce.pipeline.stages.detectMonoSyn(spikes,inputs.sr,settings),parameters.forceReload);
mono = previous;
if strcmp(result.status,'failed'), return; end
[mono,retained] = ce.curation.reconcileMonoSyn(previous,cache.data,result.provenance);
persistence.reviewRetained = retained;
end

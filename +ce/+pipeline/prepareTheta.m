function [theta, result, persistence] = prepareTheta(session, parameters)
%PREPARETHETA Verify/recompute the conventional theta cache without writing it.
file = fullfile(session.general.basePath,[session.general.name,'.InstantaneousTheta.lfp.mat']);
persistence = struct('file',file,'expectedHash',''); cache = struct();
if isfile(file)
    persistence.expectedHash = ce.pipeline.fileFingerprint(file);
    loaded = load(file,'InstantaneousTheta');
    if ~isfield(loaded,'InstantaneousTheta') || ~isstruct(loaded.InstantaneousTheta) || ~isscalar(loaded.InstantaneousTheta)
        error('ce:pipeline:InvalidThetaCache','Theta cache must contain a scalar InstantaneousTheta struct.');
    end
    previous = loaded.InstantaneousTheta;
    origin = ce.pipeline.outputSnapshot(previous,{'processinginfo.thetaSignal'});
    if origin.present
        cache.data = previous;
        cache.data = rmfield(cache.data,'processinginfo');
        cache.general.processinginfo.stages.theta_signal = origin.value;
    end
    if ~strcmp(persistence.expectedHash,ce.pipeline.fileFingerprint(file))
        error('ce:io:ThetaRevisionChanged','Theta cache changed while it was being read.');
    end
end
[recording,lfp,before] = ce.pipeline.thetaRecording(session);
% Acquisition spike rate is irrelevant to the LFP signal; it belongs to metrics.
inputs = rmfield(recording,'sr');
settings = struct('randomSeed',parameters.randomSeed);
[cache,result] = ce.pipeline.runStage(cache,ce.pipeline.stageDefinition('theta_signal'), ...
    inputs,settings,@calculate,parameters.forceReload);
theta = struct();
if strcmp(result.status,'failed'), return; end
after = dir(lfp);
if isempty(after) || before.bytes ~= after.bytes || before.datenum ~= after.datenum
    error('ce:pipeline:ThetaLfpChanged','LFP changed during theta preparation; results were not saved.');
end
theta = cache.data;
theta.processinginfo.thetaSignal = result.provenance;

    function patch = calculate
        signal = ce.io.readLfpChannel(lfp,recording.nChannels,recording.channel);
        if numel(signal) ~= recording.nSamples
            error('ce:pipeline:ThetaLfpChanged','LFP sample count changed during reading.');
        end
        patch.data = ce.processing.instantaneousTheta(recording.leastSignificantBit*signal,recording.srLfp,recording.channel);
    end
end

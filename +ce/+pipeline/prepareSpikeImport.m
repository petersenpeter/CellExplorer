function [spikes, result, cache, pending] = prepareSpikeImport(session, options, force)
%PREPARESPIKEIMPORT Verify or compute a sorting import; never write files.
% pending contains the source/cache revisions needed for deferred persistence.
if nargin < 3, force = false; end
[inputs,session,importArgs] = ce.pipeline.spikeImportInputs(session,options);
file = fullfile(session.general.basePath,[session.general.name,'.spikeImport.cache.mat']);
cache = struct(); expectedHash = '';
if isfile(file)
    expectedHash = ce.pipeline.fileFingerprint(file);
    if ~force
        loaded = load(file,'spikeImportCache');
        if isfield(loaded,'spikeImportCache') && isstruct(loaded.spikeImportCache) && isscalar(loaded.spikeImportCache)
            cache = loaded.spikeImportCache;
        end
    end
end
settings = struct('randomSeed',0); % Import is deterministic and has no random sampling.
[cache,result] = ce.pipeline.runStage(cache,ce.pipeline.stageDefinition('spike_import',inputs.format),inputs,settings, ...
    @() ce.pipeline.stages.importSpikes(session,importArgs,inputs.membershipHash,inputs.format),force);
if strcmp(result.status,'failed')
    error('ce:pipeline:SpikeImportFailed','Spike import failed (%s): %s',result.error.identifier,result.error.message);
end
pending = struct('file',file,'expectedHash',expectedHash,'session',session,'options',options, ...
    'inputHash',ce.pipeline.fingerprint(inputs));
ce.pipeline.verifySpikeImport(pending);
spikes = cache.data;
ce.pipeline.spikeSortingRevision(spikes);
spikes.processinginfo.importProvenance = result.provenance;
end

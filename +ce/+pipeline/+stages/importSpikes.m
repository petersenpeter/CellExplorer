function patch = importSpikes(session, importArgs, membershipHash, format)
%IMPORTSPIKES Import without writes and bind source membership to output identity.
if strcmp(format,'phy'), spikes=ce.io.importPhySpikes(session,importArgs{:});
else, spikes=ce.io.importNeurosuiteSpikes(session,importArgs{:}); end
identityHash = ce.pipeline.spikeIdentityHash(spikes);
revision = ce.pipeline.fingerprint(struct('schemaVersion',1,'membershipHash',membershipHash,'identityHash',identityHash));
spikes.processinginfo.sortingRevision = revision;
spikes.processinginfo.sortingIdentityHash = identityHash;
patch.data = spikes;
end

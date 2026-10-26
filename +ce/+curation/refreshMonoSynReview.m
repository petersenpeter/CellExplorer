function pending = refreshMonoSynReview(pending, receipt, viewer)
%REFRESHMONOSYNREVIEW Keep a draft usable after our confirmed annotation save.
% Only a receipt replacing the exact reviewed revision may advance its context.
if isempty(pending) || ~strcmp(receipt.file,char(java.io.File(pending.context.metricsFile).getCanonicalPath))
    return
end
previous=pending.context;
if ~receipt.saved || ~strcmp(receipt.previousHash,previous.metricsHash)
    error('ce:curation:FileRevisionChanged','The saved source was not the revision used by this pending review.');
end
ce.curation.verifyFileRevision(receipt.file,receipt.hash);
ce.curation.verifyFileRevision(previous.monoFile,previous.monoHash);
context=ce.curation.beginMonoSynReview(previous.metricsFile,previous.monoFile,viewer,previous.viewerIndices);
if ~strcmp(context.metricsHash,receipt.hash) || ~strcmp(context.monoHash,previous.monoHash) || ...
        ~strcmp(context.automaticHash,previous.automaticHash)
    error('ce:curation:FileRevisionChanged','Review inputs changed after the confirmed annotation save.');
end
if ~strcmp(ce.pipeline.fingerprint(ce.pipeline.monoSynAutomatic(pending.review)),context.automaticHash)
    error('ce:curation:InvalidMonoSynSelection','Pending review changed automatic detection data.');
end
ce.curation.validateMonoSynSelection(pending.review,ce.pipeline.monoSynAutomatic(context.mono));
pending.context=context;
end

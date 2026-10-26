function [state, errors] = checkpoint(metrics, dirty, pending, state)
%CHECKPOINT Persist compact annotation/review drafts; never save metric sources.
errors={};
if ~isempty(dirty), validateattributes(dirty,{'numeric'},{'vector','integer','positive','finite','<=',numel(metrics.UID)}); end
for index=1:numel(state)
    try
    entry=state(index); selected=intersect(entry.indices,dirty,'stable'); review=[];
    if ~isempty(pending) && strcmp(char(java.io.File(pending.context.metricsFile).getCanonicalPath),entry.source)
        context=pending.context;
        automatic=ce.pipeline.monoSynAutomatic(pending.review);
        if ~strcmp(context.automaticHash,ce.pipeline.fingerprint(automatic))
            error('ce:recovery:InvalidReview','Pending review changed automatic detection data.');
        end
        selection=ce.curation.validateMonoSynSelection(pending.review,automatic);
        review=struct('metricsFile',entry.source,'monoFile',context.monoFile, ...
            'metricsHash',context.metricsHash,'monoHash',context.monoHash, ...
            'automaticHash',context.automaticHash,'selection',selection);
        if isfield(pending.review,'manualEdit'), review.manualEdit=pending.review.manualEdit; end
    end
    if isempty(selected) && isempty(review), continue; end
    annotations=ce.curation.captureAnnotations(metrics,entry.indices);
    ce.curation.annotationOrder(entry.baseline,annotations,1:numel(annotations.UID));
    recovery=struct('schemaVersion',1,'source',entry.source,'sourceHash',entry.sourceHash, ...
        'baseline',entry.baseline,'annotations',annotations,'dirtyUIDs',metrics.UID(selected), ...
        'pendingReview',review);
    contentHash=ce.pipeline.fingerprint(recovery);
    if strcmp(contentHash,entry.contentHash), continue; end
    recovery.savedAt=now;
    folder=fileparts(entry.file);
    if ~isfolder(folder)
        [success,message]=mkdir(folder);
        if ~success, error('ce:recovery:WriteFailed','Cannot create recovery directory: %s',message); end
    end
    ce.curation.verifyFileRevision(entry.file,entry.writtenHash);
    ce.io.writeAtomic(entry.file,@(temporary) ce.io.writeMat(temporary,struct('recovery',recovery)), ...
        @(temporary) ce.curation.verifyFileRevision(entry.file,entry.writtenHash));
    state(index).writtenHash=ce.pipeline.fileFingerprint(entry.file);
    state(index).contentHash=contentHash;
    catch exception
        errors{end+1}=sprintf('%s: %s',state(index).source,exception.message);
    end
end
end

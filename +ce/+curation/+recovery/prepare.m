function [metrics, dirty, pending] = prepare(metrics, entry, candidate)
%PREPARE Validate a draft against current source bytes, identity and annotations.
% Only returns in-memory candidates. It never removes journals or saves sources.
ce.curation.verifyFileRevision(candidate.file,candidate.hash);
record=candidate.record;
required={'schemaVersion','source','sourceHash','baseline','annotations','dirtyUIDs','pendingReview'};
if ~isstruct(record) || ~isscalar(record) || ~all(isfield(record,required)) || ...
        ~isequal(record.schemaVersion,1) || ~strcmp(record.source,entry.source)
    error('ce:recovery:InvalidJournal','Unsupported or mismatched recovery journal.');
end
ce.curation.verifyFileRevision(entry.source,record.sourceHash);
order=ce.curation.annotationOrder(record.baseline,metrics,entry.indices);
current=ce.curation.captureAnnotations(metrics,order);
if ~isequaln(current,record.baseline)
    error('ce:recovery:BaselineChanged','Loaded annotations differ from the journal baseline; reconcile them explicitly.');
end
ce.curation.annotationOrder(record.baseline,record.annotations,1:numel(record.annotations.UID));
if ~isnumeric(record.dirtyUIDs) || ~isreal(record.dirtyUIDs) || ...
        (~isempty(record.dirtyUIDs) && ~isvector(record.dirtyUIDs)) || any(~isfinite(record.dirtyUIDs)) || ...
        numel(unique(record.dirtyUIDs))~=numel(record.dirtyUIDs) || ~all(ismember(record.dirtyUIDs,record.baseline.UID))
    error('ce:recovery:InvalidJournal','Journal dirty UIDs do not identify source cells.');
end
[~,positions]=ismember(record.dirtyUIDs,metrics.UID(entry.indices)); dirty=entry.indices(positions);
pending=[];
if ~isempty(record.pendingReview)
    review=record.pendingReview;
    fields={'metricsFile','monoFile','metricsHash','monoHash','automaticHash','selection'};
    if ~isstruct(review) || ~isscalar(review) || ~all(isfield(review,fields)) || ...
            ~strcmp(review.metricsFile,entry.source) || ...
            ~strcmp(fileparts(char(java.io.File(review.monoFile).getCanonicalPath)),fileparts(entry.source))
        error('ce:recovery:InvalidJournal','Pending review does not belong to this source directory.');
    end
    ce.curation.verifyFileRevision(review.metricsFile,review.metricsHash);
    ce.curation.verifyFileRevision(review.monoFile,review.monoHash);
    context=ce.curation.beginMonoSynReview(review.metricsFile,review.monoFile,metrics,entry.indices);
    if ~strcmp(context.automaticHash,review.automaticHash)
        error('ce:recovery:DetectionChanged','Detection changed since the review was journaled.');
    end
    mono=context.mono; mono.sig_con=review.selection.excitatory;
    mono.sig_con_excitatory=review.selection.excitatory; mono.sig_con_inhibitory=review.selection.inhibitory;
    if isfield(review,'manualEdit'), mono.manualEdit=review.manualEdit; end
    ce.curation.validateMonoSynSelection(mono,ce.pipeline.monoSynAutomatic(mono));
    pending=struct('context',context,'review',mono);
end
metrics=ce.curation.restoreAnnotations(metrics,record.annotations,entry.indices);
end

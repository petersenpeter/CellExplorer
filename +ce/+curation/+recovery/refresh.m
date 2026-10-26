function [state, errors] = refresh(metrics, sessions, resetAnnotations, dirty, pending, state, refreshSource, receipts)
%REFRESH Rebase a confirmed save; retain drafts for failed/unsaved sessions.
% Discarding a review only updates its journal, never the expected source bytes.
if nargin<7, refreshSource=true; end
if nargin<8, receipts=struct('file',{},'hash',{}); end
errors={};
refreshed=false(size(state));
for index=reshape(sessions,1,[])
    try
    if resetAnnotations, state(index).baseline=ce.curation.captureAnnotations(metrics,state(index).indices); end
    if refreshSource
        hash=''; baseline=[];
        receipt=find(strcmp({receipts.file},state(index).source),1);
        if ~isempty(receipt)
            % Keep the revision we actually wrote even if another writer has
            % already replaced it. Never adopt that writer's hash as our own.
            state(index).sourceHash=receipts(receipt).hash;
            if resetAnnotations, state(index).diskBaseline=state(index).baseline; end
            ce.curation.verifyFileRevision(state(index).source,state(index).sourceHash);
        end
        if isfile(state(index).source)
            hash=ce.pipeline.fileFingerprint(state(index).source);
            baseline=ce.curation.captureAnnotations(ce.io.readCellMetrics(state(index).source));
            ce.curation.verifyFileRevision(state(index).source,hash);
        end
        if ~isempty(receipt), ce.curation.verifyFileRevision(state(index).source,receipts(receipt).hash); end
        state(index).sourceHash=hash; state(index).diskBaseline=baseline;
    end
    state(index).contentHash='';
    hasReview=~isempty(pending) && strcmp(char(java.io.File(pending.context.metricsFile).getCanonicalPath),state(index).source);
    if isempty(intersect(dirty,state(index).indices)) && ~hasReview
        ce.curation.recovery.retire(state(index).file,state(index).writtenHash);
        state(index).writtenHash='';
        for reference=state(index).recovered
            if isfile(reference.file), ce.curation.recovery.retire(reference.file,reference.hash); end
        end
        state(index).recovered=struct('file',{},'hash',{});
    end
    refreshed(index)=true;
    catch exception
        errors{end+1}=sprintf('%s: %s',state(index).source,exception.message);
    end
end
[state,writeErrors]=ce.curation.recovery.checkpoint(metrics,dirty,pending,state);
errors=[errors,writeErrors];
% Once the remaining draft is durably replaced after our source save, accepted
% older drafts are superseded. A failed checkpoint keeps those older files.
if refreshSource
    for index=reshape(sessions,1,[])
        if ~refreshed(index) || isempty(state(index).contentHash), continue; end
        try
            ce.curation.verifyFileRevision(state(index).file,state(index).writtenHash);
            for reference=state(index).recovered
                ce.curation.recovery.retire(reference.file,reference.hash);
            end
            state(index).recovered=struct('file',{},'hash',{});
        catch exception
            errors{end+1}=sprintf('%s: %s',state(index).source,exception.message);
        end
    end
end
end

function assertSnapshotIdentity(target, source)
%ASSERTSNAPSHOTIDENTITY Validate all sessions before whole-file replacement.
ce.data.metricCellCount(target,true); ce.data.metricCellCount(source,true);
targetBatch=isfield(target.general,'batch'); sourceBatch=isfield(source.general,'batch');
if targetBatch~=sourceBatch
    error('ce:curation:IdentityMismatch','A session and a batch cannot replace each other.');
end
if ~targetBatch
    ce.curation.annotationOrder(target,source,1:numel(source.UID));
    return
end
% Batch IDs are positional; verify session keys before comparing local UIDs.
for key={'basenames','basepaths'}
    name=key{1};
    if ~isfield(target.general,name) || ~isfield(source.general,name) || ...
            ~iscellstr(target.general.(name)) || ~iscellstr(source.general.(name)) || ...
            ~isequal(target.general.(name)(:),source.general.(name)(:))
        error('ce:curation:IdentityMismatch','Batch session names/paths/order differ; save to a new file.');
    end
end
if ~isfield(target,'batchIDs') || ~isfield(source,'batchIDs') || ...
        ~isequal(unique(target.batchIDs),unique(source.batchIDs)) || ...
        numel(target.general.basenames)~=numel(source.general.batch) || ...
        numel(target.general.basenames)~=numel(target.general.batch) || ...
        ~isequal(unique(target.batchIDs),1:numel(target.general.basenames))
    error('ce:curation:IdentityMismatch','Batch session membership differs.');
end
for session=unique(target.batchIDs)
    selected=ce.curation.captureAnnotations(target,find(target.batchIDs==session));
    ce.curation.annotationOrder(selected,source,find(source.batchIDs==session));
end
end

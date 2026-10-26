function [disk, merged] = resolveAnnotationReconciliation(plan, choices)
%RESOLVEANNOTATIONRECONCILIATION Prepare fresh scientific data and merged edits.
if ~iscell(choices) || numel(choices)~=numel(plan.sessions)
    error('ce:curation:InvalidResolution','Provide choices for each source session.');
end
merged=cell(size(plan.sessions));
for k=1:numel(plan.sessions)
    merged{k}=ce.curation.mergeAnnotations(plan.base{k},plan.local{k},plan.disk{k},choices{k});
end
ce.curation.verifyReconciliation(plan);
if plan.batch
    disk=ce.data.assembleMetricBatch(plan.sessions,plan.general.basepaths,plan.general.basenames,'cell_metrics');
    if isfield(plan.general,'saveAs'), disk.general.saveAs=plan.general.saveAs; end
else
    disk=plan.sessions{1};
    for key={'basepath','basename','saveAs','filename'}
        if isfield(plan.general,key{1}), disk.general.(key{1})=plan.general.(key{1});
        elseif isfield(disk.general,key{1}), disk.general=rmfield(disk.general,key{1}); end
    end
end
disk.general.classificationTrackChanges=[];
end

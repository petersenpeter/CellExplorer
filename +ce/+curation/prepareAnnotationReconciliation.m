function plan = prepareAnnotationReconciliation(viewer, state)
%PREPAREANNOTATIONRECONCILIATION Read a consistent candidate; never write files.
sources=ce.curation.recovery.sources(viewer);
if isempty(state) || numel(state)~=numel(sources) || ~isequal({state.source},{sources.file})
    error('ce:curation:MissingBaseline','No matching editing baseline; reload the source or export to a new file.');
end
plan.sessions=cell(1,numel(state)); plan.hashes=cell(size(plan.sessions));
plan.base=cell(size(plan.sessions)); plan.local=cell(size(plan.sessions));
plan.disk=cell(size(plan.sessions)); plan.merged=cell(size(plan.sessions));
plan.conflicts=cell(size(plan.sessions)); plan.files={state.source};
plan.general=viewer.general; plan.batch=isfield(viewer.general,'batch');
for k=1:numel(state)
    if isempty(state(k).diskBaseline)
        error('ce:curation:MissingBaseline','Reconciliation requires an existing source-file baseline.');
    end
    plan.hashes{k}=ce.pipeline.fileFingerprint(state(k).source);
    plan.sessions{k}=ce.io.readCellMetrics(state(k).source);
    plan.base{k}=state(k).diskBaseline;
    plan.local{k}=ce.curation.captureAnnotations(viewer,state(k).indices);
    plan.disk{k}=ce.curation.captureAnnotations(plan.sessions{k});
    [plan.merged{k},plan.conflicts{k}]=ce.curation.mergeAnnotations(plan.base{k},plan.local{k},plan.disk{k});
end
ce.curation.verifyReconciliation(plan);
end

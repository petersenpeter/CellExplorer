function context = beginMonoSynReview(metricsFile, monoFile, viewer, indices)
%BEGINMONOSYNREVIEW Bind review to both disk revisions and session-local cells.
selected=ce.curation.captureAnnotations(viewer,indices);
context.metricsFile=metricsFile; context.monoFile=monoFile;
context.metricsHash=ce.pipeline.fileFingerprint(metricsFile);
context.monoHash=ce.pipeline.fileFingerprint(monoFile);
context.metrics=ce.io.readCellMetrics(metricsFile);
context.viewerIndices=ce.curation.annotationOrder(context.metrics,viewer,indices);
ce.curation.annotationOrder(selected,context.metrics,1:numel(context.metrics.UID));
loaded=load(monoFile,'mono_res');
if ~isfield(loaded,'mono_res'), error('ce:curation:MissingMonoSyn','No mono_res variable in %s.',monoFile); end
context.mono=loaded.mono_res;
automatic=ce.pipeline.monoSynAutomatic(context.mono);
count=numel(context.metrics.UID);
index=automatic.completeIndex;
if ~isfield(context.metrics,'cluID') || ~isfield(context.metrics,'shankID') || ...
        ~isnumeric(index) || ~isequal(size(index),[count 3]) || ...
        ~isequal(sort(index(:,3))',(1:count))
    error('ce:curation:MonoSynIdentityMismatch','Monosynaptic indices must identify every session cell.');
end
[~,order]=sort(index(:,3));
if ~isequal(index(order,1)',context.metrics.shankID) || ~isequal(index(order,2)',context.metrics.cluID)
    error('ce:curation:MonoSynIdentityMismatch','Monosynaptic cluster/group identities differ from the metrics.');
end
revision=ce.data.metricSortingRevision(context.metrics);
identity=ce.pipeline.outputSnapshot(context.mono,{'processinginfo.cellIdentity'});
if identity.present
    expected=struct('UID',context.metrics.UID,'cluID',context.metrics.cluID, ...
        'shankID',context.metrics.shankID,'sortingRevision',revision);
    if ~isequaln(identity.value,expected)
        error('ce:curation:MonoSynIdentityMismatch','Monosynaptic sorting identity differs; recompute detection before review.');
    end
elseif ~isempty(revision)
    error('ce:curation:MonoSynIdentityMismatch','Versioned metrics require versioned detection; recompute monosynaptic detection before review.');
end
for key={'sig_con_excitatory_all','sig_con_inhibitory_all'}
    pairs=automatic.(key{1});
    if ~isnumeric(pairs) || size(pairs,2)~=2 || any(~isfinite(pairs(:)) | pairs(:)<1 | pairs(:)>count | pairs(:)~=fix(pairs(:)))
        error('ce:curation:InvalidMonoSynSelection','Automatic pairs must reference valid session positions.');
    end
end
context.automaticHash=ce.pipeline.fingerprint(automatic);
ce.curation.verifyFileRevision(metricsFile,context.metricsHash);
ce.curation.verifyFileRevision(monoFile,context.monoHash);
end

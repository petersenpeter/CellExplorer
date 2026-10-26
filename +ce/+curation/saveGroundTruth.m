function result = saveGroundTruth(metrics, indices, file)
%SAVEGROUNDTRUTH Replace a catalog subset only within the same source identity.
subset=ce.curation.groundTruthSubset(metrics,indices);
if isfield(metrics.general,'batch')
    sessionIndices=find(metrics.batchIDs==metrics.batchIDs(indices(1)));
else
    sessionIndices=1:numel(metrics.UID);
end
source=ce.curation.captureAnnotations(metrics,sessionIndices);
[folder,~,extension]=fileparts(file);
if isempty(folder), folder=pwd; end
if ~strcmpi(extension,'.mat') || ~isfolder(folder) || isfolder(file)
    error('ce:io:InvalidDestination','Ground-truth exports require a MAT file in an existing directory.');
end
hash=''; result=struct('saved',false,'backup','');
if isfile(file)
    hash=ce.pipeline.fileFingerprint(file); previous=ce.io.readCellMetrics(file);
    if isfield(previous.general,'batch'), error('ce:curation:IdentityMismatch','Ground-truth catalog files must contain one session.'); end
    % A selection may grow/shrink, but every previous cell must still belong to
    % the complete source session. Equal selected counts are never sufficient.
    [found,order]=ismember(previous.UID,source.UID);
    if ~all(found), error('ce:curation:IdentityMismatch','Existing ground truth contains cells outside this source session.'); end
    ce.curation.annotationOrder(previous,source,order);
    for key={'basename','basepath'}
        name=key{1};
        if isfield(previous.general,name) && isfield(subset.general,name) && ...
                ~strcmp(previous.general.(name),subset.general.(name))
            error('ce:curation:IdentityMismatch','Ground-truth source %s differs; use a separate catalog destination.',name);
        end
    end
    result.backup=ce.curation.backupMetricFile(file,hash,previous);
end
ce.io.writeAtomic(file,@(temporary) ce.io.writeMat(temporary,struct('cell_metrics',subset)), ...
    @(temporary) ce.curation.verifyFileRevision(file,hash));
result.saved=true;
end

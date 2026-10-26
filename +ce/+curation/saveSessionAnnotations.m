function result = saveSessionAnnotations(file, source, indices, expectedHash)
%SAVESESSIONANNOTATIONS Validate identity, back up annotations, then save.
% Any failure is reported to the caller; dirty state belongs to the caller.
if nargin<4, expectedHash = ce.pipeline.fileFingerprint(file); end
ce.curation.verifyFileRevision(file,expectedHash);
stored = load(file, 'cell_metrics');
if ~isfield(stored, 'cell_metrics')
    error('ce:curation:MissingMetrics', 'No cell_metrics variable in %s.', file);
end
updated = ce.curation.applyAnnotations(stored.cell_metrics, source, indices);

% Preserve the complete old MAT file and guard changes since the read.
result=ce.curation.saveMetricSnapshot(updated,file,expectedHash);
end

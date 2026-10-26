function saveSessionAnnotations(file, source, indices)
%SAVESESSIONANNOTATIONS Validate identity, back up annotations, then save.
% Any failure is reported to the caller; dirty state belongs to the caller.
stored = load(file, 'cell_metrics');
if ~isfield(stored, 'cell_metrics')
    error('ce:curation:MissingMetrics', 'No cell_metrics variable in %s.', file);
end
updated = ce.curation.applyAnnotations(stored.cell_metrics, source, indices);

% Back up on-disk annotations in their original order in the correct session.
% A failed backup aborts saving rather than losing history.
[folder, filename] = fileparts(file);
backupFolder = fullfile(folder, 'revisions_cell_metrics');
if ~isfolder(backupFolder)
    [success, message] = mkdir(backupFolder);
    if ~success
        error('ce:curation:BackupFailed', 'Could not create backup directory: %s', message);
    end
end
backup = struct();
names = {'UID','cluID','labels','deepSuperficial','deepSuperficialDistance', ...
    'brainRegion','putativeCellType','groups','tags','groundTruthClassification'};
for index = 1:numel(names)
    if isfield(stored.cell_metrics, names{index})
        backup.(names{index}) = stored.cell_metrics.(names{index});
    end
end
saveAs = 'cell_metrics';
if isfield(stored.cell_metrics, 'general') && isfield(stored.cell_metrics.general, 'saveAs')
    saveAs = stored.cell_metrics.general.saveAs;
else
    token = regexp(filename, '\.(cell_metrics.*?)\.cellinfo$', 'tokens', 'once');
    if ~isempty(token)
        saveAs = token{1};
    end
end
[~, suffix] = fileparts(tempname(backupFolder));
timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));
backupFile = fullfile(backupFolder, [char(saveAs), '_', timestamp, '_', suffix, '.mat']);
ce.io.writeMat(backupFile, struct('cell_metrics', backup));
ce.io.saveCellMetrics(updated, file);
end

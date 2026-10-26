function file = writeAnnotationBackup(metrics, indices, folder, saveAs)
%WRITEANNOTATIONBACKUP Store identity-bearing annotations before restoration.
snapshot=ce.curation.captureAnnotations(metrics,indices);
if ~ischar(saveAs) || ~isrow(saveAs) || isempty(saveAs) || any(ismember(saveAs,'/\'))
    error('ce:curation:InvalidBackupName','Backup name must be a nonempty filename component.');
end
if ~isfolder(folder), error('ce:curation:BackupFailed','Session directory does not exist: %s.',folder); end
folder=fullfile(folder,'revisions_cell_metrics');
if ~isfolder(folder)
    [success,message]=mkdir(folder);
    if ~success, error('ce:curation:BackupFailed','Cannot create backup directory: %s',message); end
end
[~,suffix]=fileparts(tempname(folder));
file=fullfile(folder,[saveAs,'_',datestr(now,'yyyy-mm-dd_HHMMSS'),'_',suffix,'.mat']);
ce.io.writeMat(file,struct('cell_metrics',snapshot));
end

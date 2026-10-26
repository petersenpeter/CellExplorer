function backup = backupMetricFile(file, expectedHash, previous)
%BACKUPMETRICFILE Archive exact previous bytes after identity was checked by caller.
[folder,name]=fileparts(file); if isempty(folder), folder=pwd; end
ce.curation.verifyFileRevision(file,expectedHash);
backupFolder=fullfile(folder,'revisions_cell_metrics');
if ~isfolder(backupFolder)
    [success,message]=mkdir(backupFolder);
    if ~success, error('ce:curation:BackupFailed','Cannot create backup directory: %s',message); end
end
prefix='cell_metrics';
if isfield(previous.general,'saveAs') && ischar(previous.general.saveAs) && ...
        isrow(previous.general.saveAs) && ~isempty(previous.general.saveAs) && ...
        ~any(ismember(previous.general.saveAs,'/\'))
    prefix=previous.general.saveAs;
end
parts=strsplit(name,'.');
if numel(parts)>=3 && strcmp(parts{end},'cellinfo'), prefix=parts{end-1}; end
[~,suffix]=fileparts(tempname(backupFolder));
backup=fullfile(backupFolder,[prefix,'_',datestr(now,'yyyy-mm-dd_HHMMSS'),'_',suffix,'.mat']);
ce.io.writeAtomic(backup,@(temporary) copyfile(file,temporary), ...
    @(temporary) ce.curation.verifyFileRevision(temporary,expectedHash));
end

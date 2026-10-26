function result = saveMonoSyn(file, mono, expectedHash)
%SAVEMONOSYN Archive the exact previous file before verified replacement.
% Refuse intervening edits. This is revision checking, not a filesystem lock.
result = struct('saved',false,'backup','');
verifyRevision(file,expectedHash);
if ~isempty(expectedHash)
    loaded = load(file,'mono_res');
    if isfield(loaded,'mono_res') && isequaln(loaded.mono_res,mono), return; end
    [folder,name] = fileparts(file);
    backupFolder = fullfile(folder,'revisions_mono_res');
    if ~isfolder(backupFolder), mkdir(backupFolder); end
    result.backup = fullfile(backupFolder,[name,'.',expectedHash,'.mat']);
    if isfile(result.backup)
        verifyRevision(result.backup,expectedHash);
    else
        ce.io.writeAtomic(result.backup,@(temporary) copyfile(file,temporary), ...
            @(temporary) verifyRevision(temporary,expectedHash));
    end
end
verifyRevision(file,expectedHash);
ce.io.writeMat(file,struct('mono_res',mono));
result.saved = true;
end

function verifyRevision(file,expected)
actual = '';
if isfile(file), actual = ce.pipeline.fileFingerprint(file); end
if ~strcmp(actual,expected)
    error('ce:io:MonoSynRevisionChanged','Monosynaptic file changed since it was read: %s. Reload before saving.',file);
end
end

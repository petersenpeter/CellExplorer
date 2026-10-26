function result=saveSessionMetadata(session,file,expectedHash)
%SAVESESSIONMETADATA Validate, archive exact previous bytes, then replace.
% expectedHash is mandatory: empty means a new destination. Optimistic revision
% checks protect normal concurrent edits; this is not a filesystem lock.
report=ce.data.validateSessionMetadata(session);
if ~report.valid
    error('ce:curation:InvalidSessionMetadata','%s: %s',report.errors(1).path,report.errors(1).message);
end
file=ce.io.canonicalPath(file);
[folder,name,extension]=fileparts(file);
if ~strcmpi(extension,'.mat') || ~isfolder(folder) || isfolder(file)
    error('ce:io:InvalidDestination','Choose a MAT file in an existing directory.');
end
ce.curation.verifyFileRevision(file,expectedHash);
result=struct('saved',false,'file',file,'backup','','previousHash',expectedHash,'hash','');
if ~isempty(expectedHash)
    previous=load(file,'session');
    if ~isfield(previous,'session') || ~isstruct(previous.session) || ~isscalar(previous.session)
        error('ce:curation:InvalidSessionFile','The existing destination is not a session MAT file.');
    end
    backupFolder=fullfile(folder,'revisions_session');
    if ~isfolder(backupFolder)
        [success,message]=mkdir(backupFolder);
        if ~success, error('ce:curation:BackupFailed','Cannot create backup directory: %s',message); end
    end
    [~,suffix]=fileparts(tempname(backupFolder));
    result.backup=fullfile(backupFolder,[name,'_',datestr(now,'yyyy-mm-dd_HHMMSS'),'_',suffix,'.mat']);
    ce.io.writeAtomic(result.backup,@(temporary) copyfile(file,temporary), ...
        @(temporary) ce.curation.verifyFileRevision(temporary,expectedHash));
end
ce.io.writeAtomic(file,@write,@verify);
result.saved=true;
    function write(temporary)
        save(temporary,'session','-v7.3','-nocompression');
    end
    function verify(temporary)
        stored=load(temporary,'session');
        if ~isequaln(stored.session,session)
            error('ce:io:VerificationFailed','Staged session differs from the edited metadata.');
        end
        result.hash=ce.pipeline.fileFingerprint(temporary);
        ce.curation.verifyFileRevision(file,expectedHash);
    end
end

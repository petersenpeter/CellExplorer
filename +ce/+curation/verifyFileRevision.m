function verifyFileRevision(file, expectedHash)
%VERIFYFILEREVISION Optimistic check immediately before destination replacement.
actual='';
if isfile(file), actual=ce.pipeline.fileFingerprint(file); end
if ~strcmp(actual,expectedHash)
    error('ce:curation:FileRevisionChanged','File changed during saving: %s. Reload before retrying.',file);
end
end

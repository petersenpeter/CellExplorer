function hash = fileFingerprint(file)
%FILEFINGERPRINT Hash file contents without loading the entire file into memory.
[fid,message] = fopen(file,'rb');
if fid == -1, error('ce:pipeline:UnreadableDependency','Cannot read %s: %s',file,message); end
cleanup = onCleanup(@() fclose(fid));
digest = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    bytes = fread(fid,1024*1024,'*uint8');
    if ~isempty(bytes), digest.update(typecast(bytes,'int8')); end
end
[message,number] = ferror(fid);
if number ~= 0, error('ce:pipeline:UnreadableDependency','Cannot read %s: %s',file,message); end
hash = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[]));
end

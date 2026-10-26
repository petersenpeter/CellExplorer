function writeAtomic(file, writer, verifier)
%WRITEATOMIC Stage and verify beside the destination before replacement.
% writer(tempFile) must close its handles; verifier(tempFile) throws on failure.
% Same-directory replacement guarantees depend on the filesystem (particularly
% network shares). This does not lock out concurrent writers.
file = char(file);
[folder, ~, extension] = fileparts(file);
if isempty(folder)
    folder = pwd;
end
if ~isfolder(folder) || isfolder(file)
    error('ce:io:InvalidDestination', 'Destination must be a file in an existing directory: %s', file);
end
temporary = [tempname(folder), extension];
cleanup = onCleanup(@() removeTemporary(temporary));
writer(temporary);
if ~isfile(temporary)
    error('ce:io:MissingOutput', 'Writer did not create the staged file for %s.', file);
end
verifier(temporary);
[success, message] = movefile(temporary, file, 'f');
if ~success
    error('ce:io:ReplaceFailed', 'Could not replace %s: %s', file, message);
end
end

function removeTemporary(file)
if isfile(file)
    delete(file);
end
end

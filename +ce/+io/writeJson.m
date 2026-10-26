function writeJson(file, data)
%WRITEJSON Write literal UTF-8 JSON and verify it before replacement.
encoded = jsonencode(data);
ce.io.writeAtomic(file, @write, @verify);

    function write(temporary)
        [fid, message] = fopen(temporary, 'w', 'n', 'UTF-8');
        if fid == -1
            error('ce:io:OpenFailed', 'Could not open staged JSON: %s', message);
        end
        cleanup = onCleanup(@() fclose(fid));
        bytes = unicode2native(encoded, 'UTF-8');
        count = fwrite(fid, bytes, 'uint8');
        [message, errorNumber] = ferror(fid);
        if count ~= numel(bytes) || errorNumber ~= 0
            error('ce:io:WriteFailed', 'Could not finish writing JSON for %s: %s', file, message);
        end
        clear cleanup % Close exactly once, before staged-file verification.

    end

    function verify(temporary)
        jsondecode(fileread(temporary));
    end
end

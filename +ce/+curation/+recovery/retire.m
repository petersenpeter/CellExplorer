function retire(file, hash)
%RETIRE Delete only a journal whose contents still match the selected revision.
if isempty(hash) || ~isfile(file), return; end
ce.curation.verifyFileRevision(file,hash);
delete(file);
end

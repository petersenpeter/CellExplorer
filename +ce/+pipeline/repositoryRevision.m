function revision = repositoryRevision
%REPOSITORYREVISION Read checkout identity without invoking Git or changing state.
% Implementation file hashes, rather than commit identity alone, cover local edits.
revision = '';
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
directory = fullfile(root,'.git');
if ~isfolder(directory), return; end % Installed copies/worktree indirection may have no accessible ref.
try
    head = strtrim(fileread(fullfile(directory,'HEAD')));
    if startsWith(head,'ref: ')
        ref = strtrim(head(6:end));
        file = fullfile(directory,ref);
        if isfile(file)
            revision = strtrim(fileread(file));
        elseif isfile(fullfile(directory,'packed-refs'))
            lines = regexp(fileread(fullfile(directory,'packed-refs')),'\r?\n','split');
            for index = 1:numel(lines)
                parts = strsplit(strtrim(lines{index}));
                if numel(parts)==2 && strcmp(parts{2},ref), revision = parts{1}; break; end
            end
        end
    elseif ~isempty(regexp(head,'^[0-9a-f]{40,64}$','once'))
        revision = head;
    end
catch
    % A missing/inaccessible Git ref must not prevent an installed package running.
end
end

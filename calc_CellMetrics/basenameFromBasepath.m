function basename = basenameFromBasepath(basepath)
    % Determines a basename from a basepath by scanning the directory 
    % Part of CellExplorer, by Peter Petersen
    
    % Looks for certain files from the basepath and if none are present it determines basename from directory name
    file1 = dir(fullfile(basepath,'*.session.mat'));
    file2 = dir(fullfile(basepath,'*.xml'));
    file3 = dir(fullfile(basepath,'*.lfp'));
    file4 = dir(fullfile(basepath,'*.dat'));
    
    if ~isempty(file1)
        file = getBasenameFromDir(file1);
        basename = file(1:end-12);
    elseif ~isempty(file2)
        file = getBasenameFromDir(file4);
        basename = file(1:end-4);
    elseif ~isempty(file3)
        file = getBasenameFromDir(file3);
        basename = file(1:end-4);
    elseif ~isempty(file4)
        file = getBasenameFromDir(file4);
        basename = file(1:end-4);
    else
        disp('Failed to find basepath files')
        [~,basename,~] = fileparts(basepath);
    end

    function basname_out = getBasenameFromDir(dirInput)
        filenames = {dirInput.name};
        for i = 1:numel(filenames)
            if ~startsWith(filenames{i}, '._')
                basname_out = filenames{i};
                return
            end
        end
    end
end
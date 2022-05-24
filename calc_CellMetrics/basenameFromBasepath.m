function basename = basenameFromBasepath(basepath)
    % Determines a basename from a basepath by scanning the directory 
    % Part of CellExplorer, by Peter Petersen
    
    % Uses local files to for CellExplorer specific files from the basepath and if none are present it determines the basename from the directory name
    
    extensions = {'.session.mat','.xml','.lfp','.dat'};
    basename = '';
    for i = 1:numel(extensions)
        file1 = dir(fullfile(basepath,['*',extensions{i}]));
        if ~isempty(file1)
            filenames = {file1.name};
            for k = 1:numel(filenames)
                if ~startsWith(filenames{k}, '._')
                    file = filenames{k};
                    break
                end
            end
            basename = file(1:end-numel(extensions{i}));
        end
        if ~isempty(basename)
            break
        end
    end
    if isempty(basename)
        warning('Failed to find basepath files');
        [~,basename,~] = fileparts(basepath);
    end
end

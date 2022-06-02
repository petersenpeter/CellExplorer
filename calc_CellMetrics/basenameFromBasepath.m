function basename = basenameFromBasepath(basepath)
    % Determines the basename from a basepath by scanning the directory for known files by the following order: 
    % 
    % 1.: *.session.mat
    % 2.: *.xml
    % 3.: *.lfp
    % 4.: *.dat
    % 5.: If no local files are detected it set the basename from the directory name
    %
    % Part of CellExplorer, by Peter Petersen
    
    extensions = {'.session.mat','.xml','.lfp','.dat'};
    file_exclusions = {'settings.xml','._'};
    basename = '';
    file = '';
    for i = 1:numel(extensions)
        file1 = dir(fullfile(basepath,['*',extensions{i}]));
        if ~isempty(file1)
            filenames = {file1.name};
            for k = 1:numel(filenames)
                if ~startsWith(filenames{k},file_exclusions)
                    file = filenames{k};
                    if isempty(basename)
                        basename = file(1:end-numel(extensions{i}));
                    end
                end
            end
        end
        if ~isempty(basename)
            break
        end
    end
    if isempty(basename)
        [~,basename,~] = fileparts(basepath);
    end
end

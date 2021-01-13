function basename = basenameFromBasepath(basepath)
    % Determines a basename from a basepath
    % Part of CellExplorer, by Peter Petersen
    [~,basename,~] = fileparts(basepath);
end
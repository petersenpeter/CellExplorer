function basename = basenameFromBasepath(basepath)
    % Determines a basename from a basepath by scanning the directory 
    % Part of CellExplorer, by Peter Petersen
    
    file1 = dir(fullfile(basepath,'*.session.mat'));
    file2 = dir(fullfile(basepath,'*.xml'));
    file3 = dir(fullfile(basepath,'*.lfp'));
    file4 = dir(fullfile(basepath,'*.dat'));
    if ~isempty(file1)
        file = file1.name;
    elseif ~isempty(file2)
        file = file2.name;
    elseif ~isempty(file3)
        file = file3.name;
    elseif ~isempty(file4)
        file = file4.name;
    else
        disp('Failed to find basepath files')
        [~,basename,~] = fileparts(basepath);
        return
    end
    temp = strsplit(file,'.');
    basename = temp{1};
end
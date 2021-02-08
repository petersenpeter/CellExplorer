function data = detectCellExplorerFiles(basepath,basename)
    % Detects CellExplorer/Buzcode container files in a basepath. This function is part of CellExplorer
    
    % By Peter Petersen
    
    data = {};
    containers = {'events','timeseries','cellinfo','manipulation','channelinfo','behavior','states'};
    for i = 1:numel(containers)
        fileList = dir(fullfile(basepath,[basename '.*.',containers{i},'.mat']));
        if ~isempty(fileList)
            fileList = {fileList.name};
            fileList = split(fileList,'.');
            if size(fileList,2)>1
                fileList = fileList(:,:,2);
            else
                fileList = fileList(2);
            end
            data.(containers{i}) = fileList;
        end
    end
end

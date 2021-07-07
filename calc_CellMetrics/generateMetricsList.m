function [list_metrics,ia] = generateMetricsList(cell_metrics,fieldType,preselectedList)
    subfieldsnames = fieldnames(cell_metrics);
    subfieldstypes = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
    subfieldssizes = struct2cell(structfun(@size,cell_metrics,'UniformOutput',false));
    subfieldssizes = cell2mat(subfieldssizes);
    list_metrics = {};
    if any(strcmp(fieldType,{'double','all'}))
        temp = find(strcmp(subfieldstypes,'double') & subfieldssizes(:,2) == length(cell_metrics.cellID) & ~contains(subfieldsnames,'_num'));
        list_metrics = sort(subfieldsnames(temp));
    end
    if any(strcmp(fieldType,{'struct','all'}))
        temp2 = find(strcmp(subfieldstypes,'struct') & ~ismember(subfieldsnames,{'general','groups','tags','groundTruthClassification'}));
        for i = 1:length(temp2)
            fieldname = subfieldsnames{temp2(i)};
            subfieldsnames1 = fieldnames(cell_metrics.(fieldname));
            subfieldstypes1 = struct2cell(structfun(@class,cell_metrics.(fieldname),'UniformOutput',false));
            subfieldssizes1 = struct2cell(structfun(@size,cell_metrics.(fieldname),'UniformOutput',false));
            subfieldssizes1 = cell2mat(subfieldssizes1);
            temp1 = find(strcmp(subfieldstypes1,'double') & subfieldssizes1(:,2) == length(cell_metrics.cellID) & ~contains(subfieldsnames1,'_num'));
            list_metrics = [list_metrics;strcat({fieldname},{'.'},subfieldsnames1(temp1))];
        end
        subfieldsExclude = {'UID','batchIDs','cellID','cluID','maxWaveformCh1','maxWaveformCh','sessionID','electrodeGroup','spikeSortingID','entryID'};
        list_metrics = setdiff(list_metrics,subfieldsExclude);
    end
    if exist('preselectedList','var')
        [~,ia,~] = intersect(list_metrics,preselectedList);
        list_metrics = [list_metrics(ia);list_metrics(setdiff(1:length(list_metrics),ia))];
    else
        ia = [];
    end
end
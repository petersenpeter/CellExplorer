function cell_metrics = verifyGroupFormat(cell_metrics,fieldToVerify)
    if isfield(cell_metrics,fieldToVerify) && ~isstruct(cell_metrics.(fieldToVerify))
        group = cell_metrics.(fieldToVerify);
        cell_metrics = rmfield(cell_metrics,fieldToVerify);
        groupsInMetrics = unique([group{:}]);
        tagFilter = find(cellfun(@(X) ~isempty(X), group));
        for i = 1:length(groupsInMetrics)
            idx = cell2mat(cellfun(@(X) ismember(X,groupsInMetrics{i}), group,'uni',0));
            tag_name = groupsInMetrics{i};
            tag_name = strrep(tag_name,'+','_pos');
            tag_name = strrep(tag_name,'-','_neg');
            if isvarname(tag_name) && ~isempty(tag_name)
                cell_metrics.(fieldToVerify).(tag_name) = tagFilter(idx);
            elseif ~isvarname(tag_name) && ~isempty(tag_name)
                tag_name = matlab.lang.makeValidName(tag_name);
                if ~isfield(cell_metrics,fieldToVerify) || (isfield(cell_metrics,fieldToVerify) && ~isfield(cell_metrics.(fieldToVerify),tag_name))
                    cell_metrics.(fieldToVerify).(tag_name) = tagFilter(idx);
                elseif isfield(cell_metrics,fieldToVerify) && isfield(cell_metrics.(fieldToVerify),tag_name)
                    fields_1 = fieldnames(cell_metrics.(fieldToVerify));
                    tag_name = matlab.lang.makeUniqueStrings([fields_1,tag_name]);
                    cell_metrics.(fieldToVerify).(tag_name{end}) = tagFilter(idx);
                end
            end
        end
    end
end

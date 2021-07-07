function cell_metrics = validateGroupFormat(cell_metrics,fieldToValidate)
    if isfield(cell_metrics,fieldToValidate) && ~isstruct(cell_metrics.(fieldToValidate))
        group = cell_metrics.(fieldToValidate);
        cell_metrics = rmfield(cell_metrics,fieldToValidate);
        groupsInMetrics = unique([group{:}]);
        tagFilter = find(cellfun(@(X) ~isempty(X), group));
        for i = 1:length(groupsInMetrics)
            idx = cell2mat(cellfun(@(X) ismember(X,groupsInMetrics{i}), group,'uni',0));
            tag_name = groupsInMetrics{i};
            tag_name = strrep(tag_name,'+','_pos');
            tag_name = strrep(tag_name,'-','_neg');
            if isvarname(tag_name) && ~isempty(tag_name)
                cell_metrics.(fieldToValidate).(tag_name) = tagFilter(idx);
            elseif ~isvarname(tag_name) && ~isempty(tag_name)
                tag_name = matlab.lang.makeValidName(tag_name);
                if ~isfield(cell_metrics,fieldToValidate) || (isfield(cell_metrics,fieldToValidate) && ~isfield(cell_metrics.(fieldToValidate),tag_name))
                    cell_metrics.(fieldToValidate).(tag_name) = tagFilter(idx);
                elseif isfield(cell_metrics,fieldToValidate) && isfield(cell_metrics.(fieldToValidate),tag_name)
                    fields_1 = fieldnames(cell_metrics.(fieldToValidate));
                    tag_name = matlab.lang.makeUniqueStrings([fields_1,tag_name]);
                    cell_metrics.(fieldToValidate).(tag_name{end}) = tagFilter(idx);
                end
            end
        end
    end
end

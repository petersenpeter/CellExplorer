function groups = metricGroups(value, count, description)
%METRICGROUPS Normalize legacy per-cell tag lists to one-based local indices.
if iscell(value)
    if numel(value) ~= count || ~isvector(value)
        error('ce:data:InvalidMetricGroups','%s requires one legacy group list per cell.',description);
    end
    labels = {}; members = {};
    for index = 1:count
        names = value{index};
        if isempty(names), continue; end
        if ischar(names), names = {names}; end
        if ~iscellstr(names), error('ce:data:InvalidMetricGroups','%s group names must be character rows.',description); end
        for item = names(:)'
            name = item{1}; if isempty(name), continue; end
            position = find(strcmp(labels,name),1);
            if isempty(position)
                labels{end+1} = name; members{end+1} = index;
            else
                members{position}(end+1) = index;
            end
        end
    end
    [labels,order] = sort(labels); members = members(order);
    groups = struct();
    for index = 1:numel(labels)
        name = strrep(strrep(labels{index},'+','_pos'),'-','_neg');
        name = matlab.lang.makeValidName(name);
        name = matlab.lang.makeUniqueStrings(name,fieldnames(groups));
        groups.(name) = unique(members{index},'stable');
    end
elseif isstruct(value) && isscalar(value)
    groups = value;
else
    error('ce:data:InvalidMetricGroups','%s must contain index groups or legacy per-cell lists.',description);
end
for key = fieldnames(groups)'
    indices = groups.(key{1});
    if ~isnumeric(indices) || ~isreal(indices) || ~isempty(indices) && ~isvector(indices) || ...
            any(~isfinite(indices(:)) | indices(:) < 1 | indices(:) > count | indices(:) ~= fix(indices(:)))
        error('ce:data:InvalidMetricGroups','%s.%s contains invalid one-based cell indices.',description,key{1});
    end
    groups.(key{1}) = indices(:)';
end
end

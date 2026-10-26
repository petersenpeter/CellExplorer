function subset = subsetGroups(groups, indices)
%SUBSETGROUPS Convert source cell indices to positions in an ordered subset.
subset = struct();
names = fieldnames(groups);
for index = 1:numel(names)
    selected = find(ismember(indices, groups.(names{index})));
    if ~isempty(selected)
        subset.(names{index}) = reshape(selected, 1, []);
    end
end
end

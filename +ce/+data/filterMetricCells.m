function indices = filterMetricCells(metrics, filters)
%FILTERMETRICCELLS OR within a filter, AND across filters; do not subset data.
count = ce.data.metricCellCount(metrics,true); selected = true(1,count);
for key = {'brainRegion','animal','labels','synapticEffect','putativeCellType','deepSuperficial'}
    name = key{1};
    if ~isfield(filters,name) || isempty(filters.(name)), continue; end
    match = false(1,count);
    if isfield(metrics,name)
        values = metrics.(name);
        if ~iscellstr(values) || numel(values) ~= count
            error('ce:data:InvalidMetricFilter','%s must contain one character label per cell.',name);
        end
        if ismember(name,{'brainRegion','animal','labels'})
            match = ismember(values(:)',filters.(name));
        else
            match = contains(values(:)',filters.(name));
        end
    end
    selected = selected & match;
end
for key = {'tags','groups','groundTruthClassification'}
    name = key{1};
    if ~isfield(filters,name) || isempty(filters.(name)), continue; end
    match = false(1,count);
    if isfield(metrics,name)
        groups = ce.data.metricGroups(metrics.(name),count,name);
        for tag = filters.(name)(:)'
            if isfield(groups,tag{1}), match(groups.(tag{1})) = true; end
        end
    end
    selected = selected & match;
end
indices = find(selected);
end

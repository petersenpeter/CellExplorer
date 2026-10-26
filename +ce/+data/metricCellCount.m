function count = metricCellCount(metrics, allowBatch)
%METRICCELLCOUNT Validate identity before loading/assembling per-cell data.
if nargin < 2, allowBatch = false; end
if ~isstruct(metrics) || ~isscalar(metrics) || ~isfield(metrics,'general') || ...
        ~isstruct(metrics.general) || ~isscalar(metrics.general) || ...
        ~isfield(metrics.general,'cellCount') || ~isfield(metrics,'UID')
    error('ce:data:InvalidMetricIdentity','Metrics require a scalar general struct, cellCount and UID.');
end
count = metrics.general.cellCount;
if ~isnumeric(count) || ~isreal(count) || ~isscalar(count) || ~isfinite(count) || count < 1 || count ~= fix(count)
    error('ce:data:InvalidMetricIdentity','general.cellCount must be a positive integer.');
end
ids = metrics.UID;
if ~isnumeric(ids) || ~isreal(ids) || ~isequal(size(ids),[1 count]) || any(~isfinite(ids))
    error('ce:data:InvalidMetricIdentity','UID must be a finite numeric row matching cellCount.');
end
if isfield(metrics,'batchIDs')
    batch = metrics.batchIDs;
    if ~allowBatch || ~isnumeric(batch) || ~isreal(batch) || ~isequal(size(batch),[1 count]) || ...
            any(~isfinite(batch) | batch < 1 | batch ~= fix(batch))
        error('ce:data:InvalidMetricIdentity','Nested batches are unsupported; batchIDs must identify each cell in a loaded batch.');
    end
    for index = unique(batch)
        selected = ids(batch == index);
        if numel(unique(selected)) ~= numel(selected)
            error('ce:data:InvalidMetricIdentity','UID values must be unique within each session.');
        end
    end
elseif numel(unique(ids)) ~= count
    error('ce:data:InvalidMetricIdentity','UID values must be unique within each session.');
end
for key = {'cellID','cluID'}
    name = key{1};
    if isfield(metrics,name)
        value = metrics.(name);
        if ~isnumeric(value) || ~isreal(value) || ~isequal(size(value),[1 count]) || any(~isfinite(value))
            error('ce:data:InvalidMetricIdentity','%s must be a finite numeric row matching cellCount.',name);
        end
    end
end
end

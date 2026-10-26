function metrics = readCellMetrics(file, variableName)
%READCELLMETRICS Read a named MAT variable without UI, database or cwd changes.
% Comparison caches use reference_cell_metrics or groundTruth_cell_metrics.
if nargin < 2, variableName = 'cell_metrics'; end
if ~ismember(variableName,{'cell_metrics','reference_cell_metrics','groundTruth_cell_metrics'})
    error('ce:io:InvalidMetricVariable','Unsupported metric variable name.');
end
if ~isfile(file), error('ce:io:MissingMetrics','Metrics file not found: %s.',file); end
loaded = load(file,variableName);
if ~isfield(loaded,variableName)
    error('ce:io:InvalidMetricsFile','%s must contain a %s variable.',file,variableName);
end
metrics = loaded.(variableName);
ce.data.metricCellCount(metrics,true);
end

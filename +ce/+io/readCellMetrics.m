function metrics = readCellMetrics(file)
%READCELLMETRICS Read a named MAT variable without UI, database or cwd changes.
if ~isfile(file), error('ce:io:MissingMetrics','Metrics file not found: %s.',file); end
loaded = load(file,'cell_metrics');
if ~isfield(loaded,'cell_metrics')
    error('ce:io:InvalidMetricsFile','%s must contain a cell_metrics variable.',file);
end
metrics = loaded.cell_metrics;
ce.data.metricCellCount(metrics,true);
end

function metrics = recordRun(metrics, spikes, parameters, stageResults)
%RECORDRUN Describe the invocation without relabeling stage generation records.
metrics.general.processinginfo.latestRun.stages = stageResults;
metrics.general.processinginfo.latestRun.date = now;
% Legacy top-level parameters describe the invocation; stages retain generation provenance.
metrics.general.processinginfo.params = parameters;
metrics.general.processinginfo.function = 'ProcessCellMetrics';
metrics.general.processinginfo.date = now;
metrics.general.processinginfo.version = 2.1;
try
    metrics.general.processinginfo.username = char(java.lang.System.getProperty('user.name'));
    metrics.general.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
catch
    disp('Failed to retrieve system info.')
end
if isfield(metrics.general.processinginfo,'spikes')
    metrics.general.processinginfo = rmfield(metrics.general.processinginfo,'spikes');
end
if isfield(spikes,'processinginfo')
    metrics.general.processinginfo.spikes = spikes.processinginfo;
end

% Restricted intervals (latest invocation; stage records retain their own selection).
for name = {'restrictToIntervals','excludeIntervals'}
    if isfield(metrics.general,name{1}), metrics.general = rmfield(metrics.general,name{1}); end
end
if ~isempty(parameters.restrictToIntervals) && size(parameters.restrictToIntervals,2) == 2
    metrics.general.restrictToIntervals = parameters.restrictToIntervals;
end
if ~isempty(parameters.excludeIntervals) && size(parameters.excludeIntervals,2) == 2
    metrics.general.excludeIntervals = parameters.excludeIntervals;
end

end

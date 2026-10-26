function revision = metricSortingRevision(metrics, indices)
%METRICSORTINGREVISION Read a session-local revision, including within batches.
revision = '';
if ~isfield(metrics,'general'), return; end
general = metrics.general;
if isfield(general,'batch')
    if nargin < 2, indices = 1:numel(metrics.UID); end
    if ~isfield(metrics,'batchIDs') || ~isnumeric(metrics.batchIDs) || numel(metrics.batchIDs)~=numel(metrics.UID)
        error('ce:data:InvalidSortingRevision','Batch sorting revisions need one batchID per cell.');
    end
    selected = unique(metrics.batchIDs(indices));
    if numel(selected)~=1 || ~isfinite(selected) || selected<1 || selected~=fix(selected) || ...
            ~iscell(general.batch) || selected>numel(general.batch)
        error('ce:data:InvalidSortingRevision','Select exactly one session when comparing sorting revisions.');
    end
    general = general.batch{selected};
end
if ~isstruct(general) || ~isscalar(general)
    error('ce:data:InvalidSortingRevision','Expected scalar session metadata for the sorting revision.');
end
if isfield(general,'sortingRevision'), revision = ce.data.validateSortingRevision(general.sortingRevision); end
end

function revision = spikeSortingRevision(spikes)
%SPIKESORTINGREVISION Validate the revision before pipeline interval filtering.
revision = '';
if ~isfield(spikes,'processinginfo') || ~isfield(spikes.processinginfo,'sortingRevision'), return; end
info = spikes.processinginfo;
revision = ce.data.validateSortingRevision(info.sortingRevision);
if ~isfield(info,'sortingIdentityHash') || ~strcmp(info.sortingIdentityHash,ce.pipeline.spikeIdentityHash(spikes))
    error('ce:pipeline:InvalidSortingRevision','Spikes changed since import; regenerate their sorting revision before processing.');
end
end

function [metrics,session] = updateMetadata(metrics, spikes, session)
%UPDATEMETADATA Refresh owned metadata independently of numerical stage caches.
count = numel(spikes.UID);
session.general.sessionName = session.general.name;
metrics.sessionName = repmat({session.general.name},1,count);
metrics.animal = repmat({session.animal.name},1,count);
if ~isfield(metrics.general,'session'), metrics.general.session = struct(); end
if ~isfield(metrics.general,'animal'), metrics.general.animal = struct(); end
for name = {'investigator','sessionType'}
    metrics.general.session = copyOptional(metrics.general.session,session.general,name{1});
end
metrics.general.session = remove(metrics.general.session,'spikeSortingMethod');
if isfield(session.spikeSorting{1},'method')
    metrics.general.session.spikeSortingMethod = session.spikeSorting{1}.method;
end
for name = {'sex','species','strain','geneticLine'}
    metrics.general.animal = copyOptional(metrics.general.animal,session.animal,name{1});
end
metrics.general = copyOptional(metrics.general,session,'epochs');
metrics = remove(metrics,'sessionID'); metrics = remove(metrics,'spikeSortingID');
if isfield(session.general,'entryID') && ~isempty(session.general.entryID)
    metrics.sessionID = repmat(parseID(session.general.entryID,'session'),1,count);
end
if isfield(session.spikeSorting{1},'entryID') && ~isempty(session.spikeSorting{1}.entryID)
    metrics.spikeSortingID = repmat(parseID(session.spikeSorting{1}.entryID,'spike sorting'),1,count);
end
metrics.cellID = spikes.UID; metrics.UID = spikes.UID; metrics.cluID = spikes.cluID;
metrics.electrodeGroup = spikes.shankID;
metrics.maxWaveformCh = spikes.maxWaveformCh1-1;
metrics.maxWaveformCh1 = spikes.maxWaveformCh1;
metrics.general.electrodeGroups = session.extracellular.electrodeGroups.channels;
if isfield(session,'brainRegions') && ~isempty(session.brainRegions)
    regions = findBrainRegion(session); % Keep existing mapping conventions.
    metrics.brainRegion = regions(spikes.maxWaveformCh1);
end
channels = [session.extracellular.electrodeGroups.channels{:}];
metrics.maxWaveformChannelOrder = nan(1,count);
for j = 1:count
    index = find(channels == spikes.maxWaveformCh1(j));
    if isscalar(index), metrics.maxWaveformChannelOrder(j) = index; end
end
end

function target = copyOptional(target,source,name)
target = remove(target,name);
if isfield(source,name), target.(name) = source.(name); end
end

function value = remove(value,name)
if isfield(value,name), value = rmfield(value,name); end
end

function value = parseID(value,source)
if ischar(value) || isstring(value) && isscalar(value), value = str2double(value); end
if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ~isfinite(value)
    error('ce:pipeline:InvalidMetadataID','The %s entryID must be one finite number, not an expression.',source);
end
end

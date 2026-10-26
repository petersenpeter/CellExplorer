function data = deepSuperficialChannels(data, session)
%DEEPSUPERFICIALCHANNELS Validate channel identity before mapping classifications.
n = session.extracellular.nChannels;
if ~isstruct(data) || ~isscalar(data) || ~all(isfield(data,{'channel','channelClass','channelDistance'}))
    error('ce:data:InvalidDeepSuperficial','Classification requires channel, channelClass and channelDistance.');
end
ids = data.channel;
if ~isnumeric(ids) || ~isreal(ids) || ~isvector(ids) || numel(ids) ~= n || ...
        ~isequal(sort(double(ids(:))),(1:n)')
    error('ce:data:DeepSuperficialChannelIdentity','Classification channel must explicitly identify every recording channel once, using one-based IDs.');
end
labels = data.channelClass; distances = data.channelDistance;
if ~iscell(labels) || ~isvector(labels) || numel(labels) ~= n || ...
        ~all(cellfun(@(x) ischar(x) && (isrow(x) || isempty(x)),labels)) || ...
        ~isnumeric(distances) || ~isreal(distances) || ~isvector(distances) || ...
        numel(distances) ~= n || any(isinf(distances(:)))
    error('ce:data:InvalidDeepSuperficial','Each channel needs a text label and a numeric distance in micrometers (NaN is permitted).');
end
[~,order] = ismember(1:n,ids);
data.channel = (1:n)';
data.channelClass = reshape(labels(order),[],1);
data.channelDistance = reshape(distances(order),[],1);
if isfield(data,'ripple_channels')
    expected = session.extracellular.electrodeGroups.channels;
    if isnumeric(expected), expected = num2cell(expected,2); end
    if ~iscell(data.ripple_channels) || numel(data.ripple_channels) ~= numel(expected)
        error('ce:data:DeepSuperficialGroupIdentity','Classification electrode groups do not match session metadata.');
    end
    for index = 1:numel(expected)
        if ~isequal(data.ripple_channels{index}(:),expected{index}(:))
            error('ce:data:DeepSuperficialGroupIdentity','Classification channel order for electrode group %d differs from the session. Reconcile the source classification first.',index);
        end
    end
end
end

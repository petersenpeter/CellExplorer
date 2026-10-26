function hash = spikeIdentityHash(spikes)
%SPIKEIDENTITYHASH Bind a declared sorting revision to the unfiltered spike data.
names = {'UID','cluID','sr','times'};
if ~isstruct(spikes) || ~isscalar(spikes) || ~all(isfield(spikes,names))
    error('ce:pipeline:InvalidSortingRevision','Versioned spikes require UID, cluID, sr and times.');
end
identity = struct();
for key = {'UID','cluID','shankID','sr','times','ts'}
    if isfield(spikes,key{1}), identity.(key{1})=spikes.(key{1}); end
end
hash = ce.pipeline.fingerprint(identity);
end

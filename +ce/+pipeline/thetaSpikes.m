function selected = thetaSpikes(spikes, recording)
%THETASPIKES Validate seconds/sample correspondence before phase indexing.
if ~all(isfield(spikes,{'times','ts','UID'})) || ~iscell(spikes.times) || ~iscell(spikes.ts) || ...
        numel(spikes.times) ~= numel(spikes.UID) || numel(spikes.ts) ~= numel(spikes.UID)
    error('ce:pipeline:InvalidThetaSpikes','Theta needs times (seconds) and ts (acquisition samples) for each UID.');
end
selected = struct('times',{spikes.times},'ts',{spikes.ts},'UID',spikes.UID);
if isfield(spikes,'cluID'), selected.cluID = spikes.cluID; end
for index = 1:numel(selected.times)
    times = selected.times{index}; samples = selected.ts{index};
    if ~isnumeric(times) || ~isreal(times) || ~isnumeric(samples) || ~isreal(samples) || ...
            ~isequal(size(times),size(samples)) || (~isempty(times) && ~isvector(times)) || ...
            any(~isfinite(times(:))) || any(~isfinite(samples(:))) || ...
            any(times(:) < 0) || any(samples(:) < 0 | mod(samples(:),1) ~= 0) || ...
            any(abs(double(samples(:))/recording.sr-times(:)) > (1+1e-6)/recording.sr)
        error('ce:pipeline:InvalidThetaSpikes','UID %g: ts must be integer acquisition samples aligned with times within one sample.',spikes.UID(index));
    end
    keep = times < recording.nSamples/recording.srLfp;
    indices = ceil(samples(keep)*recording.srLfp/recording.sr);
    if any(indices < 1 | indices > recording.nSamples)
        error('ce:pipeline:InvalidThetaSpikeSamples', ...
            'UID %g maps outside one-based LFP samples. Check the timestamp origin; the legacy ceil(ts*srLfp/sr) convention is preserved.',spikes.UID(index));
    end
end
end

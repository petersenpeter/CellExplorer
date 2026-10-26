function needed = needsWaveforms(spikes)
%NEEDSWAVEFORMS Check cached extraction metadata without assuming nested fields.
needed = true;
if isfield(spikes,'processinginfo') && isstruct(spikes.processinginfo) && isscalar(spikes.processinginfo)
    info = spikes.processinginfo;
    if isfield(info,'params') && isstruct(info.params) && isscalar(info.params) && ...
            isfield(info.params,'WaveformsSource') && isfield(info,'version') && ...
            isnumeric(info.version) && isscalar(info.version) && isfinite(info.version)
        needed = ~strcmp(info.params.WaveformsSource,'dat file') || info.version < 3.5;
    end
end
end

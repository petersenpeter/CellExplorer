function inputs = localizationInputs(metrics, spikes, session, geometry)
%LOCALIZATIONINPUTS Only waveform, identity, channel and coordinate dependencies.
inputs.geometry = geometry;
inputs.spikes.shankID = spikes.shankID;
inputs.UID = spikes.UID;
if isfield(spikes,'cluID'), inputs.cluID = spikes.cluID; end
inputs.electrodeGroups = session.extracellular.electrodeGroups;
inputs.badChannels = get_bad_channels(session);
inputs.peakVoltage = metrics.peakVoltage;
inputs.maxWaveformCh1 = metrics.maxWaveformCh1;
inputs.waveforms = struct();
for name = {'filt_all','channels_all'}
    if isfield(metrics.waveforms,name{1}), inputs.waveforms.(name{1}) = metrics.waveforms.(name{1}); end
end
end

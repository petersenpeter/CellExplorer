function inputs = stageInputs(name, spikes, session)
%STAGEINPUTS Explicit consumed data and cell identity, excluding volatile metadata.
inputs.sr = session.extracellular.sr;
fields = {'UID','cluID','times','total'};
switch name
    case 'waveform_shape'
        fields = [fields, {'shankID','peakVoltage','peakVoltage_expFitLengthConstant', ...
            'filtWaveform_std','rawWaveform','rawWaveform_std','rawWaveform_all', ...
            'filtWaveform_all','timeWaveform_all','channels_all','filtWaveform', ...
            'timeWaveform','maxWaveform_all'}];
        inputs.nChannels = session.extracellular.nChannels;
        inputs.electrodeGroups = session.extracellular.electrodeGroups;
        if isfield(session,'channelTags'), inputs.channelTags = session.channelTags; end
    case 'acg_metrics'
        fields{end+1} = 'spindices';
    otherwise
        error('ce:pipeline:UnknownStage','Unknown stage %s.',name);
end
for index = 1:numel(fields)
    if isfield(spikes,fields{index}), inputs.spikes.(fields{index}) = spikes.(fields{index}); end
end
end

function patch = waveformShape(spikes, session, preferences, showFigures)
%WAVEFORMSHAPE Waveform descriptors from supplied/extracted waveform arrays.
% Raw extraction and spatial localization are separate, currently legacy steps.
patch = struct();
bad = get_bad_channels(session);
good = setdiff(1:session.extracellular.nChannels,bad);
source = {'filtWaveform_std','rawWaveform','rawWaveform_std','rawWaveform_all', ...
    'filtWaveform_all','timeWaveform_all','channels_all','filtWaveform','timeWaveform'};
destination = {'filt_std','raw','raw_std','raw_all','filt_all','time_all','channels_all','filt','time'};
if isfield(spikes,'peakVoltage')
    patch.peakVoltage = spikes.peakVoltage;
else
    patch.peakVoltage = nan(size(spikes.times));
end
if isfield(spikes,'peakVoltage_expFitLengthConstant')
    patch.peakVoltage_expFitLengthConstant = spikes.peakVoltage_expFitLengthConstant(:)';
end
for index = 1:numel(source)
    if isfield(spikes,source{index})
        patch.waveforms.(destination{index}) = spikes.(source{index});
    end
end
if isfield(spikes,'maxWaveform_all')
    for index = 1:numel(spikes.times)
        if numel(spikes.maxWaveform_all)>=index && ~isempty(spikes.maxWaveform_all{index})
            count = min([preferences.waveform.trilat_nChannels,length(spikes.maxWaveform_all{index}), ...
                length(session.extracellular.electrodeGroups.channels{spikes.shankID(index)})]);
            patch.waveforms.bestChannels{index} = spikes.maxWaveform_all{index}(1:count);
        else
            patch.waveforms.bestChannels{index} = [];
        end
    end
end
if isfield(spikes,'filtWaveform_all')
    for index = 1:numel(spikes.times)
        patch.waveforms.peakVoltage_all{index} = nan(1,session.extracellular.nChannels);
        patch.waveforms.peakVoltage_all{index}(good) = range(spikes.filtWaveform_all{index}(good,:),2);
    end
end
values = ce.metrics.calc_waveform_metrics(spikes,session.extracellular.sr,'showFigures',showFigures);
patch.troughToPeak = values.troughtoPeak;
patch.troughtoPeakDerivative = values.derivative_TroughtoPeak;
patch.ab_ratio = values.ab_ratio;
patch.polarity = values.polarity;
end

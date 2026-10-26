function [spikes, result, cache, file] = prepareWaveforms(spikes, session, parameters, preferences, subset)
%PREPAREWAVEFORMS Verify/extract waveforms using an independent, interval-aware cache.
% Returns the cache for persistence only after all requested calculations succeed.
file = fullfile(session.general.basePath,[session.general.name,'.',parameters.saveAs,'.waveformExtraction.cache.mat']);
cache = struct();
if isfile(file) && ~parameters.forceReload
    loaded = load(file,'waveformCache');
    if isfield(loaded,'waveformCache') && isstruct(loaded.waveformCache) && isscalar(loaded.waveformCache)
        cache = loaded.waveformCache;
    end
end
[inputs.recording,stamp] = ce.pipeline.rawRecording(session);
inputs.times = spikes.times;
inputs.UID = spikes.UID;
if isfield(spikes,'cluID'), inputs.cluID = spikes.cluID; end
if isfield(spikes,'ts'), inputs.ts = spikes.ts; end
fields = {'sr','nChannels','nElectrodeGroups','electrodeGroups','spikeGroups','precision','leastSignificantBit'};
for index = 1:numel(fields)
    if isfield(session.extracellular,fields{index})
        inputs.extracellular.(fields{index}) = session.extracellular.(fields{index});
    end
end
if isfield(session,'channelTags'), inputs.channelTags = session.channelTags; end
settings = ce.pipeline.stageSettings(parameters, ...
    struct('nPull',preferences.waveform.nPull,'wfWin_sec',preferences.waveform.wfWin_sec, ...
    'wfWinKeep',preferences.waveform.wfWinKeep),subset);
settings.filtFreq = [500,8000];
if settings.filtFreq(2) > session.extracellular.sr/2
    settings.filtFreq(2) = session.extracellular.sr/2-1;
end
definition = ce.pipeline.stageDefinition('waveform_extraction');
[cache,result] = ce.pipeline.runStage(cache,definition,inputs,settings, ...
    @() ce.pipeline.stages.extractWaveforms(spikes,session,settings,parameters.showWaveforms), ...
    parameters.forceReload || parameters.forceReloadSpikes);
if strcmp(result.status,'failed'), return; end
after = dir(stamp.file);
if isempty(after) || after.bytes ~= stamp.bytes || after.datenum ~= stamp.datenum
    error('ce:pipeline:RawDataChanged','Raw recording changed during waveform preparation; results were not saved.');
end
fields = ce.pipeline.waveformFields;
for index = 1:numel(fields), spikes.(fields{index}) = cache.data.(fields{index}); end
% Preserve importer metadata; only the waveform parameters belong to this stage.
names = fieldnames(cache.waveformParameters);
for index = 1:numel(names)
    spikes.processinginfo.params.(names{index}) = cache.waveformParameters.(names{index});
end
end

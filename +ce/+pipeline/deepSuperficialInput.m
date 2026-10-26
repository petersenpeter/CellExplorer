function record = deepSuperficialInput(session)
%DEEPSUPERFICIALINPUT Read the reviewed channel file without running its producer.
record.file = fullfile(session.general.basePath,[session.general.name,'.deepSuperficialfromRipple.channelinfo.mat']);
record.available = isfile(record.file);
record.sha256 = ''; record.data = struct();
if ~record.available
    ripples = fullfile(session.general.basePath,[session.general.name,'.ripples.events.mat']);
    if isfile(ripples) || isfield(session,'channelTags') && isfield(session.channelTags,'Ripple')
        error('ce:pipeline:DeepSuperficialPreparationRequired', ...
            'Prepare/review %s separately, or exclude deepSuperficial. The pipeline does not detect ripples, create LFP or overwrite channel classifications.',record.file);
    end
    return
end
record.sha256 = ce.pipeline.fileFingerprint(record.file);
loaded = load(record.file,'deepSuperficialfromRipple');
if ~isfield(loaded,'deepSuperficialfromRipple')
    error('ce:pipeline:InvalidDeepSuperficialFile','%s must contain deepSuperficialfromRipple.',record.file);
end
record.data = ce.data.deepSuperficialChannels(loaded.deepSuperficialfromRipple,session);
if ~strcmp(record.sha256,ce.pipeline.fileFingerprint(record.file))
    error('ce:pipeline:DeepSuperficialFileChanged','Classification changed while it was being read.');
end
end

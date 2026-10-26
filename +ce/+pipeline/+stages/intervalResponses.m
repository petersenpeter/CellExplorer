function patch = intervalResponses(inputs, settings, kind, showFigures)
%INTERVALRESPONSES Retain legacy PSTH formulas and event/manipulation preferences.
group = 'events';
if strcmp(kind,'manipulation_metrics'), group = 'manipulations'; end
patch.(group) = struct(); patch.general.(group) = struct();
for record = inputs.records
    if isempty(record.data.timestamps), continue; end
    preferences = settings.preferences.(record.name);
    options = {};
    for name = fieldnames(preferences)'
        options = [options,{name{1},preferences.(name{1})}];
    end
    psth = calc_PSTH(record.data,inputs.spikes,options{:},'eventName',record.name,'plots',showFigures);
    if size(psth.responsecurve,2) ~= numel(inputs.spikes.times)
        error('ce:pipeline:InvalidPsthOutput','PSTH cell count differs from spike identities for %s.',record.name);
    end
    patch.(group).(record.name) = num2cell(psth.responsecurve,1);
    patch.general.(group).(record.name) = struct('event_file',record.file, ...
        'x_bins',psth.time*1000,'x_label','Time (ms)','alignment',psth.alignment);
    for name = {'modulationIndex','modulationRatio','modulationPeakResponseTime','modulationSignificanceLevel'}
        patch.([record.name,'_',name{1}]) = psth.(name{1});
    end
end
end

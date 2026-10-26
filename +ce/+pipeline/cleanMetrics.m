function metrics = cleanMetrics(metrics, parameters)
%CLEANMETRICS Legacy output normalization, separate from calculation and saving.
basename = metrics.general.basename;
% Removing CCGs
field2remove = {'ccg','ccg_time'};
test = isfield(metrics.general,field2remove);
metrics.general = rmfield(metrics.general,field2remove(test));

% Defines unknown brain region if not defined
if ~isfield(metrics,'brainRegion')
    metrics.brainRegion = repmat({'Unknown'},1,metrics.general.cellCount);
end

% Order fields alphabetically
metrics = orderfields(metrics);

if any(contains(parameters.removeMetrics,{'deepSuperficial'}))
    dispLog('Removing deepSuperficial metrics',basename)
    field2remove = {'deepSuperficial','deepSuperficialDistance'};
    test = isfield(metrics,field2remove);
    metrics = rmfield(metrics,field2remove(test));
    metrics.deepSuperficial = repmat({'Unknown'},1,metrics.general.cellCount);
    metrics.deepSuperficialDistance = nan(1,metrics.general.cellCount);
end

if ~isfield(metrics,'deepSuperficial')
    metrics.deepSuperficial = repmat({'Unknown'},1,metrics.general.cellCount);
    metrics.deepSuperficialDistance = nan(1,metrics.general.cellCount);
    % These are generated placeholders, not new manual annotations.
    if isfield(metrics.general,'processinginfo') && ...
            isfield(metrics.general.processinginfo,'deepSuperficialReview') && ...
            isfield(metrics.general.processinginfo,'deepSuperficialProjection') && ...
            ~metrics.general.processinginfo.deepSuperficialProjection.available
        metrics.general.processinginfo.deepSuperficialReview.values.deepSuperficial = metrics.deepSuperficial;
        metrics.general.processinginfo.deepSuperficialReview.values.deepSuperficialDistance = metrics.deepSuperficialDistance;
    end
end

field2remove = {'firingRateMap_StimStates','rawWaveform_zscored','firingRateMap_StimStates','acg2_zscored','acg_zscored','filtWaveform_zscored',...
    'firingRateAcrossTime','thetaPhaseResponse','firingRateMap_CoolingStates','firingRateMap_LeftRight','firingRateMap','firing_rate_map_states',...
    'firing_rate_map','placecell_stability','SpatialCoherence','place_cell','placefield_count','placefield_peak_rate','FiringRateMap',...
    'FiringRateMap_CoolingStates','FiringRateMap_StimStates','FiringRateMap_LeftRight'...
    'sex','species','strain','geneticLine','sessionType','geneticLine','session_name','spikeSortingMethod'};
% cleaning metrics
test2 = isfield(metrics,field2remove);
metrics = rmfield(metrics,field2remove(test2));
% cleaning metrics.general
test = isfield(metrics.general,field2remove);
metrics.general = rmfield(metrics.general,field2remove(test));

% cleaning waveforms
field2remove = {'filt_absolute','filt_zscored', 'raw_absolute','raw_zscored','time_zscored'};
test2 = isfield(metrics.waveforms,field2remove);
metrics.waveforms = rmfield(metrics.waveforms,field2remove(test2));

% cleaning metrics.general.session & metrics.general.animal
field2remove = {'name'};
test2 = isfield(metrics.general.session,field2remove);
metrics.general.session = rmfield(metrics.general.session,field2remove(test2));
field2remove = {'name'};
test2 = isfield(metrics.general.animal,field2remove);
metrics.general.animal = rmfield(metrics.general.animal,field2remove(test2));


end

function paths = intervalOwnership(metrics, kind)
%INTERVALOWNERSHIP Recover only recognized stage outputs from provenance/metadata.
container = struct('event_metrics','events','manipulation_metrics','manipulations','state_metrics','states');
group = container.(kind);
paths = {group,['general.',group]};
names = {};
snapshots = ce.pipeline.outputSnapshot(metrics,{group,['general.',group]});
for snapshot = snapshots
    if snapshot.present && isstruct(snapshot.value) && isscalar(snapshot.value)
        if strcmp(kind,'state_metrics')
            for file = fieldnames(snapshot.value)'
                if isstruct(snapshot.value.(file{1})) && isscalar(snapshot.value.(file{1}))
                    names = [names,fieldnames(snapshot.value.(file{1}))'];
                end
            end
        else
            names = [names,fieldnames(snapshot.value)'];
        end
    end
end
if strcmp(kind,'state_metrics')
    paths = {'general.states'};
    for name = names
        paths = [paths,strcat({'firingRate_','firingRateISI_','cv2_','burstIndex_','firingRates_','firingRatesISI_'},name{1})];
    end
else
    for name = names
        paths = [paths,strcat(name{1},{'_modulationIndex','_modulationRatio','_modulationPeakResponseTime','_modulationSignificanceLevel'})];
    end
end
origin = ce.pipeline.outputSnapshot(metrics,{['general.processinginfo.stages.',kind,'.ownedOutputs']});
if origin.present && iscellstr(origin.value)
    for path = origin.value
        if strcmp(kind,'state_metrics')
            recognized = ~isempty(regexp(path{1},'^(firingRate_|firingRateISI_|cv2_|burstIndex_)[A-Za-z]\w*$','once'));
        else
            recognized = ~isempty(regexp(path{1},'^[A-Za-z]\w*_modulation(Index|Ratio|PeakResponseTime|SignificanceLevel)$','once'));
        end
        if recognized, paths{end+1} = path{1}; end
    end
end
if strcmp(kind,'event_metrics'), paths = [paths,{'rippleCorrelogram','rippleModulationIndex','ripplePeakDelay'}]; end
paths = unique(paths);
end

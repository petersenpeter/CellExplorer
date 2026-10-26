function patch = spatialMetrics(inputs)
%SPATIALMETRICS Project aligned maps using the original spatial formulas.
patch.firingRateMaps = struct();
patch.general.firingRateMaps = struct();
for record = inputs.records
    firingRateMap = record.data;
    patch.firingRateMaps.(record.name) = firingRateMap.map;
    patch.general.firingRateMaps.(record.name) = rmfield(firingRateMap,'map');
    if ~strcmp(record.name,'ratemap'), continue; end
    patch.firingRateMaps.firingRateMap = firingRateMap.map;
    patch.general.firingRateMaps.firingRateMap.x_bins = firingRateMap.x_bins;
    if isfield(firingRateMap,'boundaries')
        patch.general.firingRateMaps.firingRateMap.boundaries = firingRateMap.boundaries;
    end
    for j = 1:numel(firingRateMap.map)
        patch.spatialPeakRate(j) = max(firingRateMap.map{j});
        temp = place_cell_condition(firingRateMap.map{j});
        patch.spatialCoherence(j) = temp.SpatialCoherence;
        patch.placeCell(j) = temp.condition;
        patch.placeFieldsCount(j) = temp.placefield_count;
        temp3 = cumsum(sort(firingRateMap.map{j},'descend'));
        if ~all(temp3==0 | isnan(temp3))
            patch.spatialCoverageIndex(j) = find(temp3>0.75*temp3(end),1)/(length(temp3)*0.75);
            patch.spatialGiniCoeff(j) = ce.metrics.calc_gini(firingRateMap.map{j});
        else
            patch.spatialCoverageIndex(j) = nan;
            patch.spatialGiniCoeff(j) = nan;
        end
    end
end
end

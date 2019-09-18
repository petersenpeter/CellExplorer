figure
colors = {'or','ob'}
metrics = {'ThetaModulationIndex','BurstIndex_Royer2012','ACG_tau_decay','ACG_tau_rise','ACG_c','ACG_d','ACG_fit_rsquare','RippleModulationIndex','RipplePeakDelay','RippleCorrelogram','FiringRate','CV2','BurstIndex_Mizuseki2012','PeakVoltage','TroughToPeak','derivative_TroughtoPeak','AB_ratio','IsolationDistance','LRatio','RefractoryPeriodViolation','DeepSuperficialDistance','ACG_refrac','BurstIndex_Doublets','placefield_count','SpatialCoherence','ACG_tau_burst','ACG_h','BatchIDs','PlaceCellStability'}
for j = 1:length(metrics)
    subplot(6,5,j), hold on
    for i = 1:2
        indx = find(cell_metrics_batch.PlaceCellStability==i & contains(cell_metrics_batch.PutativeCellType,'Pyramidal'));
        plot(cell_metrics_batch.(metrics{j})(indx),cell_metrics_batch.FiringRate(indx),colors{i})
    end
end

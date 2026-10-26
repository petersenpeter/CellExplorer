function patch = acgMetrics(spikes, sr, settings, showFigures, debugMode)
%ACGMETRICS ACG, fit, log ACG/ISI and optional population modulation outputs.
values = calc_ACG_metrics(spikes,sr,'showFigures',debugMode);
patch.acg.wide = values.acg_wide;
patch.acg.narrow = values.acg_narrow;
patch.thetaModulationIndex = values.thetaModulationIndex;
patch.burstIndex_Royer2012 = values.burstIndex_Royer2012;
patch.burstIndex_Doublets = values.burstIndex_Doublets;
fits = fit_ACG(values.acg_narrow,debugMode,settings.useParallel);
names = fieldnames(fits);
for index = 1:numel(names), patch.(names{index}) = fits.(names{index}); end
acg = calc_logACGs(spikes.times,'showFigures',showFigures,'useParallel',settings.useParallel);
patch.acg.log10 = acg.log10;
patch.general.acgs.log10 = acg.log10_bins;
isi = ce.metrics.calc_logISIs(spikes.times,'showFigures',showFigures);
patch.isi.log10 = isi.log10;
patch.general.isis.log10 = isi.log10_bins;
if settings.preferences.population_modIndex
    [meanCCG,bins,modulation] = detectDownStateCells(spikes,sr,'showFigures',showFigures);
    patch.responseCurves.meanCCG = num2cell(meanCCG,1);
    patch.general.responseCurves.meanCCG.x_bins = bins;
    patch.population_modIndex = modulation;
end
end

function patch = coreMetrics(inputs, settings)
%COREMETRICS Original per-cell rate, variability and burst formulas.
spikes = inputs.spikes;
count = numel(spikes.times);
for j = 1:count
    times = spikes.times{j};
    if ~isnumeric(times) || ~isreal(times) || (~isempty(times) && ~iscolumn(times)) || ...
            any(~isfinite(times) | times < 0) || any(diff(times) < 0)
        error('ce:pipeline:InvalidCoreSpikes','Core metrics need sorted finite spike times in seconds.');
    end
end
totals = cellfun(@numel,spikes.times);
if ~isequal(spikes.total,totals)
    error('ce:pipeline:InvalidSpikeTotals','spikes.total must match the number of selected spike times for each cell.');
end
lastTime = max(vertcat(spikes.times{:}));
if isempty(lastTime) || lastTime <= 0
    error('ce:pipeline:InvalidCoreTimeSpan','Core metrics require at least one spike after time zero to define the legacy time bins.');
end
if ~isempty(settings.excludeIntervals) && any(totals == 0)
    error('ce:pipeline:EmptyCoreUnit','The legacy exclusion-duration formula requires a first and last spike for every cell. Choose intervals retaining each cell.');
end
binSize = settings.preferences.firingRateAcrossTime_binsize;
if ~isnumeric(binSize) || ~isreal(binSize) || ~isscalar(binSize) || ~isfinite(binSize) || binSize <= 0
    error('ce:pipeline:InvalidCorePreferences','firingRateAcrossTime_binsize must be a positive finite scalar.');
end
if lastTime/binSize < 40
    binSize = ceil(lastTime/40/10)*10;
end
edges = 0:binSize:max([binSize,lastTime]);
patch.general.responseCurves.firingRateAcrossTime.x_edges = edges;
patch.general.responseCurves.firingRateAcrossTime.x_bins = edges(1:end-1)+binSize/2;
patch.spikeCount = spikes.total;
for j = 1:count
    times = spikes.times{j};
    if ~isempty(settings.excludeIntervals)
        idx = find(any(settings.excludeIntervals' > times(1)) & any(settings.excludeIntervals' < times(end)));
        if isempty(idx)
            spike_window = times(end)-times(1);
        else
            spike_window = (times(end)-times(1))-sum(diff(settings.excludeIntervals(idx,:)'));
        end
        patch.firingRate(j) = spikes.total(j)/spike_window;
    elseif isempty(times)
        patch.firingRate(j) = 0;
    else
        patch.firingRate(j) = spikes.total(j)/(times(end)-times(1));
    end
    temp = histcounts(times,edges)/binSize;
    patch.responseCurves.firingRateAcrossTime{j} = temp(:);
    patch.firingRateGiniCoeff(j) = ce.metrics.calc_gini(temp);
    patch.firingRateCV(j) = std(temp(:))./mean(temp(:));
    patch.firingRateInstability(j) = median(abs(diff(temp(:))))./mean(temp(:));
    tau = diff(times);
    patch.firingRateISI(j) = 1/median(tau);
    CV2_temp = 2*abs(tau(1:end-1)-tau(2:end))./(tau(1:end-1)+tau(2:end));
    patch.cv2(j) = mean(CV2_temp(CV2_temp<1.95));
    bursty = [];
    for jj = 2:length(times)-1
        bursty(jj) = any(diff(times(jj-1:jj+1)) < 0.006);
    end
    patch.burstIndex_Mizuseki2012(j) = length(find(bursty > 0))/length(bursty);
    patch.refractoryPeriodViolation(j) = 1000*length(find(diff(times)<0.002))/spikes.total(j);
end
end

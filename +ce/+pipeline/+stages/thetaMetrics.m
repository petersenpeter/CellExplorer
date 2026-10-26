function patch = thetaMetrics(inputs, settings)
%THETAMETRICS Preserve the legacy phase histogram and speed-gating formulas.
patch = struct();
if ~inputs.available, return; end
theta_bins = settings.preferences.bins;
if ~isnumeric(theta_bins) || ~isreal(theta_bins) || ~isvector(theta_bins) || ...
        numel(theta_bins) < 3 || any(~isfinite(theta_bins(:))) || any(diff(theta_bins(:)) <= 0)
    error('ce:pipeline:InvalidThetaPreferences','Theta bins must be finite, strictly increasing edges.');
end
for key = {'speed_threshold','min_spikes'}
    value = settings.preferences.(key{1});
    if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ~isfinite(value) || ...
            strcmp(key{1},'min_spikes') && value < 0
        error('ce:pipeline:InvalidThetaPreferences','Invalid theta preference %s.',key{1});
    end
end
count = numel(inputs.spikes.times);
patch.thetaPhasePeak = nan(1,count);
patch.thetaPhaseTrough = nan(1,count);
patch.thetaEntrainment = nan(1,count);
for j = 1:count
    keep = inputs.spikes.times{j} < length(inputs.phase)/inputs.srLfp;
    times = inputs.spikes.times{j}(keep);
    samples = inputs.spikes.ts{j}(keep);
    ts_eeg = ceil(samples*inputs.srLfp/inputs.sr);
    theta_phase = inputs.phase(ts_eeg);
    speed = interp1(inputs.behavior.time,inputs.behavior.speed,times);
    % The eligibility gate of 10 differs from the configurable histogram gate.
    % Keep this legacy convention for a separate scientific review.
    if sum(speed > 10) > settings.preferences.min_spikes
        [counts,centers] = histcounts(theta_phase(speed > settings.preferences.speed_threshold),theta_bins,'Normalization','probability');
        counts = nanconv(counts,[1,1,1,1,1]/5,'edge');
        [~,tem2] = max(counts); [~,tem3] = min(counts);
        patch.responseCurves.thetaPhase{j} = counts(:);
        patch.thetaPhasePeak(j) = centers(tem2)+diff(centers([1,2]))/2;
        patch.thetaPhaseTrough(j) = centers(tem3)+diff(centers([1,2]))/2;
        patch.thetaEntrainment(j) = max(counts)/min(counts);
    else
        patch.responseCurves.thetaPhase{j} = nan(length(theta_bins)-1,1);
    end
end
patch.general.responseCurves.thetaPhase.x_bins = theta_bins(1:end-1)+diff(theta_bins([1,2]))/2;
end

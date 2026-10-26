function [metrics,thetaBins] = prepareDisplayData(metrics, logIntervals)
%PREPAREDISPLAYDATA Prepare viewer arrays without figures, I/O or UI state.
% Preserve legacy interpolation, zero/NaN handling and range normalization.
% This retains the legacy initialized flag, not a scientific cache-freshness test.
count = ce.data.metricCellCount(metrics,true);
times = metrics.waveforms.time;
if ~iscell(times) || numel(times) ~= count
    error('ce:ui:InvalidWaveformTime','Waveform time axes must describe every cell.');
end
for index = 1:count
    axis = times{index};
    if ~isnumeric(axis) || ~isreal(axis) || ~isvector(axis) || numel(axis)<2 || ...
            any(~isfinite(axis(:))) || any(diff(axis(:))<=0)
        error('ce:ui:InvalidWaveformTime','Cell %d needs a finite increasing waveform time axis with at least two samples.',index);
    end
end
steps = cellfun(@diff,times,'UniformOutput',false);
% The legacy grid is an intersection of extents at the smallest sample step.
step = min(cellfun(@min,steps));
grid = max(cellfun(@min,times)):step:min(cellfun(@max,times));
metrics.waveforms.time_zscored = grid;
thetaBins = (-1:.05:1)*pi;
thetaBins = thetaBins(1:end-1)+diff(thetaBins([1 2]))/2;
initialized = isfield(metrics.general,'initialized') && metrics.general.initialized;
if initialized && all(isfield(metrics.waveforms,{'filt_zscored','filt_absolute'}))
    return
end
filtered = resampleWaveforms(times,metrics.waveforms.filt,grid,count);
metrics.waveforms.filt_absolute = filtered;
metrics.waveforms.filt_zscored = (filtered-mean(filtered,'omitnan'))./std(filtered,'omitnan');
if isfield(metrics.waveforms,'raw')
    raw = resampleWaveforms(times,metrics.waveforms.raw,grid,count);
    metrics.waveforms.raw_absolute = raw;
    metrics.waveforms.raw_zscored = (raw-mean(raw,'omitnan'))./std(raw,'omitnan');
end
metrics.acg.wide_normalized = normalizeRange(metrics.acg.wide);
metrics.acg.narrow_normalized = normalizeRange(metrics.acg.narrow);
if isfield(metrics.acg,'log10')
    metrics.acg.log10_rate = normalizeRange(metrics.acg.log10);
    metrics.acg.log10_occurrence = normalizeRange(metrics.acg.log10.*diff(10.^logIntervals)');
end
if isfield(metrics,'isi') && isfield(metrics.isi,'log10')
    metrics.isi.log10_rate = normalizeRange(metrics.isi.log10);
    metrics.isi.log10_occurrence = normalizeRange(metrics.isi.log10.*diff(10.^logIntervals)');
end
if isfield(metrics,'responseCurves') && isfield(metrics.responseCurves,'thetaPhase')
    curves = nan(numel(thetaBins),count);
    for index = 1:numel(metrics.responseCurves.thetaPhase)
        if isempty(metrics.responseCurves.thetaPhase{index})
            metrics.responseCurves.thetaPhase{index} = nan(size(thetaBins'));
        end
        values = metrics.responseCurves.thetaPhase{index};
        if isempty(values) || any(isnan(values))
            curves(:,index) = nan(size(thetaBins));
        elseif isfield(metrics.general,'batch')
            axis = metrics.general.batch{metrics.batchIDs(index)}.responseCurves.thetaPhase.x_bins;
            curves(:,index) = interp1(axis,values',thetaBins,'spline',nan);
        elseif isfield(metrics.general,'responseCurves')
            axis = metrics.general.responseCurves.thetaPhase.x_bins;
            curves(:,index) = interp1(axis,values,thetaBins,'spline',nan);
        else
            curves(:,index) = values;
        end
    end
    metrics.responseCurves.thetaPhase_zscored = curves;
end
end

function output = resampleWaveforms(times,values,grid,count)
if ~iscell(values) || numel(values) ~= count
    error('ce:ui:InvalidDisplayWaveform','Waveforms must describe every cell.');
end
output = zeros(numel(grid),count);
valid = false(1,count);
for index = 1:count
    value = values{index};
    if isempty(value), continue; end
    if ~isnumeric(value) || ~isreal(value) || ~isvector(value) || numel(value) ~= numel(times{index})
        error('ce:ui:InvalidDisplayWaveform','Cell %d waveform must match its time axis.',index);
    end
    valid(index) = ~any(isnan(value));
end
% Preserve per-cell calls: matrix-valued spline evaluation can change rounding.
% Preallocation avoids repeated array growth while retaining exact results.
for index = find(valid)
    output(:,index) = interp1(times{index},values{index},grid,'spline',nan);
end
end

function value = normalizeRange(value)
% Deliberately retain division by range, with no minimum subtraction.
value = value./range(value);
end

function waveform_metrics = calc_waveform_metrics(spikes,sr_in,varargin)
    % Extracts waveform metrics
    %
    % INPUT:
    % spikes structure
    %   .filtWaveform : Waveforms (in µV; cell-array [1x nCells])
    % 	.timeWaveform : Time axis (in ms; cell-array [1x nCells])
    %
    % OUTPUT:
    % waveform_metrics
    % Metrics for the waveforms: peaktoTrough, troughtoPeak,
    % derivative_TroughtoPeak, peakA, peakB, ab_ratio, trough
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    
% Compatibility entry point; implementation: ce.metrics.calc_waveform_metrics.
waveform_metrics = ce.metrics.calc_waveform_metrics(spikes, sr_in, varargin{:});
end

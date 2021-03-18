function preferences = p1_preferences(preferences,session)
% This is an example file for generating your own preferences for ProcessCellMetrics part of CellExplorer
% Please follow the structure of preferences_ProcessCellMetrics.m

% e.g.:
% preferences.waveform.nPull = 600;            % number of spikes to pull out (default: 600)
preferences.waveform.wfWin_sec = 0.008;      % Larger size of waveform windows for filterning. total width in s
preferences.waveform.wfWinKeep = 0.001;     % half width in s
% preferences.waveform.showWaveforms = true;
disp('User preferences loaded successfully')

end

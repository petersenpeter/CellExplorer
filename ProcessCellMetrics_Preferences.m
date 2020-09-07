% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% ProcessCellMetrics preferences 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
% Preferences loaded by ProcessCellMetrics
% Check the website of CellExplorer for more details: https://cellexplorer.org/

% By Peter Petersen
% Last edited: 07-09-2020

% general
preferences.general.probesVerticalSpacing = 10;
preferences.general.probesLayout = 'poly2';
    
% Waveform
preferences.waveform.nPull = 600;            % number of spikes to pull out (default: 600)
preferences.waveform.wfWin_sec = 0.004;      % Larger size of waveform windows for filterning. total width in ms
preferences.waveform.wfWinKeep = 0.0008;     % half width in ms
preferences.waveform.filtFreq = [500,8000];  % Band pass filter
preferences.waveform.showWaveforms = true;

% PCA
% acg

% deepSuperficial 
preferences.deepSuperficial.ripples_durations = [50 150];
preferences.deepSuperficial.ripples_passband = [120 180];

% monoSynaptic_connections

% theta
preferences.theta.theta_bins =[-1:0.05:1]*pi;
preferences.theta.speed_threshold = 10; % behavioral running speed (cm/s)
preferences.theta.min_spikes = 500;     % only calculated if the unit has above 500 spikes

% spatial

% event

% psth
preferences.psth.binCount = 100;        % how many bins (for half the window)
preferences.psth.alignment = 'onset';   % alignment of time ['onset','center','peaks','offset']
preferences.psth.binDistribution = [0.25,0.5,0.25];  % How the bins should be distributed around the events, pre, during, post. Must sum to 1
preferences.psth.duration = 0;          % duration of PSTH (for half the window - used in CCG) [in seconds]
preferences.psth.smoothing = 5;         % any gaussian smoothing to apply? units of bins.
preferences.psth.percentile = 99;       % if events does not have the same length, the event duration can be determined from percentile of the distribution of events

% manipulation
preferences.manipulation.binCount = 100;        % how many bins (for half the window)
preferences.manipulation.alignment = 'onset';   % alignment of time ['onset','center','peaks','offset']
preferences.manipulation.binDistribution = [0.25,0.5,0.25];  % How the bins should be distributed around the events, pre, during, post. Must sum to 1
preferences.manipulation.duration = 0;          % duration of PSTH (for half the window - used in CCG) [in seconds]
preferences.manipulation.smoothing = 0;         % any gaussian smoothing to apply? units of bins.
preferences.manipulation.percentile = 99;       % if events does not have the same length, the event duration can be determined from percentile of the distribution of events

% other
preferences.other.firingRateAcrossTime_binsize = 3*60;  % 180 seconds default bin_size

% putativeCellType 
% Cells are reassigned as interneurons by below criteria
preferences.putativeCellType.acg_tau_decay_bondary = 30;    % acg_tau_decay > 30ms
preferences.putativeCellType.acg_tau_rise_boundary = 3;     % acg_tau_rise > 3ms
preferences.putativeCellType.troughToPeak_boundary = 0.425; % Narrow interneuron assigned if troughToPeak <= 0.425ms, otherwise wide interneuron

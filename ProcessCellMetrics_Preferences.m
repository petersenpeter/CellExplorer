function preferences = ProcessCellMetrics_Preferences(session)
% Preferences loaded by ProcessCellMetrics
%
% Check the website of CellExplorer for more details: https://cellexplorer.org/

% By Peter Petersen
% Last edited: 09-09-2020

% General
preferences.general.probesVerticalSpacing = 10; % 10um spacing between channels
preferences.general.probesLayout = 'poly2';     % Default probe layout
    
% Waveform
preferences.waveform.nPull = 600;               % number of spikes to pull out (default: 600)
preferences.waveform.wfWin_sec = 0.004;         % Larger size of waveform windows for filterning. total width in ms
preferences.waveform.wfWinKeep = 0.0008;        % half width in ms
preferences.waveform.showWaveforms = true;

% PCA

% ACG

% Deep superficial 
preferences.deepSuperficial.ripples_durations = [50 150]; % in ms
preferences.deepSuperficial.ripples_passband = [120 180]; % in Hz

% monoSynaptic_connections

% Theta
preferences.theta.bins = [-1:0.05:1]*pi; % theta bins from -pi to pi
preferences.theta.speed_threshold = 10;  % behavioral running speed (cm/s)
preferences.theta.min_spikes = 500;      % only calculated if the unit has above 500 spikes

% Spatial

% Event

% PSTH
preferences.psth.binCount = 100;                % how many bins (for half the window)
preferences.psth.alignment = 'onset';           % alignment of time ['onset','center','peaks','offset']
preferences.psth.binDistribution = [0.25,0.5,0.25];  % How the bins should be distributed around the events, pre, during, post. Must sum to 1
preferences.psth.duration = 0;                  % duration of PSTH (for half the window - used in CCG) [in seconds]
preferences.psth.smoothing = 5;                 % any gaussian smoothing to apply? units of bins.
preferences.psth.percentile = 99;               % if events does not have the same length, the event duration can be determined from percentile of the distribution of events

% Manipulation
preferences.manipulation.binCount = 100;        % how many bins (for half the window)
preferences.manipulation.alignment = 'onset';   % alignment of time ['onset','center','peaks','offset']
preferences.manipulation.binDistribution = [0.25,0.5,0.25];  % How the bins should be distributed around the events, pre, during, post. Must sum to 1
preferences.manipulation.duration = 0;          % duration of PSTH (for half the window - used in CCG) [in seconds]
preferences.manipulation.smoothing = 5;         % any gaussian smoothing to apply? units of bins.
preferences.manipulation.percentile = 99;       % if events does not have the same length, the event duration can be determined from percentile of the distribution of events

% Other
preferences.other.firingRateAcrossTime_binsize = 3*60;      % 180 seconds default bin_size

% PutativeCellType
% Cells are reassigned as interneurons by below criteria
preferences.putativeCellType.acg_tau_decay_bondary = 30;    % acg_tau_decay > 30ms
preferences.putativeCellType.acg_tau_rise_boundary = 3;     % acg_tau_rise > 3ms
preferences.putativeCellType.troughToPeak_boundary = 0.425; % Narrow interneuron assigned if troughToPeak <= 0.425ms, otherwise wide interneuron

% % % % % % % % % % % % % % % % % % % %
% User preferences 
% % % % % % % % % % % % % % % % % % % % 
% You may edit above preferences or provide your own preferences in a separate file.
% Provide the path to your preferences as an analysis tag in the session struct: 
% session.analysisTags.ProcessCellMetrics_preferences = 'user_preferences.user_preferences'; % loads the user_preference.m file from the folder +user_preferences

if exist('session','var') && isfield(session,'analysisTags') && isfield(session.analysisTags,'ProcessCellMetrics_preferences') && exist(session.analysisTags.ProcessCellMetrics_preferences,'file')
    preferences = feval(session.analysisTags.ProcessCellMetrics_preferences,preferences,session);
end

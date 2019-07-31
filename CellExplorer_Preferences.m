% Preferences loaded by the Cell Explorer at startup
% https://github.com/petersenpeter/Cell-Explorer

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 07-06-2019

% % % % % % % % % % % % % % % % % % % % % %
% Cell Explorer Preferences  
% % % % % % % % % % % % % % % % % % % % % %

% Display settings - An incomplete list:
% 'Single waveform','All waveforms','All waveforms (image)','Single raw waveform','All raw waveforms','Single ACG',
% 'All ACGs','All ACGs (image)','CCGs (image)','Sharp wave-ripple'
UI.settings.customCellPlotIn1 = 'All waveforms';
UI.settings.customCellPlotIn2 = 'Single ACG'; 
UI.settings.customCellPlotIn3 = 'responseCurves_firingRateAcrossTime';
UI.settings.customCellPlotIn4 = 'All waveforms';
UI.settings.customCellPlotIn5 = 'CCGs (image)';
UI.settings.customCellPlotIn6 = 'firingRateMap';

UI.settings.acgType = 'Normal';                 % Normal (100ms), Wide (1s), Narrow (30ms)
UI.settings.monoSynDispIn = 'Selected';         % 'All', 'Upstream', 'Downstream', 'Up & downstream', 'Selected', 'None'
UI.settings.metricsTableType = 'Metrics';         % ['Metrics','Cells','None']
UI.settings.plotCountIn = 'GUI 3+3';            % ['GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6']
UI.settings.dispLegend = 0;                     % [0,1] Display legend for scatter plots?
UI.settings.plotWaveformMetrics = 0;            % show waveform metrics on the single waveform

% Autosave settings
UI.settings.autoSaveFrequency = 6;              % How often you want to autosave (classifications steps). Put to 0 to turn autosave off
UI.settings.autoSaveVarName = 'cell_metrics';   % Variable name used in autosave

% Initial data displayed in the customPlot
UI.settings.plotXdata = 'firingRate';
UI.settings.plotYdata = 'peakVoltage';
UI.settings.plotZdata = 'troughToPeak';

% Cell type classification definitions
UI.settings.cellTypes = {'Unknown','Pyramidal Cell','Narrow Interneuron','Wide Interneuron'};
UI.settings.deepSuperficial = {'Unknown','Cortical','Deep','Superficial'};
UI.settings.tags = {'Good','Bad','Mua','Noise','InverseSpike','Other'};
UI.settings.groundTruth = {'PV+','NOS1+','GAT1+','SST+','Axoaxonic','5HT3a'}; 
UI.settings.groundTruthMarkers = {'om','dg','sm','*k','+k','+p'}; % Supports any Matlab marker symbols: https://www.mathworks.com/help/matlab/creating_plots/create-line-plot-with-markers.html

% Cell type classification colors
UI.settings.cellTypeColors = [[.5,.5,.5];[.8,.2,.2];[.2,.2,.8];[0.2,0.8,0.8];[0.8,0.2,0.8];[.2,.8,.2]];

% Fields used to define the tSNE represetation
UI.settings.tSNE_calcWideAcg = false;           % boolean
UI.settings.tSNE_calcNarrowAcg = false;         % boolean
UI.settings.tSNE_calcFiltWaveform = false;      % boolean
UI.settings.tSNE_calcRawWaveform = false;       % boolean

% List of fields to use in the general tSNE representation
UI.settings.tSNE_metrics = {'firingRate','thetaModulationIndex','burstIndex_Mizuseki2012','troughToPeak','ab_ratio','burstIndex_Royer2012','acg_tau_rise','acg_tau_burst','acg_h','acg_tau_decay','cv2','burstIndex_Doublets','troughtoPeakDerivative'};
UI.settings.tSNE_dDistanceMetric = 'seuclidean'; % default: 'euclidean'

% Highlight excitatory / inhibitory cells
UI.settings.displayInhibitory = false;          % boolean
UI.settings.displayExcitatory = false;          % boolean

% Firing rate map setting
UI.settings.firingRateMap.showHeatmap = false;          % boolean
UI.settings.firingRateMap.showLegend = false;           % boolean
UI.settings.firingRateMap.showHeatmapColorbar = false;  % boolean

% % % % % % % % % % % % % % % % % % % % % %
% Spikes plot definitions
%
% Can be loaded by pressing S in the Cell Explorer
% % % % % % % % % % % % % % % % % % % % % %

plotName = 'spikes_pos_vs_phase';
spikesPlots.(plotName).x = 'pos_linearized';
spikesPlots.(plotName).y = 'theta_phase';
spikesPlots.(plotName).x_label = 'Position (cm)';
spikesPlots.(plotName).y_label = 'Theta phase';
spikesPlots.(plotName).state = '';
spikesPlots.(plotName).filter = 'speed';
spikesPlots.(plotName).filterType = 'greater than';     % [none, equal to, less than, greater than]
spikesPlots.(plotName).filterValue = 20;
spikesPlots.(plotName).event = '';
spikesPlots.(plotName).eventAlignment = 'peak';         % [onset, offset, center, peak]
spikesPlots.(plotName).eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikesPlots.(plotName).eventSecBefore = 0.2;            % in seconds
spikesPlots.(plotName).eventSecAfter = 0.2;             % in seconds
spikesPlots.(plotName).plotRaster = 0; 
spikesPlots.(plotName).plotAverage = 0;
spikesPlots.(plotName).plotAmplitude = 0;
spikesPlots.(plotName).plotDuration = 0;
spikesPlots.(plotName).plotCount = 0;

plotName = 'spikes_pos_vs_trials';
spikesPlots.(plotName).x = 'pos_linearized';
spikesPlots.(plotName).y = 'trials';
spikesPlots.(plotName).x_label = 'Position (cm)';
spikesPlots.(plotName).y_label = 'Trials';
spikesPlots.(plotName).state = '';
spikesPlots.(plotName).filter = '';
spikesPlots.(plotName).filterType = '';                 % [none, equal to, less than, greater than]
spikesPlots.(plotName).filterValue = 0;
spikesPlots.(plotName).event = '';
spikesPlots.(plotName).eventAlignment = 'peak';         % [onset, offset, center, peak]
spikesPlots.(plotName).eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikesPlots.(plotName).eventSecBefore = 0.2;            % in seconds
spikesPlots.(plotName).eventSecAfter = 0.2;             % in seconds
spikesPlots.(plotName).plotRaster = 0; 
spikesPlots.(plotName).plotAverage = 0;
spikesPlots.(plotName).plotAmplitude = 0;
spikesPlots.(plotName).plotDuration = 0;
spikesPlots.(plotName).plotCount = 0;

plotName = 'spikes_pos_vs_trials_cooling';
spikesPlots.(plotName).x = 'pos_linearized';
spikesPlots.(plotName).y = 'trials';
spikesPlots.(plotName).x_label = 'Position (cm)';
spikesPlots.(plotName).y_label = 'Trials';
spikesPlots.(plotName).state = 'state';
spikesPlots.(plotName).filter = '';
spikesPlots.(plotName).filterType = '';                 % [none, equal to, less than, greater than]
spikesPlots.(plotName).filterValue = 0;
spikesPlots.(plotName).event = '';
spikesPlots.(plotName).eventAlignment = 'peak';         % [onset, offset, center, peak]
spikesPlots.(plotName).eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikesPlots.(plotName).eventSecBefore = 0.2;            % in seconds
spikesPlots.(plotName).eventSecAfter = 0.2;             % in seconds
spikesPlots.(plotName).plotRaster = 0; 
spikesPlots.(plotName).plotAverage = 0;
spikesPlots.(plotName).plotAmplitude = 0;
spikesPlots.(plotName).plotDuration = 0;
spikesPlots.(plotName).plotCount = 0;

plotName = 'spikes_time_vs_amplitude';
spikesPlots.(plotName).x = 'times';
spikesPlots.(plotName).y = 'amplitudes';
spikesPlots.(plotName).x_label = 'Time (s)';
spikesPlots.(plotName).y_label = 'Amplitude';
spikesPlots.(plotName).state = '';
spikesPlots.(plotName).filter = '';
spikesPlots.(plotName).filterType = '';                 % [none, equal to, less than, greater than]
spikesPlots.(plotName).filterValue = 0;
spikesPlots.(plotName).event = '';
spikesPlots.(plotName).eventAlignment = 'peak';         % [onset, offset, center, peak]
spikesPlots.(plotName).eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikesPlots.(plotName).eventSecBefore = 0.2;            % in seconds
spikesPlots.(plotName).eventSecAfter = 0.2;             % in seconds
spikesPlots.(plotName).plotRaster = 0; 
spikesPlots.(plotName).plotAverage = 0;
spikesPlots.(plotName).plotAmplitude = 0;
spikesPlots.(plotName).plotDuration = 0;
spikesPlots.(plotName).plotCount = 0;

plotName = 'spikes_ripples_raster';
spikesPlots.(plotName).x = 'times';
spikesPlots.(plotName).y = 'amplitudes';
spikesPlots.(plotName).x_label = 'Time';
spikesPlots.(plotName).y_label = 'Event';
spikesPlots.(plotName).state = '';
spikesPlots.(plotName).filter = '';
spikesPlots.(plotName).filterType = '';                 % [none, equal to, less than, greater than]
spikesPlots.(plotName).filterValue = 0;
spikesPlots.(plotName).event = 'ripples';
spikesPlots.(plotName).eventAlignment = 'peak';         % [onset, offset, center, peak]
spikesPlots.(plotName).eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikesPlots.(plotName).eventSecBefore = 0.2;            % in seconds
spikesPlots.(plotName).eventSecAfter = 0.2;             % in seconds
spikesPlots.(plotName).plotRaster = 1; 
spikesPlots.(plotName).plotAverage = 1;
spikesPlots.(plotName).plotAmplitude = 1;
spikesPlots.(plotName).plotDuration = 1;
spikesPlots.(plotName).plotCount = 0;

plotName = 'spikes_optoStim';
spikesPlots.(plotName).x = 'times';
spikesPlots.(plotName).y = 'times';
spikesPlots.(plotName).x_label = 'Time';
spikesPlots.(plotName).y_label = 'Event';
spikesPlots.(plotName).state = '';
spikesPlots.(plotName).filter = '';
spikesPlots.(plotName).filterType = '';                 % [none, equal to, less than, greater than]
spikesPlots.(plotName).filterValue = 0;
spikesPlots.(plotName).event = 'optoStim';
spikesPlots.(plotName).eventAlignment = 'onset';        % [onset, offset, center, peak]
spikesPlots.(plotName).eventSorting = 'time';           % [none, time, amplitude, duration]
spikesPlots.(plotName).eventSecBefore = 0.1;            % in seconds
spikesPlots.(plotName).eventSecAfter = 0.2;             % in seconds
spikesPlots.(plotName).plotRaster = 1;
spikesPlots.(plotName).plotAverage = 1;
spikesPlots.(plotName).plotAmplitude = 0;
spikesPlots.(plotName).plotDuration = 0;
spikesPlots.(plotName).plotCount = 0;

plotName = 'spikes_tesStimulation';
spikesPlots.(plotName).x = 'times';
spikesPlots.(plotName).y = 'times';
spikesPlots.(plotName).x_label = 'Time';
spikesPlots.(plotName).y_label = 'Event';
spikesPlots.(plotName).state = '';
spikesPlots.(plotName).filter = '';
spikesPlots.(plotName).filterType = '';                 % [none, equal to, less than, greater than]
spikesPlots.(plotName).filterValue = 0;
spikesPlots.(plotName).event = 'stimulation';
spikesPlots.(plotName).eventAlignment = 'onset';        % [onset, offset, center, peak]
spikesPlots.(plotName).eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikesPlots.(plotName).eventSecBefore = 2;              % in seconds
spikesPlots.(plotName).eventSecAfter = 2;               % in seconds
spikesPlots.(plotName).plotRaster = 1;
spikesPlots.(plotName).plotAverage = 1;
spikesPlots.(plotName).plotAmplitude = 1;
spikesPlots.(plotName).plotDuration = 0;
spikesPlots.(plotName).plotCount = 0;

plotName = 'spikes_pulses';
spikesPlots.(plotName).x = 'times';
spikesPlots.(plotName).y = 'times';
spikesPlots.(plotName).x_label = 'Time';
spikesPlots.(plotName).y_label = 'Event';
spikesPlots.(plotName).state = '';
spikesPlots.(plotName).filter = '';
spikesPlots.(plotName).filterType = '';                 % [none, equal to, less than, greater than]
spikesPlots.(plotName).filterValue = 0;
spikesPlots.(plotName).event = 'pulses';
spikesPlots.(plotName).eventAlignment = 'onset';        % [onset, offset, center, peak]
spikesPlots.(plotName).eventSorting = 'none';           % [none, time, amplitude, duration]
spikesPlots.(plotName).eventSecBefore = 0.2;            % in seconds
spikesPlots.(plotName).eventSecAfter = 0.1;             % in seconds
spikesPlots.(plotName).plotRaster = 1;
spikesPlots.(plotName).plotAverage = 1;
spikesPlots.(plotName).plotAmplitude = 1;
spikesPlots.(plotName).plotDuration = 0;
spikesPlots.(plotName).plotCount = 0;

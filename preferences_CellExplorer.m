% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% CellExplorer Preferences  
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
% Preferences loaded by the CellExplorer at startup
% Check the website of the CellExplorer for more details: https://cellexplorer.org/
  
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 24-04-2020

% Display preferences - An incomplete list:
% 'Waveforms (single)','Waveforms (all)','Waveforms (image)','Raw waveforms (single)','Raw waveforms (all)','ACGs (single)',
% 'ACGs (all)','ACGs (image)','CCGs (image)','sharpWaveRipple'
UI.preferences.customCellPlotIn{1} = 'Waveforms (single)';
UI.preferences.customCellPlotIn{2} = 'ACGs (single)'; 
UI.preferences.customCellPlotIn{3} = 'RCs_firingRateAcrossTime';
UI.preferences.customCellPlotIn{4} = 'Waveforms (single)';
UI.preferences.customCellPlotIn{5} = 'CCGs (image)';
UI.preferences.customCellPlotIn{6} = 'sharpWaveRipple';

UI.preferences.acgType = 'Normal';                 % Normal (100ms), Wide (1s), Narrow (30ms), Log10
UI.preferences.isiNormalization = 'Occurrence';     % 'Rate', 'Occurrence'
UI.preferences.rainCloudNormalization = 'Peak';    % 'Probability'
UI.preferences.monoSynDispIn = 'Selected';         % 'All', 'Upstream', 'Downstream', 'Up & downstream', 'Selected', 'None'
UI.preferences.metricsTableType = 'Metrics';       % ['Metrics','Cells','None']
UI.preferences.plotCountIn = 'GUI 3+3';            % ['GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6']
UI.preferences.dispLegend = 0;                     % [0,1] Display legends in plots?
UI.preferences.plotWaveformMetrics = 0;            % show waveform metrics on the single waveform
UI.preferences.sortingMetric = 'burstIndex_Royer2012'; % metrics used for sorting image data
UI.preferences.markerSize = 15;                    % marker size in the group plots [default: 20]
UI.preferences.plotInsetChannelMap = 3;            % Show a channel map inset with waveforms.
UI.preferences.plotInsetACG = 0;                   % Show a ACG plot inset with waveforms.
UI.preferences.plotChannelMapAllChannels = true;   % Boolean. Show a select set of channels or all 
UI.preferences.waveformsAcrossChannelsAlignment = 'Probe layout'; % 'Probe layout', 'Electrode groups'
UI.preferences.colormap = 'hot';                   % colormap of image plots
UI.preferences.showAllWaveforms = 0;               % Show all traces or a random subset (maxi 2000; faster UI)
UI.preferences.zscoreWaveforms = 1;                % Show zscored or full amplitude waveforms
UI.preferences.trilatGroupData = 'session';        % 'session','animal','all'
UI.preferences.hoverEffect = 1;                    % Highlights cells by hovering the mouse
UI.preferences.plotLinearFits = 0;                 % Linear fit shown in group plot for each cell group

% Autosave preferences
UI.preferences.autoSaveFrequency = 5;              % How often you want to autosave (classifications steps). Put to 0 to turn autosave off
UI.preferences.autoSaveVarName = 'cell_metrics';   % Variable name used in autosave

% Initial data displayed in the customPlot
UI.preferences.plotXdata = 'firingRate';
UI.preferences.plotYdata = 'peakVoltage';
UI.preferences.plotZdata = 'troughToPeak';
UI.preferences.plotMarkerSizedata = 'peakVoltage';

% Cell type classification definitions
UI.preferences.cellTypes = {'Unknown','Pyramidal Cell','Narrow Interneuron','Wide Interneuron'};
UI.preferences.deepSuperficial = {'Unknown','Cortical','Deep','Superficial'};
UI.preferences.tags = {'Good','Bad','Noise','InverseSpike'};
UI.preferences.groundTruth = {'PV','NOS1','GAT1','SST','Axoaxonic','CellType_A'};
UI.preferences.groupDataMarkers = ce_append(["o","d","s","*","+"],["m","k","g"]'); 

UI.preferences.groundTruthMarkers = {'om','d','sm','*k','+k','+m','om','dm','sg','*m'}; % Supports any Matlab marker symbols: https://www.mathworks.com/help/matlab/creating_plots/create-line-plot-with-markers.html
UI.preferences.groundTruthColors = [[.9,.2,.2];[.2,.2,.9];[0.2,0.9,0.9];[0.9,0.2,0.9];[.2,.9,.2];[.5,.5,.5];[.8,.2,.2];[.2,.2,.8];[0.2,0.8,0.8];[0.8,0.2,0.8]];
UI.preferences.cellTypeColors = [[.5,.5,.5];[.8,.2,.2];[.2,.2,.8];[0.2,0.8,0.8];[0.8,0.2,0.8];[.2,.8,.2]];

% tSNE representation
UI.preferences.tSNE.metrics = {'firingRate','thetaModulationIndex','burstIndex_Mizuseki2012','troughToPeak','ab_ratio','burstIndex_Royer2012','acg_tau_rise','acg_tau_burst','acg_h','acg_tau_decay','cv2','burstIndex_Doublets','troughtoPeakDerivative'};
UI.preferences.tSNE.dDistanceMetric = 'chebychev'; % default: 'euclidean'
UI.preferences.tSNE.exaggeration = 10;             % default: 15
UI.preferences.tSNE.standardize = true;           % boolean
UI.preferences.tSNE.NumPCAComponents = 0;
UI.preferences.tSNE.LearnRate = 1000;
UI.preferences.tSNE.Perplexity = 30;
UI.preferences.tSNE.InitialY = 'Random';

UI.preferences.tSNE.calcWideAcg = false;           % boolean
UI.preferences.tSNE.calcNarrowAcg = false;         % boolean
UI.preferences.tSNE.calcLogAcg = false;            % boolean
UI.preferences.tSNE.calcLogIsi = false;            % boolean
UI.preferences.tSNE.calcFiltWaveform = false;      % boolean
UI.preferences.tSNE.calcRawWaveform = false;       % boolean

% Highlight excitatory / inhibitory cells
UI.preferences.displayInhibitory = false;          % boolean
UI.preferences.displayExcitatory = false;          % boolean
UI.preferences.displayExcitatoryPostsynapticCells = false; % boolean
UI.preferences.displayInhibitoryPostsynapticCells = false; % boolean

% Firing rate map setting
UI.preferences.firingRateMap.showHeatmap = false;          % boolean
UI.preferences.firingRateMap.showLegend = false;           % boolean
UI.preferences.firingRateMap.showHeatmapColorbar = false;  % boolean

% Supplementary figure
UI.supplementaryFigure.waveformNormalization = 1;
UI.supplementaryFigure.groupDataNormalization = 1;
UI.supplementaryFigure.metrics = {'troughToPeak'  'acg_tau_rise'  'firingRate'  'cv2'  'peakVoltage'  'isolationDistance'  'lRatio'  'refractoryPeriodViolation'};
UI.supplementaryFigure.axisScale = [1 2 2 2 2 2 2 2];
UI.supplementaryFigure.smoothing = [1 1 1 1 1 1 1 1];

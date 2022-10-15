function UI = preferences_CellExplorer(UI)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% CellExplorer Preferences  
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
% Preferences loaded by the CellExplorer at startup
% Visit the website of the CellExplorer for more details: https://CellExplorer.org/
  
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 25-06-2021

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Preferences saved between sessions
% Saved to last_preferences_CellExplorer.m
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %   

UI.preferences.metricsTable = 1;                   % 1: Metrics, 2: Cells, 3: None
UI.preferences.layout = 3;                         % 1:'GUI 1+3',2:'GUI 2+3',3:'GUI 3+3',4:'GUI 3+4',5:'GUI 3+5',6:'GUI 3+6',7:'GUI 1+6'
UI.preferences.customPlotHistograms = 1;           % 1: 2D scatter plot, 2: 2D+histograms, 3: 3D plot, 4: raincloud plot

% Custom plot (incomplete list): 'Waveforms (single)','Waveforms (all)','Waveforms (image)','Raw waveforms (single)','Raw waveforms (all)','ACGs (single)', 'ACGs (all)','ACGs (image)','CCGs (image)','sharpWaveRipple'
UI.preferences.customPlot{1} = 'Waveforms (single)';
UI.preferences.customPlot{2} = 'ACGs (single)'; 
UI.preferences.customPlot{3} = 'RCs_firingRateAcrossTime';
UI.preferences.customPlot{4} = 'Waveforms (all)';
UI.preferences.customPlot{5} = 'ACGs (all)';
UI.preferences.customPlot{6} = 'Connectivity graph';

UI.preferences.acgType = '100 ms';                 % '30 mms', '100 ms', '1 sec', 'Log10'
UI.preferences.isiNormalization = 'Occurrence';     % 'Rate', 'Occurrence'
UI.preferences.rainCloudNormalization = 'Peak';    % 'Peak','Probability'
UI.preferences.monoSynDisp = 'Selected';         % 'All', 'Upstream', 'Downstream', 'Up & downstream', 'Selected', 'None'

UI.preferences.plotWaveformMetrics = 0;            % show waveform metrics on the single waveform
UI.preferences.sortingMetric = 'burstIndex_Royer2012'; % metrics used for sorting image data
UI.preferences.markerSize = 15;                    % marker size in the group plots [default: 20]
UI.preferences.plotInsetChannelMap = 3;            % Show a channel map inset with waveforms.
UI.preferences.plotInsetACG = 0;                   % Show a ACG plot inset with waveforms.
UI.preferences.colormap = 'hot';                   % colormap of image plots
UI.preferences.colormapStates = 'lines';           % colormap of states plots
UI.preferences.zscoreWaveforms = 1;                % Show zscored or full amplitude waveforms
UI.preferences.trilatGroupData = 'session';        % 'session','animal','all'
UI.preferences.hoverEffect = 1;                    % Highlights cells by hovering the mouse
UI.preferences.stickySelection = false; 

% Initial data displayed in the customPlot
UI.preferences.plotXdata = 'firingRate';
UI.preferences.plotYdata = 'peakVoltage';
UI.preferences.plotZdata = 'troughToPeak';
UI.preferences.plotMarkerSizedata = 'peakVoltage';

% Highlight excitatory / inhibitory cells
UI.preferences.displayInhibitory = false;          % boolean
UI.preferences.displayExcitatory = false;          % boolean
UI.preferences.displayExcitatoryPostsynapticCells = false; % boolean
UI.preferences.displayInhibitoryPostsynapticCells = false; % boolean
UI.preferences.plotExcitatoryConnections = true; 
UI.preferences.plotInhibitoryConnections = true; 

UI.preferences.showIntroduction = true; 

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Other preferences
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

UI.preferences.acgYaxisLog = 1;
UI.preferences.dispLegend = 0;                     % [0,1] Display legends in plots?
UI.preferences.logMarkerSize = 0;
UI.preferences.plotChannelMapAllChannels = true;   % Boolean. Show a select set of channels or all 
UI.preferences.waveformsAcrossChannelsAlignment = 'Probe layout'; % 'Probe layout', 'Electrode groups'
UI.preferences.peakVoltage_all_sorting = 'channelOrder'; % 'channelOrder', 'amplitude', 'none'
UI.preferences.peakVoltage_session = true;   
UI.preferences.showAllTraces = 0;                  % Show all traces or a random subset (maxi 2000; faster UI)
UI.preferences.plotLinearFits = 0;                 % Linear fit shown in group plot for each cell group
UI.preferences.graph_depth = 4;                    % Allen Institute Brain region atlas depth [1:7]
UI.preferences.hoverTimer = 0.045;                 % A minimum interval timer between each hover call (in seconds. Increase if you have issue with CellExplorer not detecting your mouse clicks on graths)
UI.preferences.binCount = 100;
UI.preferences.plotZLog = 0; 
UI.preferences.plot3axis = 0;
UI.preferences.raster = 'cv2';
UI.preferences.displayMenu = 0; 
UI.preferences.shuffleLayout = 1;

UI.preferences.referenceData = 'None'; 
UI.preferences.groundTruthData = 'None'; 
UI.preferences.channelMapColoring = false;         % Color groups in channel map inset with waveforms

if verLessThan('matlab','9.9')
    UI.preferences.rasterMarker = '.';
else
    UI.preferences.rasterMarker = '|';
end

% Autosave
UI.preferences.autoSaveFrequency = 5;              % How often you want to autosave (classifications steps). Put to 0 to turn autosave off
UI.preferences.autoSaveVarName = 'cell_metrics';   % Variable name used in autosave

% Cell type classification definitions
UI.preferences.cellTypes = {'Unknown','Pyramidal Cell','Narrow Interneuron','Wide Interneuron'};
UI.preferences.deepSuperficial = {'Unknown','Cortical','Deep','Superficial'};
UI.preferences.tags = {'Good','Bad','Noise','InverseSpike'};
UI.preferences.groundTruth = {'PV','NOS1','GAT1','SST','Axoaxonic'};
UI.preferences.groupDataMarkers = ce_append(["o","d","s","*","+"],["m","k","g"]'); 

UI.preferences.putativeConnectingMarkers = {'k','m','c','b'}; % 1) Excitatory, 2) Inhibitory, 3) Receiving Excitation, 4) receiving Inhibition, 
UI.preferences.groundTruthMarker = 'o'; % Supports any Matlab marker symbols: https://www.mathworks.com/help/matlab/creating_plots/create-line-plot-with-markers.html
UI.preferences.groundTruthColors = [[.9,.2,.2];[.2,.2,.9];[0.2,0.9,0.9];[0.9,0.2,0.9];[.2,.9,.2];[.5,.5,.5];[.8,.2,.2];[.2,.2,.8];[0.2,0.8,0.8];[0.8,0.2,0.8]];
UI.preferences.cellTypeColors = [[.5,.5,.5];[.8,.2,.2];[.2,.2,.8];[0.2,0.8,0.8];[0.8,0.2,0.8];[.2,.8,.2]];

% Dimensionality reduction plot
% tSNE
UI.preferences.tSNE.algorithm = 'tSNE'; % Options: {'tSNE','UMAP','PCA'}
UI.preferences.tSNE.metrics = {'troughToPeak','ab_ratio','burstIndex_Royer2012','acg_tau_rise','firingRate'};
UI.preferences.tSNE.dDistanceMetric = 'chebychev';
UI.preferences.tSNE.exaggeration = 10; 
UI.preferences.tSNE.standardize = true;
UI.preferences.tSNE.NumPCAComponents = 0;
UI.preferences.tSNE.LearnRate = 1000;
UI.preferences.tSNE.Perplexity = 30;
UI.preferences.tSNE.InitialY = 'Random';

% UMAP
UI.preferences.tSNE.n_neighbors = 30;
UI.preferences.tSNE.min_dist = 0.3;

% Firing rate map
UI.preferences.firingRateMap.showHeatmap = false;          % boolean
UI.preferences.firingRateMap.showLegend = false;           % boolean
UI.preferences.firingRateMap.showHeatmapColorbar = false;  % boolean

% Supplementary figure
UI.supplementaryFigure.waveformNormalization = 1;
UI.supplementaryFigure.groupDataNormalization = 1;
UI.supplementaryFigure.metrics = {'troughToPeak'  'acg_tau_rise'  'firingRate'  'cv2'  'peakVoltage'  'isolationDistance'  'lRatio'  'refractoryPeriodViolation'};
UI.supplementaryFigure.axisScale = [1 2 2 2 2 2 2 2];
UI.supplementaryFigure.smoothing = [1 1 1 1 1 1 1 1];

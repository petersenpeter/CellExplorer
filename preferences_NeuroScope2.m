function preferences = preferences_NeuroScope2(preferences)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% NeuroScope2 Preferences
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
% Preferences loaded by the NeuroScope2
% Visit the website of the CellExplorer for more details: https://CellExplorer.org/

preferences.debug = false; % For performance testing at this point
preferences.extraSpacing = true; % Adds spacing between the electrode groups traces
preferences.colormap = 'hsv'; % any Matlab colormap, e.g. 'hsv' or 'lines'
preferences.windowDuration = 1; % window duration in seconds
preferences.scalingFactor = 50; % Scaling factor
preferences.plotStyle = 2; % Plot style
preferences.greyScaleTraces = 1; % Plot colors
preferences.channelOrder = 1; % Channel order
preferences.plotTracesInColumns = false; % Plot traces in columns
preferences.colorByChannels = 1; % Color by channel order
preferences.nColorGroups = 10; % Number of color groups when coloring by channel order
preferences.displayMenu = 0; % Show the regular Matlab menu
preferences.background = [0 0 0]; % Background color
preferences.textBackground = [0 0 0 0.7]; % Text backgroups, semi-transparent
preferences.primaryColor = [1 1 1]; % Primary color of trace highlights and text
preferences.linewidth = 1.2; % Linewidth of ephys traces
preferences.showChannelNumbers = false; % Show channel numbers next to traces
preferences.showScalebar = false; % A vertical scalebar shown in upper left corner
preferences.showTimeScalebar = false; % A horizontal time scalebar shown in lower right corner
preferences.narrowPadding = false; % Padding above and below traces
preferences.ephys_padding = 0.05; % Initial padding above and below ephys traces
preferences.text_spacing = 0.016; % Vertical spacing between legends
preferences.resetZoomOnNavigation = false;
preferences.replayRefreshInterval = 0.50; % Fraction of window updated in replay mode
preferences.insetRelativeWidth = 1/4;
preferences.insetRelativeHeight = 1/4;
preferences.stickySelection = false;
preferences.to_save = {'windowDuration','plotStyle','greyScaleTraces','colormap','scalingFactor','background','textBackground','primaryColor',...
    'extraSpacing','plotTracesInColumns','showChannelNumbers','showScalebar','showTimeScalebar','narrowPadding','stickySelection','resetZoomOnNavigation'};

if ismac
    preferences.fontsize = 11;
else
    preferences.fontsize = 9;
end
preferences.detectedEventsBelowTrace = false;
preferences.detectedSpikesBelowTrace = false;


% Only Matlab 2020b and forward support vertical markers unfortunately
if verLessThan('matlab','9.9')
    preferences.rasterMarker = 'o';
else
    preferences.rasterMarker = '|';
end

% Trace processing
preferences.plotEnergy = false; % Absolute smoothing
preferences.energyWindow = 0.030; % Smoothing width (in seconds)
preferences.detectEvents = false; % Detect events
preferences.eventThreshold = 100; % Event threshold (in micro V)
preferences.filterTraces = false; % Filter traces
preferences.medianFilter = false; % Apply median filter
preferences.removeDC = false;     % Remove DC from traces
preferences.detectSpikes = false; % Detect spikes from high-pass filtered traces
preferences.spikesDetectionThreshold = -100; % in micro V
preferences.spikesDetectionPolarity = false; % Detect spikes with both polarity
preferences.showWaveformsBelowTrace = true;
preferences.showDetectedSpikeWaveforms = false;
preferences.showDetectedSpikesPCAspace = false;
preferences.showDetectedSpikesPopulationRate = false;
preferences.colorDetectedSpikesByWidth = false;
preferences.interneuronMaxWidth = 0.5; % in ms
preferences.waveformsRelativeWidth = 1/16;
preferences.spikeWaveformWidth = 0.0008; % in ms. Default: 2*0.8ms window size
preferences.filterMethod = 'filtfilt'; % filter or filtfilt

% Performance settings
preferences.plotStyleDynamicRange = true; % If true, in the range plot mode, all samples will be shown below a temporal threshold (default: 1.2 sec)
preferences.plotStyleDynamicThreshold = 23000; % in samples, threshold for switching between range and raw data presentation (Matlab's plot scales linearly with samples and channels certain number of points after which the performance changes and the range plotting style becomes faster)
preferences.plotStyleRangeSamples = 4; % average samples per second of data. Default: 4; Higher value will show less data points

% Spikes settings
preferences.spikesBelowTrace = false;
preferences.useSpikesYData = false;
preferences.spikesYData = ''; % Metric applied to sort spikes shown below the traces
preferences.spikesColormap = 'hsv'; % The colormap applied to units
preferences.spikesGroupColors = 1;
preferences.showPopulationRate = false;
preferences.populationRateBelowTrace = true;
preferences.populationRateWindow = 0.001; % seconds
preferences.populationRateSmoothing = 35; % nBins
preferences.spikeRasterLinewidth = 1.2;
preferences.showSpikeWaveforms = false; % Show spike waveforms below traces
preferences.showSpikesPCAspace = false;
preferences.PCAspace_electrodeGroup = 1;
preferences.showSpikeMatrix = false;

% Other spike data
preferences.klustaBelowTrace = false;
preferences.kilosortBelowTrace = false;
preferences.spykingcircusBelowTrace = false;

% Cell metrics
preferences.tags = {'Good','Bad','Noise','InverseSpike'};
preferences.groundTruth = {'PV','NOS1','GAT1','SST','Axoaxonic','CellType_A'};

% Event settings
preferences.iEvent = 1;
preferences.showEventsBelowTrace = false;
preferences.showEventsIntervals = false;
preferences.processing_steps = false;

% Behavior settings
preferences.plotBehaviorLinearized = false;
preferences.showBehaviorBelowTrace = false;
preferences.showTrials = false;

% Intan settings
preferences.showTimeseriesBelowTrace = false;

% Spectrogram
preferences.spectrogram.show = false;
preferences.spectrogram.channel = 1;
preferences.spectrogram.window = 0.2;
preferences.spectrogram.freq_low = 4;
preferences.spectrogram.freq_high = 250;
preferences.spectrogram.freq_step_size = 2;
preferences.spectrogram.freq_range = [preferences.spectrogram.freq_low:preferences.spectrogram.freq_step_size:preferences.spectrogram.freq_high];

% CSD
preferences.CSD.show = false;

% RMS noise inset
preferences.plotRMSnoiseInset = false;
preferences.plotRMSnoise_apply_filter = 2;
preferences.plotRMSnoise_lowerBand = 100;
preferences.plotRMSnoise_higherBand = 220;

% Instantaneous metrics plot
preferences.instantaneousMetrics.show = false;
preferences.instantaneousMetrics.showPower = false;
preferences.instantaneousMetrics.showSignal = false;
preferences.instantaneousMetrics.showPhase = false;
preferences.instantaneousMetrics.channel = 1;
preferences.instantaneousMetrics.lowerBand = 100;
preferences.instantaneousMetrics.higherBand = 220;

% Audio
% only works together with the DSP System Toolbox or the Audio Toolbox
preferences.audioChannels = [1,2]; % Up to two channels can be selected
preferences.audioGain = 3; % Gain factor, recommended: 1:5 = 1,2,5,10,20

function PSTH = calc_PSTH(event,spikes,varargin)
% This is a generalized way for creating a PSTH for units for various events
% 
% INPUTS
% event  : event times formatted according to the CellExplorer's convention
% spikes : spikes formatted according to the CellExplorer's convention
%
% See description of parameters below
% 
% OUTPUT
% PSTH : struct
% .modulationIndex : the difference between the averages of the stimulation interval and the pre-stimulation interval (the baseline) divided by their sum. Scaled from -1 to 1.
% .modulationRatio : The ratio between the averages of the stimulation interval and the pre-stimulation interval (the baseline). 
% .modulationPeakResponseTime : The delay between the alignment and the peak response of the average response, post-smoothing.
% .modulationSignificanceLevel : KS-test (kstest2) between the stimulation values and the pre-stimulation values, pre-smoothing
% 
% Dependencies: CCG
%
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited 10-11-2022

p = inputParser;

addParameter(p,'binCount',100,@isnumeric);        % how many bins (for half the window)
addParameter(p,'alignment','onset',@ischar);    % alignment of time ['onset','center','peaks','offset']
addParameter(p,'binDistribution',[0.25,0.5,0.25],@isnumeric);  % How the bins should be distributed around the events, pre, during, post. Must sum to 1
addParameter(p,'duration',nan,@isnumeric);        % duration of PSTH (for half the window - used in CCG) [in seconds]
addParameter(p,'intervals',[nan,nan,nan],@isnumeric);  % Define specific intervals to be applied. Must be a 1x3 vector [in seconds]

addParameter(p,'percentile',99,@isnumeric);     % if events does not have the same length, the event duration can be determined from percentile of the distribution of events
addParameter(p,'smoothing',nan,@isnumeric);       % any gaussian smoothing to apply? units of bins.
addParameter(p,'plots',true,@islogical);        % Show plots?
addParameter(p,'eventName','',@ischar);         % Title used for plots
addParameter(p,'maxWindow',10,@isnumeric);      % Maximum window size in seconds

% Setting intervals overrules binDistribution, duration, percentile
% Setting duration overrules percentile

parse(p,varargin{:})

binCount = p.Results.binCount;
alignment = p.Results.alignment;
binDistribution = p.Results.binDistribution;
intervals = p.Results.intervals;
duration = p.Results.duration;
smoothing = p.Results.smoothing;
percentile = p.Results.percentile;
eventName = p.Results.eventName;
plots = p.Results.plots;
maxWindow = p.Results.maxWindow;

% If intervals is given
if all(~isnan(intervals))
    duration = sum(intervals)/2;
    binDistribution = intervals / sum(intervals);
end

% If no duration is given, an optimal duration is determined from the percentile
if isnan(duration)
    durations = diff(event.timestamps');
    stim_duration = prctile(sort(durations),percentile);
    duration = min(max(round(stim_duration*1000),50)/1000,maxWindow);
end

binSize = max(duration/binCount*1000,0.5)/1000; % minimum binsize is 0.5ms.

% Determine event alignment
switch alignment
    case 'onset'
        event_times = event.timestamps(:,1);
        padding = binDistribution(1)/binDistribution(2)*duration;
        binsToKeep = int64(ceil((padding+duration/2)/binSize):(duration+padding)*2/binSize);
    case 'center'
        event_times = mean(event.timestamps);
        padding = 0;
        binsToKeep = 1:duration*2/binSize;
    case 'offset'
        event_times = event.timestamps(:,2);
        padding = binDistribution(3)/binDistribution(2)*duration;
        binsToKeep = 1:(duration+padding)*2/binSize-ceil((padding+duration/2)/binSize);
    case 'peaks'
        event_times = event.peaks;
        padding = 0;
        binsToKeep = 1:duration*2/binSize;
end

disp(['  ', num2str(length(event_times)), '  events, duration set to: ', num2str(duration), ' sec, aligned to ', alignment,', with binsize: ' num2str(binSize)])

% Determining the bins interval for metrics
binsPre = 1:floor(binDistribution(1)*length(binsToKeep));
binsEvents = floor(binDistribution(1)*length(binsToKeep))+1:floor((binDistribution(1)+binDistribution(2))*length(binsToKeep));
binsPost = floor((binDistribution(1)+binDistribution(2))*length(binsToKeep))+1:length(binsToKeep);

% Calculating PSTH
PSTH_out = [];
sr = spikes.sr; % Sampling rate
for j = 1:numel(spikes.times)   
    [spike_times,index] = sort([spikes.times{j};event_times(:)]);
    spike_cluster_index = [ones(size(spikes.times{j}));2*ones(size(event_times(:)))];
    [ccg,time] = CCG(spike_times,spike_cluster_index(index),'binSize',binSize,'duration',(duration+padding)*2,'Fs',1/sr);
    PSTH_out(:,j) = ccg(binsToKeep+1,2,1)./numel(event_times)/binSize;
end
time = time(binsToKeep+1);

% Calculating modulation ratio
modulationRatio = mean(PSTH_out(binsEvents,:))./mean(PSTH_out(binsPre,:));

% Calculating modulation index
modulationIndex = (mean(PSTH_out(binsEvents,:))-mean(PSTH_out(binsPre,:)))./(mean(PSTH_out(binsEvents,:))+mean(PSTH_out(binsPre,:)));

% Calculating modulation significance level
modulationSignificanceLevel = [];
for i = 1:size(PSTH_out,2)
    [~,p_kstest2] = kstest2(PSTH_out(binsEvents,i),PSTH_out(binsPre,i));
    modulationSignificanceLevel(i) = p_kstest2;
end

% Applying smoothing
if ~isnan(smoothing)
    PSTH_out = nanconv(PSTH_out,ce_gausswin(smoothing)/sum(ce_gausswin(smoothing)),'edge');
end

% Calculating modulation peak response time
[~,modulationPeakResponseTime] = max(PSTH_out);
modulationPeakResponseTime = time(modulationPeakResponseTime);

% Generating output structure
PSTH.responsecurve = PSTH_out;
PSTH.time = time;
PSTH.alignment = alignment;
PSTH.modulationRatio = modulationRatio;
PSTH.modulationIndex = modulationIndex;
PSTH.modulationPeakResponseTime = modulationPeakResponseTime';
PSTH.modulationSignificanceLevel = modulationSignificanceLevel;

% Generating plots
if plots
    figure, plot(time,PSTH_out), title(eventName), xlabel('Time')
    [~,index2] = sort(modulationIndex,'descend');
    [~,index3] = sort(modulationPeakResponseTime);
    
    figure,
    subplot(2,2,1), histogram(modulationIndex,40), title('modulationIndex'), xlabel('Ratio'), ylabel(eventName)
    subplot(2,2,2), histogram(modulationPeakResponseTime,40), title('modulationPeakResponseTime'), xlabel('Time')
    subplot(2,2,3), imagesc(time,[1:size(PSTH_out,2)],zscore(PSTH_out(:,index2))'), title('Sorting: modulationIndex'), xlabel('Time'), ylabel('Units')
    subplot(2,2,4), imagesc(time,[1:size(PSTH_out,2)],zscore(PSTH_out(:,index3))'),  title('Sorting: modulationPeakResponseTime'), xlabel('Time')
end

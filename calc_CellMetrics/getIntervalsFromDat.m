function events = getIntervalsFromDat(timestamps,session,varargin)
% Extracts event intervals from the binary file. 
% This function is part of CellExplorer: https://cellexplorer.org/
%
% INPUTS
% events struct:            https://cellexplorer.org/datastructure/data-structure-and-format/#events
% session metadata struct:  https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata
%
% Last edited: 21-12-2020

p = inputParser;
addParameter(p,'nPull',600, @isnumeric); % number of events to pull out (default: 600)
addParameter(p,'wfWin_sec', 0.160, @isnumeric); % Larger size of event intervals for filterning. total width in seconds (default: 0.080 sec)
addParameter(p,'wfWinKeep', 0.040, @isnumeric); % half width in seconds (default: 0.040 sec)
addParameter(p,'showIntervals', true, @islogical);
addParameter(p,'filtFreq',[80,220], @isnumeric); % Band pass filter (default: 80Hz - 220Hz)
addParameter(p,'keepIntervals_filt', false, @islogical); % Keep all extracted filtered events
addParameter(p,'keepIntervals_raw', false, @islogical); % Keep all extracted raw events
addParameter(p,'saveFig', false, @islogical); % Save figure with data
addParameter(p,'extraLabel', '', @ischar); % Extra labels in figures
addParameter(p,'getBadChannelsFromDat', true, @islogical); % Determining any extra bad channels from noiselevel of .dat file

parse(p,varargin{:})

nPull = p.Results.nPull;
wfWin_sec = p.Results.wfWin_sec;
wfWinKeep = p.Results.wfWinKeep;
showIntervals = p.Results.showIntervals;
filtFreq = p.Results.filtFreq;
keepIntervals_filt = p.Results.keepIntervals_filt;
keepIntervals_raw = p.Results.keepIntervals_raw;
saveFig = p.Results.saveFig;
extraLabel  = p.Results.extraLabel;
params = p.Results;

events = {};

% Loading session struct into separate parameters
basepath = session.general.basePath;
basename = session.general.name;
LSB = session.extracellular.leastSignificantBit;
nChannels = session.extracellular.nChannels;
sr = session.extracellular.sr;
electrodeGroups = session.extracellular.electrodeGroups.channels;
nElectrodeGroups = session.extracellular.nElectrodeGroups;
if isfield(session.extracellular,'fileName') && ~isempty(session.extracellular.fileName)
    fileNameRaw = session.extracellular.fileName;
else
    fileNameRaw = [basename '.dat'];
end
try
    precision = session.extracellular.precision;
catch
    precision = 'int16';
end

badChannels = [];
timerVal = tic;

if filtFreq(2) > sr/2
    filtFreq(2) = sr/2-1;
end

% Determining any extra bad channels from noiselevel of .dat file
if params.getBadChannelsFromDat
    try
        session = getBadChannelsFromDat(session,'filtFreq',filtFreq);
    end
end

% Removing channels marked as Bad in session struct
if ~isempty(session) && isfield(session,'channelTags') && isfield(session.channelTags,'Bad')
    if isfield(session.channelTags.Bad,'channels') && ~isempty(session.channelTags.Bad.channels)
        badChannels = [badChannels,session.channelTags.Bad.channels];
    end
    if isfield(session.channelTags.Bad,'electrodeGroups') && ~isempty(session.channelTags.Bad.electrodeGroups)
        badChannels = [badChannels,electrodeGroups{session.channelTags.Bad.electrodeGroups}];
    end
    badChannels = unique(badChannels);
end

if ~isempty(badChannels)
    badChannels_message = ['Bad channels detected: ' num2str(badChannels)];
else
    badChannels_message = 'No bad channels detected. ';
end

if isempty(badChannels)
    goodChannels = 1:nChannels;
else
    goodChannels = setdiff(1:nChannels,badChannels);
end
nGoodChannels = length(goodChannels);

int_gt_0 = @(n,sr) (isempty(n)) || (n <= 0 ) || (n >= sr/2) || isnan(n);

if int_gt_0(filtFreq(1),sr) && ~int_gt_0(filtFreq(1),sr)
    [b1, a1] = butter(3, filtFreq(2)/sr*2, 'low');
    filter_message = ['Lowpass filter applied: ' num2str(filtFreq(2)),' Hz. '];
elseif int_gt_0(filtFreq(2),sr) && ~int_gt_0(filtFreq(1),sr)
    [b1, a1] = butter(3, filtFreq(1)/sr*2, 'high');
    filter_message = ['Highpass filter applied: ' num2str(filtFreq(1)),' Hz. '];
else
    [b1, a1] = butter(3, [filtFreq(1),filtFreq(2)]/sr*2, 'bandpass');
    filter_message = ['Bandpass filter applied: ', num2str(filtFreq(1)) ,' - ',num2str(filtFreq(2)),' Hz. '];
end

disp(['Getting event intervals from dat file (nPull=', num2str(nPull),'). ', filter_message, badChannels_message])
if showIntervals
    fig1 = figure('Name', ['Getting event intervals for ' basename],'NumberTitle', 'off','position',[100,100,1000,800]);
    movegui('center');
end

wfWin = round((wfWin_sec * sr)/2);
window_interval = wfWin-ceil(wfWinKeep*sr):wfWin-1+ceil(wfWinKeep*sr); % +- 0.8 ms of interval
window_interval2 = wfWin-ceil(1.5*wfWinKeep*sr):wfWin-1+ceil(1.5*wfWinKeep*sr); % +- 1.20 ms of interval
t1 = toc(timerVal);
if ~exist(fullfile(basepath,fileNameRaw),'file')
    error(['Binary file missing: ', fullfile(basepath,fileNameRaw)])
end
s = dir(fullfile(basepath,fileNameRaw));

duration = s.bytes/(2*nChannels*sr);
rawData = memmapfile(fullfile(basepath,fileNameRaw),'Format',precision,'writable',false);

    t1 = toc(timerVal);
    spkTmp = round(sr * timestamps(find(timestamps > wfWin_sec/1.8 & timestamps < duration-wfWin_sec/1.8)));
    
    if length(spkTmp) > nPull
        spkTmp = spkTmp(randperm(length(spkTmp)));
        spkTmp = sort(spkTmp(1:nPull));
    end
    spkTmp = spkTmp(:);
    
    % Pulls the Intervals from all channels from the dat
    startIndicies2 = (spkTmp - wfWin)*nChannels+1;
    stopIndicies2 = (spkTmp + wfWin)*nChannels;
    X2 = cumsum(accumarray(cumsum([1;stopIndicies2(:)-startIndicies2(:)+1]),[startIndicies2(:);0]-[0;stopIndicies2(:)]-1)+1);
    wf = LSB * permute(reshape(double(rawData.Data(X2(1:end-1))),nChannels,(wfWin*2),[]),[2,3,1]);
    wfF = zeros((wfWin * 2),length(spkTmp),nChannels);
    for jjj = 1 : nChannels
        wfF(:,:,jjj) = filtfilt(b1, a1, wf(:,:,jjj));
    end
    wfF = permute(wfF,[3,1,2]);
    
    for jjj = 1 : nChannels
        wf(:,:,jjj) = detrend(wf(:,:,jjj));
    end    
    
    wf = permute(wf,[3,1,2]);
    wfF2 = mean(wfF(goodChannels,:,:),3)';
    [~, maxIntervalCh1] = max(max(wfF2(window_interval,:))-min(wfF2(window_interval,:)));
    events.maxIntervalCh1 = goodChannels(maxIntervalCh1);
    events.maxIntervalCh = events.maxIntervalCh1-1;
    
    % Assigning shankID to the unit
    for jj = 1:nElectrodeGroups
        if any(electrodeGroups{jj} == events.maxIntervalCh1)
            events.shankID = jj;
        end
    end

    rawIntervals_all = mean(wf,3);
    events.rawIntervals = rawIntervals_all(events.maxIntervalCh1,window_interval);
    rawIntervals_std = std((wf(events.maxIntervalCh1,:,:)-mean(wf(events.maxIntervalCh1,:,:),3)),0,3);
    filtIntervals_all = mean(wfF,3);
    events.filtIntervals = filtIntervals_all(events.maxIntervalCh1,window_interval);
    filtIntervals_std = std((wfF(events.maxIntervalCh1,:,:)-mean(wfF(events.maxIntervalCh1,:,:),3)),0,3);
    
    events.rawIntervals_all = rawIntervals_all(:,window_interval2);
    events.rawIntervals_std = rawIntervals_std(window_interval);
    events.filtIntervals_all = filtIntervals_all(:,window_interval2);
    events.filtIntervals_std = filtIntervals_std(window_interval);
    events.timeInterval = ([-ceil(wfWinKeep*sr)*(1/sr):1/sr:(ceil(wfWinKeep*sr)-1)*(1/sr)])*1000;
    events.timeInterval_all = ([-ceil(1.5*wfWinKeep*sr)*(1/sr):1/sr:(ceil(1.5*wfWinKeep*sr)-1)*(1/sr)])*1000;
    events.peakVoltage = range(events.filtIntervals);
    events.channels_all = [1:nChannels];
    
    [B,I] = sort(range(events.filtIntervals_all(goodChannels,:),2),'descend');
    events.peakVoltage_sorted = zeros(1,nChannels);
    events.peakVoltage_sorted(1:length(goodChannels)) = B;
    events.maxInterval_all = zeros(1,nChannels);
    events.maxInterval_all(1:length(goodChannels)) = goodChannels(I);

    % keep all filtered Intervals
    if keepIntervals_filt
        events.intervals.filt = wfF(:,window_interval,:);
    end
    
    % keep all raw intervals
    if keepIntervals_raw
        events.intervals.raw = wf(:,window_interval,:);
    end
    
    if keepIntervals_filt || keepIntervals_raw
       events.intervals.peaks = spkTmp/sr;
    end
    
    if showIntervals 
        time = ([-ceil(wfWin_sec/2*sr)*(1/sr):1/sr:(ceil(wfWin_sec/2*sr)-1)*(1/sr)])*1000;
        if ishandle(fig1)
        figure(fig1)
        subplot(2,3,1), hold off
        plot(time,wfF2), hold on, plot(time,wfF2(:,maxIntervalCh1),'k','linewidth',2), xlabel('Time (ms)'),title('All channels'),ylabel('Average filtered intervals across channels (\muV)','Interpreter','tex'), hold off
        
        subplot(2,3,2), hold off,
        plot(time,permute(wfF(events.maxIntervalCh1,:,:),[2,3,1])), hold on
        plot(time,mean(permute(wfF(events.maxIntervalCh1,:,:),[2,3,1]),2),'k','linewidth',2),
        title(['Peak channel = ',num2str(events.maxIntervalCh1)]),ylabel('Filtered intervals from peak channel (\muV)','Interpreter','tex'), xlabel('Time (ms)')
        
        subplot(2,3,4), hold off,
        plot(events.timeInterval,vertcat(events.rawIntervals)'), hold on
        plot(events.timeInterval,events.rawIntervals,'-k'), xlabel('Time (ms)'), ylabel('Raw intervals (\muV)','Interpreter','tex'), axis tight
        
        subplot(2,3,5), hold off,
        plot(events.timeInterval,vertcat(events.filtIntervals)'), hold on
        plot(events.timeInterval,events.filtIntervals,'-k'), xlabel('Time (ms)'), ylabel('Filtered intervals (\muV)','Interpreter','tex'), axis tight
        
        subplot(3,3,3), hold off
        plot(spkTmp/sr,permute(range((wfF(events.maxIntervalCh1,window_interval,:)),2),[3,2,1]),'.b')
        ylabel('Amplitude (\muV)','Interpreter','tex'), xlabel('Time (sec)'), title(['Spike amplitudes (nPull=' num2str(nPull),')'])
        
        subplot(3,3,6), hold off
        plot(events.peakVoltage_sorted,'-b'), hold on
        xlabel('Sorted channels'), ylabel('Amplitude (\muV)','Interpreter','tex'), axis tight
        
        subplot(3,3,9), hold on
        all_channels = [session.extracellular.electrodeGroups.channels{:}];
        plot(events.peakVoltage_sorted(events.maxInterval_all(all_channels)),'-r'), hold on
        xlabel('Channels'), ylabel('Amplitude (\muV)','Interpreter','tex'), axis tight
 
        if saveFig && ishandle(fig1)
            % Saving figure
            saveFig1.path = 1; saveFig1.fileFormat = 1; saveFig1.save = 1;
            ce_savefigure(fig1,basepath,[basename, '.getIntervalsFromDat'],0,saveFig1)
        end
    else
        disp('Canceling event intervals extraction...')
        clear wf wfF wf2 wfF2
        clear rawIntervals rawIntervals_std filtIntervals filtIntervals_std
        clear rawData
        error('Event intervals extraction canceled by user by closing figure window.')
        end
    end
    clear wf wfF wf2 wfF2


events.getIntervalsFromDat.params.IntervalsSource = 'dat file';
events.getIntervalsFromDat.params.IntervalsFiltFreq = filtFreq;
events.getIntervalsFromDat.params.Intervals_nPull = nPull;
events.getIntervalsFromDat.params.IntervalsWin_sec = wfWin_sec;
events.getIntervalsFromDat.params.IntervalsWinKeep = wfWinKeep;
events.getIntervalsFromDat.params.IntervalsFilterType = 'butter';
clear rawIntervals rawIntervals_std filtIntervals filtIntervals_std
clear rawData

% Plots
if showIntervals && ishandle(fig1)
    fig1.Name = [basename, ': Intervals extraction complete. ', num2str(round(toc(timerVal)/60)) ' minutes total'];
    
    % Saving a summary figure for all cells
    timestamp = datestr(now, '_dd-mm-yyyy_HH.MM.SS');
    try
        ce_savefigure(fig1,basepath,[basename, '.getIntervalsFromDat' timestamp])
        disp(['getIntervalsFromDat: Summary figure saved to ', fullfile(basepath, 'SummaryFigures', [basename, '.getIntervalsFromDat', timestamp]),'.png'])
    end
end
disp(['Interval extraction complete. Total duration: ' num2str(round(toc(timerVal)/60)),' minutes'])
end
function spikes = getWaveformsFromDat(spikes,session,varargin)
% Extracts raw waveforms from the binary file. 
% This function is part of CellExplorer: https://cellexplorer.org/
%
% INPUTS
% Spikes struct:            https://cellexplorer.org/datastructure/data-structure-and-format/#spikes
% session metadata struct:  https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata
%
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 21-12-2020

% Loading preferences
preferences = preferences_ProcessCellMetrics(session);

p = inputParser;
addParameter(p,'unitsToProcess',1:size(spikes.times,2), @isnumeric);
addParameter(p,'nPull',preferences.waveform.nPull, @isnumeric); % number of spikes to pull out (default: 600)
addParameter(p,'wfWin_sec', preferences.waveform.wfWin_sec, @isnumeric); % Larger size of waveform windows for filterning. total width in seconds (default: 0.004)
addParameter(p,'wfWinKeep', preferences.waveform.wfWinKeep, @isnumeric); % half width in seconds (default: 0.0008)
addParameter(p,'showWaveforms', preferences.waveform.showWaveforms, @islogical);
addParameter(p,'filtFreq',[500,8000], @isnumeric); % Band pass filter (default: 500Hz - 8000Hz)
addParameter(p,'keepWaveforms_filt', false, @islogical); % Keep all extracted filtered waveforms
addParameter(p,'keepWaveforms_raw', false, @islogical); % Keep all extracted raw waveforms
addParameter(p,'saveFig', false, @islogical); % Save figure with data
addParameter(p,'extraLabel', '', @ischar); % Extra labels in figures
addParameter(p,'getBadChannelsFromDat', true, @islogical); % Determining any extra bad channels from noiselevel of .dat file
parse(p,varargin{:})

unitsToProcess = p.Results.unitsToProcess;
nPull = p.Results.nPull;
wfWin_sec = p.Results.wfWin_sec;
wfWinKeep = p.Results.wfWinKeep;
showWaveforms = p.Results.showWaveforms;
filtFreq = p.Results.filtFreq;
keepWaveforms_filt = p.Results.keepWaveforms_filt;
keepWaveforms_raw = p.Results.keepWaveforms_raw;
saveFig = p.Results.saveFig;
extraLabel  = p.Results.extraLabel;
params = p.Results;

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

badChannels = [];
timerVal = tic;

% Determining any extra bad channels from noiselevel of .dat file
if params.getBadChannelsFromDat
    session = getBadChannelsFromDat(session);
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
disp(['Bad channels detected: ' num2str(badChannels)])

% Removing channels that does not exist in SpkGrps
if isfield(session.extracellular,'spikeGroups')
    badChannels = [badChannels,setdiff([electrodeGroups{:}],[session.extracellular.spikeGroups.channels{:}])];
end

if isempty(badChannels)
    goodChannels = 1:nChannels;
else
    goodChannels = setdiff(1:nChannels,badChannels);
end
nGoodChannels = length(goodChannels);

[b1, a1] = butter(3, filtFreq/sr*2, 'bandpass');
disp('Getting waveforms from dat file')
if showWaveforms
    fig1 = figure('Name', ['Getting waveforms for ' basename],'NumberTitle', 'off','position',[100,100,1000,800]);
    movegui('center');
end

wfWin = round((wfWin_sec * sr)/2);
window_interval = wfWin-ceil(wfWinKeep*sr):wfWin-1+ceil(wfWinKeep*sr); % +- 0.8 ms of waveform
window_interval2 = wfWin-ceil(1.5*wfWinKeep*sr):wfWin-1+ceil(1.5*wfWinKeep*sr); % +- 1.20 ms of waveform
t1 = toc(timerVal);
if ~exist(fullfile(basepath,fileNameRaw),'file')
    error(['Binary file missing: ', fullfile(basepath,fileNameRaw)])
end
s = dir(fullfile(basepath,fileNameRaw));

duration = s.bytes/(2*nChannels*sr);
rawData = memmapfile(fullfile(basepath,fileNameRaw),'Format','int16','writable',false);
% DATA = rawData.Data;

% Fit exponential
g = fittype('a*exp(-x/b)+c','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c'});

for i = 1:length(unitsToProcess)
    ii = unitsToProcess(i);
    t1 = toc(timerVal);
    if isfield(spikes,'ts')
        spkTmp = spikes.ts{ii}(find(spikes.ts{ii}./sr > wfWin_sec/1.8 & spikes.ts{ii}./sr < duration-wfWin_sec/1.8));
    else
        spkTmp = round(sr * spikes.times{ii}(find(spikes.times{ii} > wfWin_sec/1.8 & spikes.times{ii} < duration-wfWin_sec/1.8)));
    end
    
    if length(spkTmp) > nPull
        spkTmp = spkTmp(randperm(length(spkTmp)));
        spkTmp = sort(spkTmp(1:nPull));
    end
    spkTmp = spkTmp(:);
%     % Determines the maximum waveform channel from 100 waveforms across all good channels
%     startIndicies1 = (spkTmp(1:min(100,length(spkTmp))) - wfWin)*nChannels+1;
%     stopIndicies1 =  (spkTmp(1:min(100,length(spkTmp))) + wfWin)*nChannels;
%     X1 = cumsum(accumarray(cumsum([1;stopIndicies1(:)-startIndicies1(:)+1]),[startIndicies1(:);0]-[0;stopIndicies1(:)]-1)+1);
%     wf = LSB * mean(reshape(double(rawData.Data(X1(1:end-1))),nChannels,(wfWin*2),[]),3);
%     wfF2 = zeros((wfWin * 2),nGoodChannels);
%     for jj = 1 : nGoodChannels
%         wfF2(:,jj) = filtfilt(b1, a1, wf(goodChannels(jj),:));
%     end
    
    % Pulls the waveforms from all channels from the dat
    startIndicies2 = (spkTmp - wfWin)*nChannels+1;
    stopIndicies2 = (spkTmp + wfWin)*nChannels;
    X2 = cumsum(accumarray(cumsum([1;stopIndicies2(:)-startIndicies2(:)+1]),[startIndicies2(:);0]-[0;stopIndicies2(:)]-1)+1);
    wf = LSB * permute(reshape(double(rawData.Data(X2(1:end-1))),nChannels,(wfWin*2),[]),[2,3,1]);
    wfF = zeros((wfWin * 2),length(spkTmp),nChannels);
    for jjj = 1 : nChannels
        wfF(:,:,jjj) = filtfilt(b1, a1, wf(:,:,jjj));
    end
    wfF = permute(wfF,[3,1,2]);
    wf = permute(wf,[3,1,2]);
    wfF2 = mean(wfF(goodChannels,:,:),3)';
    [~, maxWaveformCh1] = max(max(wfF2(window_interval,:))-min(wfF2(window_interval,:)));
    spikes.maxWaveformCh1(ii) = goodChannels(maxWaveformCh1);
    spikes.maxWaveformCh(ii) = spikes.maxWaveformCh1(ii)-1;
    
    % Assigning shankID to the unit
    for jj = 1:nElectrodeGroups
        if any(electrodeGroups{jj} == spikes.maxWaveformCh1(ii))
            spikes.shankID(ii) = jj;
        end
    end
    
    wf2 = mean(wf,3);
    rawWaveform_all = detrend(wf2 - mean(wf2,2));
    spikes.rawWaveform{ii} = rawWaveform_all(spikes.maxWaveformCh1(ii),window_interval);
    rawWaveform_std = std((wf(spikes.maxWaveformCh1(ii),:,:)-mean(wf(spikes.maxWaveformCh1(ii),:,:),3)),0,3);
    filtWaveform_all = mean(wfF,3);
    spikes.filtWaveform{ii} = filtWaveform_all(spikes.maxWaveformCh1(ii),window_interval);
    filtWaveform_std = std((wfF(spikes.maxWaveformCh1(ii),:,:)-mean(wfF(spikes.maxWaveformCh1(ii),:,:),3)),0,3);
    
    spikes.rawWaveform_all{ii} = rawWaveform_all(:,window_interval2);
    spikes.rawWaveform_std{ii} = rawWaveform_std(window_interval);
    spikes.filtWaveform_all{ii} = filtWaveform_all(:,window_interval2);
    spikes.filtWaveform_std{ii} = filtWaveform_std(window_interval);
    spikes.timeWaveform{ii} = ([-ceil(wfWinKeep*sr)*(1/sr):1/sr:(ceil(wfWinKeep*sr)-1)*(1/sr)])*1000;
    spikes.timeWaveform_all{ii} = ([-ceil(1.5*wfWinKeep*sr)*(1/sr):1/sr:(ceil(1.5*wfWinKeep*sr)-1)*(1/sr)])*1000;
    spikes.peakVoltage(ii) = range(spikes.filtWaveform{ii});
    spikes.channels_all{ii} = [1:nChannels];
    
    [B,I] = sort(range(spikes.filtWaveform_all{ii}(goodChannels,:),2),'descend');
    spikes.peakVoltage_sorted{ii} = zeros(1,nChannels);
    spikes.peakVoltage_sorted{ii}(1:length(goodChannels)) = B;
    spikes.maxWaveform_all{ii} = zeros(1,nChannels);
    spikes.maxWaveform_all{ii}(1:length(goodChannels)) = goodChannels(I);

    % keep all filtered waveforms
    if keepWaveforms_filt
        spikes.waveforms.filt{ii} = wfF(:,window_interval,:);
    end
    
    % keep all raw waveforms
    if keepWaveforms_raw
        spikes.waveforms.raw{ii} = wf(:,window_interval,:);
    end
    
    if keepWaveforms_filt || keepWaveforms_raw
       spikes.waveforms.times{ii} = spkTmp/sr;
    end
    
    % Fitting peakVoltage sorted with exponential function with length constant
    nChannelFit = min([16,length(goodChannels),length(electrodeGroups{spikes.shankID(ii)})]);
    x = 1:nChannelFit;
    y = spikes.peakVoltage_sorted{ii}(x);
    if ~isempty(spikes.times{ii})
        f0 = fit(x',y',g,'StartPoint',[spikes.peakVoltage(ii), 5, 5],'Lower',[1, 0.001, 0],'Upper',[5000, 50, 1000]);
        fitCoeffValues = coeffvalues(f0);
        spikes.peakVoltage_expFitLengthConstant(ii) = fitCoeffValues(2);
    else
        spikes.peakVoltage_expFitLengthConstant(ii) = nan;
    end
    time = ([-ceil(wfWin_sec/2*sr)*(1/sr):1/sr:(ceil(wfWin_sec/2*sr)-1)*(1/sr)])*1000;
    if ishandle(fig1)
        figure(fig1)
        subplot(5,3,[1,4]), hold off
        plot(time,wfF2), hold on, plot(time,wfF2(:,maxWaveformCh1),'k','linewidth',2),title('All channels'),ylabel('Mean filtered waveforms (uV)'),hold off
        subplot(5,3,[2,5]), hold off,
        plot(time,permute(wfF(spikes.maxWaveformCh1(ii),:,:),[2,3,1])), hold on
        plot(time,mean(permute(wfF(spikes.maxWaveformCh1(ii),:,:),[2,3,1]),2),'k','linewidth',2),
        title(['Peak channel (',num2str(spikes.maxWaveformCh1(ii)),')']),ylabel('All filtered waveforms (uV)')
        
        subplot(5,3,[7,10]), hold off,
        plot(spikes.timeWaveform{ii},vertcat(spikes.rawWaveform{1:ii})'), hold on
        plot(spikes.timeWaveform{ii},spikes.rawWaveform{ii},'-k','linewidth',1.5), xlabel('Time (ms)'), ylabel('Raw waveforms (uV)'), xlim([-0.8,0.8])
        subplot(5,3,[8,11]), hold off,
        plot(spikes.timeWaveform{ii},vertcat(spikes.filtWaveform{1:ii})'), hold on
        plot(spikes.timeWaveform{ii},spikes.filtWaveform{ii},'-k','linewidth',1.5), xlabel('Time (ms)'), ylabel('Filtered waveforms (uV)'), xlim([-0.8,0.8])
        subplot(5,3,3), hold off
        plot(permute(range((wfF(spikes.maxWaveformCh1(ii),window_interval,:)),2),[3,2,1]),'.b')
        title('Spikes across time (uV)')
        subplot(5,3,6), hold off
        plot(spikes.peakVoltage_sorted{ii},'.-b'), hold on
        plot(x,fitCoeffValues(1)*exp(-x/fitCoeffValues(2))+fitCoeffValues(3),'r'),
        title(['Length constant (\lambda) = ',num2str(spikes.peakVoltage_expFitLengthConstant(ii),2)]), xlabel('Sorted channels'), ylabel('Amplitude (uV)'), xlim([1,nChannelFit])
        subplot(5,3,9), hold on
        plot(spikes.peakVoltage_sorted{ii}), title('Processed units'), xlabel('Sorted channels'), ylabel('Amplitude (uV)'), xlim([1,nChannelFit])
        subplot(5,3,12), hold off,
        histogram(spikes.peakVoltage_expFitLengthConstant(unitsToProcess(1:i)),20), title('Length constant (\lambda)'), axis tight
        subplot(5,3,15), hold off,
        histogram(spikes.peakVoltage(unitsToProcess(1:i)),20), title('Amplitudes (uV)'), axis tight
        
        subplot(10,3,[28,29]), hold off, title(['Extraction progress for session: ' basename ,' ', extraLabel],'interpreter','none')
        rectangle('Position',[0,0,100*i/length(unitsToProcess),1],'FaceColor',[0, 0.4470, 0.7410],'EdgeColor',[0, 0.4470, 0.7410] ,'LineWidth',1), xlim([0,100]), ylim([0,1]), set(gca,'xtick',[],'ytick',[])
        xlabel(['Waveforms: ',num2str(i),'/',num2str(length(unitsToProcess)),'. ', num2str(round(toc(timerVal)-t1)),' sec/unit, Duration: ', num2str(round(toc(timerVal)/60)), '/', num2str(round(toc(timerVal)/60/i*length(unitsToProcess))),' minutes']);
        
        if saveFig & ishandle(fig1)
            % Saving figure
            saveFig1.path = 1; saveFig1.fileFormat = 1; saveFig1.save = 1;
            ce_savefigure(fig1,basepath,[basename, '.getWaveformsFromDat_cell_', num2str(unitsToProcess(i))],0,saveFig1)
        end
    else
        disp('Canceling waveform extraction...')
        clear wf wfF wf2 wfF2
        clear rawWaveform rawWaveform_std filtWaveform filtWaveform_std
        clear rawData
        error('Waveform extraction canceled by user by closing figure window.')
    end
    clear wf wfF wf2 wfF2
end

% Plots
if ishandle(fig1)
    spikes.processinginfo.params.WaveformsSource = 'dat file';
    spikes.processinginfo.params.WaveformsFiltFreq = filtFreq;
    spikes.processinginfo.params.Waveforms_nPull = nPull;
    spikes.processinginfo.params.WaveformsWin_sec = wfWin_sec;
    spikes.processinginfo.params.WaveformsWinKeep = wfWinKeep;
    spikes.processinginfo.params.WaveformsFilterType = 'butter';
    clear rawWaveform rawWaveform_std filtWaveform filtWaveform_std
    clear rawData
    disp(['Waveform extraction complete. Total duration: ' num2str(round(toc(timerVal)/60)),' minutes'])
    fig1.Name = [basename, ': Waveform extraction complete. ',num2str(i),' cells processed.  ', num2str(round(toc(timerVal)/60)) ' minutes total'];
    
    % Saving a summary figure for all cells
    timestamp = datestr(now, '_dd-mm-yyyy_HH.MM.SS');
    try
        ce_savefigure(fig1,basepath,[basename, '.getWaveformsFromDat' timestamp])
        disp(['getWaveformsFromDat: Summary figure saved to ', fullfile(basepath, 'SummaryFigures', [basename, '.getWaveformsFromDat', timestamp]),'.png'])
    end
end
end
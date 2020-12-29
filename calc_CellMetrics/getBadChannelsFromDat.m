function [session,noiseLevel] = getBadChannelsFromDat(session,varargin)
% Extracts samples from the binary file to determine bad channels.
% This function is part of CellExplorer: https://cellexplorer.org/
%
% INPUT + varargin described below
% session metadata struct:  https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata
%
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 22-12-2020

p = inputParser;
addParameter(p,'nPull',1000, @isnumeric); % number of sample windows to pull out (default: 100)
addParameter(p,'wfWin_sec', 0.005, @isnumeric); % Larger size of waveform windows for filterning. total width in seconds (default: 0.004)
addParameter(p,'showWaveforms', true, @islogical);
addParameter(p,'filtFreq',[500,8000], @isnumeric); % Band pass filter (default: 500Hz - 8000Hz)
addParameter(p,'showFig', false, @islogical); % Show figure
addParameter(p,'saveFig', false, @islogical); % Save figure with data
addParameter(p,'extraLabel', '', @ischar); % Extra labels for the figures
addParameter(p,'noiseStdThreshold', 70, @isnumeric); % Noise threshold in uV. Default: 70uV
addParameter(p,'noiseRangeThreshold', 10, @isnumeric); % Noise threshold in uV. Default: 10uV
addParameter(p,'saveMat',true,@islogical);
parse(p,varargin{:})

nPull = p.Results.nPull;
wfWin_sec = p.Results.wfWin_sec;
showWaveforms = p.Results.showWaveforms;
filtFreq = p.Results.filtFreq;
saveFig = p.Results.saveFig;
extraLabel  = p.Results.extraLabel;
noiseStdThreshold  = p.Results.noiseStdThreshold;
noiseRangeThreshold  = p.Results.noiseRangeThreshold;
showFig = p.Results.showFig;
saveMat = p.Results.saveMat;

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

[b1, a1] = butter(3, filtFreq/sr*2, 'bandpass');

wfWin = round((wfWin_sec * sr)/2);
if ~exist(fullfile(basepath,fileNameRaw),'file')
    error(['Binary file missing: ', fullfile(basepath,fileNameRaw)])
end
s = dir(fullfile(basepath,fileNameRaw));

duration = s.bytes/(2*nChannels*sr);
rawData = memmapfile(fullfile(basepath,fileNameRaw),'Format','int16','writable',false);

% Fit exponential
g = fittype('a*exp(-x/b)+c','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c'});

spkTmp = wfWin_sec/1.8 + rand(nPull,1)*(duration-2*wfWin_sec/1.8);

spkTmp = round(sr * spkTmp(:));
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
wf2 = mean(wf,3);

wfF_mean = mean(wfF,3)';
wfF_std = std(wfF,0,3)';

time = ([-ceil(wfWin_sec/2*sr)*(1/sr):1/sr:(ceil(wfWin_sec/2*sr)-1)*(1/sr)])*1000;

wfF_std2 = mean(wfF_std);
wfF_range = range(wfF_mean);
newBadChannels = find(wfF_std2 > noiseStdThreshold);
newBadChannels2 = find(wfF_range > noiseRangeThreshold);
newBadChannels = unique([newBadChannels,newBadChannels2]);
session.channelTags.Bad.channels = unique([badChannels,newBadChannels]);

% Saving noiselevel to mat file
if saveMat
    noiseLevel.std = wfF_std2';
    noiseLevel.range = wfF_range';
    noiseLevel.units = 'uV';
    noiseLevel.metric = 'std';
    noiseLevel.channel = [1:numel(wfF_std2)]';
    noiseLevel.processinginfo.function = 'getBadChannelsFromDat';
    noiseLevel.processinginfo.date = now;
    noiseLevel.processinginfo.version = 1;
    try
        noiseLevel.processinginfo.username = char(java.lang.System.getProperty('user.name'));
        noiseLevel.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
    end
    saveStruct(noiseLevel,'channelInfo','session',session);
end

% Plots
if showFig
    fig1 = figure('name',[basename,' ',extraLabel]);
    subplot(3,2,1)
    plot(time,wfF_mean), ylabel('Mean (uV)')
    if ~isempty(badChannels); title(['Existing bad channels: ' num2str(badChannels)]); else; title('No existing bad channels'); end
    subplot(3,2,2)
    plot(time,wfF_std), ylabel('std (uV)')
    subplot(3,2,3)
    plot((range(wfF_mean))), hold on, plot(badChannels,(range(wfF_mean(:,badChannels))),'or'), plot(newBadChannels,(range(wfF_mean(:,newBadChannels))),'xr')
    if ~isempty(newBadChannels); title(['Bad channels detected: ' num2str(newBadChannels)]); else; title('No new bad channels detected'); end
    subplot(3,2,4)
    plot((mean(wfF_std))), hold on, plot(badChannels,(mean(wfF_std(:,badChannels))),'or'), plot(newBadChannels,(mean(wfF_std(:,newBadChannels))),'xr')
    subplot(3,2,5)
    plot(noiseLevel.range,noiseLevel.std,'.b'), xlabel('range of mean'), ylabel('mean of std'), hold on
    plot(noiseLevel.range(badChannels),noiseLevel.std(badChannels),'or')
    plot(noiseLevel.range(newBadChannels),noiseLevel.std(newBadChannels),'xr')
    if saveFig && ishandle(fig1)
        % Saving figure
        saveFig1.path = 1; saveFig1.fileFormat = 1; saveFig1.save = 1;
        ce_savefigure(fig1,basepath,[basename, '.getBadChannelsFromDat'],0,saveFig1)
    end
end
clear wf wfF wf2 wfF2
clear rawData
end

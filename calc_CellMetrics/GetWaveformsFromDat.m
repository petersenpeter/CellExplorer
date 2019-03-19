function spikes = GetWaveformsFromDat(spikes,sessionInfo)
% get waveforms
nPull = 1000; % number of spikes to pull out
wfWin = 0.008; % Larger size of waveform windows for filterning
filtFreq = 500;
sr = sessionInfo.rates.wideband;
hpFilt = designfilt('highpassiir','FilterOrder',3, 'PassbandFrequency',filtFreq,'PassbandRipple',0.1, 'SampleRate',sr);

fWave = waitbar(0,'Getting waveforms...');
wfWin = round((wfWin * sr)/2);
wfWinFilt = round(0.002*sr);

for ii = 1 : size(spikes.times,2)
    spkTmp = spikes.times{ii};
    if length(spkTmp) > nPull
        spkTmp = spkTmp(randperm(length(spkTmp)));
        spkTmp = spkTmp(1:nPull);
    end
    wf = [];
    for jj = 1 : length(spkTmp)
        wf = cat(3,wf,bz_LoadBinary([sessionInfo.session.name '.dat'],'offset',spikes.ts{ii}(jj) - (wfWin),...
            'samples',(wfWin * 2)+1,'frequency',sessionInfo.rates.wideband,'nChannels',sessionInfo.nChannels));
    end
    wf = mean(wf,3);
    for jj = 1 : size(wf,2)
        wfF(:,jj) = filtfilt(hpFilt,wf(:,jj));
    end
    [~, spikes.maxWaveformCh(ii)] = max(abs(wfF(wfWin,:)));
    rawWaveform{ii} = detrend(wf(:,spikes.maxWaveformCh(ii)) - mean(wf(:,spikes.maxWaveformCh(ii))));
    filtWaveform{ii} = wfF(:,spikes.maxWaveformCh(ii)) - mean(wfF(:,spikes.maxWaveformCh(ii)));
    
    spikes.rawWaveform{ii} = rawWaveform{ii}(wfWin - wfWinFilt : wfWin + wfWinFilt); % keep only +- 1ms of waveform
    spikes.filtWaveform{ii} = filtWaveform{ii}(wfWin - wfWinFilt : wfWin + wfWinFilt);
    
    spikes.PeakVoltage(ii) = max(max(spikes.filtWaveform{ii}) - min(spikes.filtWaveform{ii}));
    
    % TODO Waveform std
%     spikes.filtWaveform_std{ii} = std();
    
    waitbar(ii/size(spikes.times,2),fWave,'Pulling out waveforms...');
end

close(fWave)

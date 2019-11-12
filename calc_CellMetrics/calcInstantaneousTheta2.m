function [InstantaneousTheta] = calcInstantaneousTheta2(session,varargin)
% Calculates the instantaneous theta with phase and power
% By Peter Petersen
% Last edited: 18-08-2019

p = inputParser;
addParameter(p,'forceReload',false,@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'saveAs','InstantaneousTheta',@isstr);

parse(p,varargin{:})

forceReload = p.Results.forceReload;
saveMat = p.Results.saveMat;
saveAs = p.Results.saveAs;

saveAsFullfile = fullfile(session.general.basePath,[session.general.baseName,'.',saveAs,'.lfp.mat']);

if ~exist([session.general.baseName, '.lfp']) && ~exist(saveAsFullfile,'file') || forceReload
    disp('Creating lfp file')
    bz_LFPfromDat(pwd,'noPrompts',true)
end

if ~forceReload && exist(saveAsFullfile,'file')
    disp('Loading existing InstantaneousTheta.lfp.mat file')
    InstantaneousTheta = [];
    load(saveAsFullfile)
    if isempty(InstantaneousTheta) || isnumeric(InstantaneousTheta.ThetaInstantFreq)
        disp(['InstantaneousTheta not calculated correctly. Hold on'])
        InstantaneousTheta = [];
        forceReload = true;
    elseif isempty(InstantaneousTheta) || size(InstantaneousTheta.ThetaInstantFreq,2)<recording.ch_theta || isempty(InstantaneousTheta.ThetaInstantFreq{session.channelTags.Theta.channels})
        forceReload = true;
        disp(['Selected channel not calculated yet. Hold on'])
    end
end

% Calculating the instantaneous theta frequency
if ~exist(saveAsFullfile,'file') || forceReload
    srLfp = session.extracellular.srLfp;
    disp('Calculating the instantaneous theta frequency')
    signal = session.extracellular.leastSignificantBit * double(LoadBinary([session.general.baseName '.lfp'],'nChannels',session.extracellular.nChannels,'channels',session.channelTags.Theta.channels,'precision','int16','frequency',srLfp)); % ,'start',start,'duration',duration
    Fpass = [4,10];
    Wn_theta = [Fpass(1)/(srLfp/2) Fpass(2)/(srLfp/2)]; % normalized by the nyquist frequency
    [btheta,atheta] = butter(3,Wn_theta);
    signal_filtered = filtfilt(btheta,atheta,signal)';
    hilbert1 = hilbert(signal_filtered);
    signal_phase = atan2(imag(hilbert1), real(hilbert1));
    signal_phase2 = unwrap(signal_phase);
%     ThetaInstantFreq = 1250/(2*pi)*diff(signal_phase2);
    ThetaInstantFreq = (srLfp)./diff(find(diff(signal_phase>0)==1));
    ThetaInstantTime = cumsum(diff(find(diff(signal_phase>0)==1)))/srLfp;
    ThetaInstantFreq(find(ThetaInstantFreq>11)) = nan;
    ThetaInstantFreq = nanconv(ThetaInstantFreq,gauss(7,1)/sum(gauss(7,1)),'edge');
    
    % Theta frequency
    freqlist = [4:0.1:10];
    wt = spectrogram(signal_filtered,srLfp,2*srLfp/10,freqlist,srLfp);
    wt = medfilt2(abs(wt),[2,10]);
    h = 1/10*ones(10,1);
    H= h*h';
    wt = filter2(H,wt);
    [~,index] = max(wt);
    signal_freq = freqlist(index);
    signal_power = max(wt);
    
    %max(mean(wt2(:,indexes),2))
    %signal_freq = sr_eeg/(2*pi)*diff(signal_phase2);
    InstantaneousTheta.ThetaInstantFreq{recording.ch_theta} = ThetaInstantFreq;
    InstantaneousTheta.timestamps = ThetaInstantTime;
    InstantaneousTheta.signal_phase{recording.ch_theta} = signal_phase;
    InstantaneousTheta.signal_phase2{recording.ch_theta} = signal_phase2;
    InstantaneousTheta.signal_freq{recording.ch_theta} = signal_freq;
    InstantaneousTheta.signal_power{recording.ch_theta} = signal_power;
    InstantaneousTheta.signal_time = wt_t;
    if saveMat
        save(saveAsFullfile,'InstantaneousTheta')
        disp('InstantaneousTheta saved to disk')
    end
    clear signal signal_filtered
    if saveMat
        save(saveAsFullfile,'InstantaneousTheta')
    end
    clear signal signal_filtered
end

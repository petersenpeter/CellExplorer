function InstantaneousTheta = calcInstantaneousTheta2(session,varargin)
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

saveAsFullfile = fullfile(session.general.basePath,[session.general.name,'.',saveAs,'.lfp.mat']);

ch_theta = session.channelTags.Theta.channels;

if ~forceReload && exist(saveAsFullfile,'file')
    disp('Loading existing InstantaneousTheta.lfp.mat file')
    InstantaneousTheta = [];
    load(saveAsFullfile)
    if isempty(InstantaneousTheta) || isnumeric(InstantaneousTheta.ThetaInstantFreq)
        disp(['InstantaneousTheta not calculated correctly. Hold on'])
        InstantaneousTheta = [];
        forceReload = true;
    elseif isempty(InstantaneousTheta) || size(InstantaneousTheta.ThetaInstantFreq,2) < ch_theta || isempty(InstantaneousTheta.ThetaInstantFreq{ch_theta})
        forceReload = true;
        disp(['Selected channel not calculated yet. Hold on'])
    end
end

% Calculating the instantaneous theta frequency
if ~exist(saveAsFullfile,'file') || forceReload
    if ~exist(fullfile(session.general.basePath,[session.general.name, '.lfp']),'file')
        disp('Creating lfp file')
        ce_LFPfromDat(session)
%         bz_LFPfromDat(session.general.basePath)
    end
    srLfp = session.extracellular.srLfp;
    disp('Calculating the instantaneous theta frequency')
    signal = session.extracellular.leastSignificantBit * double(LoadBinary(fullfile(session.general.basePath,[session.general.name '.lfp']),'nChannels',session.extracellular.nChannels,'channels',ch_theta,'precision','int16','frequency',srLfp)); % ,'start',start,'duration',duration
    Fpass = [4,11];
    Wn_theta = [Fpass(1)/(srLfp/2) Fpass(2)/(srLfp/2)]; % normalized by the nyquist frequency
    [btheta,atheta] = butter(3,Wn_theta);
    signal_filtered = filtfilt(btheta,atheta,signal)';
    hilbert1 = hilbert(signal_filtered);
    signal_phase = atan2(imag(hilbert1), real(hilbert1));
    signal_phase2 = unwrap(signal_phase);
%     ThetaInstantFreq = 1250/(2*pi)*diff(signal_phase2);
    ThetaInstantFreq = (srLfp)./diff(find(diff(signal_phase>0)==1));
    ThetaInstantTime = cumsum(diff(find(diff(signal_phase>0)==1)))/srLfp;
    ThetaInstantFreq(ThetaInstantFreq>12) = nan;
    ThetaInstantFreq = nanconv(ThetaInstantFreq,ce_gausswin(7)/sum(ce_gausswin(7)),'edge');
    
    % Theta frequency
    freqlist = [4:0.1:11];
    [wt,w,wt_t] = spectrogram(signal_filtered,srLfp,2*srLfp/10,freqlist,srLfp);
    wt = medfilt2(abs(wt),[2,10]);
    h = 1/10*ones(10,1);
    H= h*h';
    wt = filter2(H,wt);
    [~,index] = max(wt);
    signal_freq = freqlist(index);
    signal_power = max(wt);
    
    %max(mean(wt2(:,indexes),2))
    %signal_freq = sr_eeg/(2*pi)*diff(signal_phase2);
    InstantaneousTheta.ThetaInstantFreq{ch_theta} = ThetaInstantFreq;
    InstantaneousTheta.timestamps = ThetaInstantTime;
    InstantaneousTheta.signal_phase{ch_theta} = signal_phase;
    InstantaneousTheta.signal_phase2{ch_theta} = signal_phase2;
    InstantaneousTheta.signal_freq{ch_theta} = signal_freq;
    InstantaneousTheta.signal_power{ch_theta} = signal_power;
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

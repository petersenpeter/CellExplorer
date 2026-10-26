function theta = instantaneousTheta(signal, srLfp, channel)
%INSTANTANEOUSTHETA Original theta formulas, without file access or plotting.
% signal is a column of calibrated LFP values; channel is one based.
Fpass = [4,11];
freqlist = Fpass(1):0.1:Fpass(2);
Wn_theta = [Fpass(1)/(srLfp/2) Fpass(2)/(srLfp/2)];
[btheta,atheta] = butter(3,Wn_theta);
signal_filtered = filtfilt(btheta,atheta,signal)';
hilbert1 = hilbert(signal_filtered);
signal_phase = atan2(imag(hilbert1), real(hilbert1));
signal_phase2 = unwrap(signal_phase);
ThetaInstantFreq = srLfp./diff(find(diff(signal_phase>0)==1));
ThetaInstantTime = cumsum(diff(find(diff(signal_phase>0)==1)))/srLfp;
ThetaInstantFreq(ThetaInstantFreq>12) = nan;
ThetaInstantFreq = nanconv(ThetaInstantFreq,ce_gausswin(7)/sum(ce_gausswin(7)),'edge');
[wt,~,wt_t] = spectrogram(signal_filtered,srLfp,2*srLfp/10,freqlist,srLfp);
wt = medfilt2(abs(wt),[2,10]);
h = 1/10*ones(10,1);
H = h*h';
wt = filter2(H,wt);
[~,index] = max(wt);
theta.ThetaInstantFreq{channel} = ThetaInstantFreq;
theta.timestamps = ThetaInstantTime;
theta.signal_phase{channel} = signal_phase;
theta.signal_phase2{channel} = signal_phase2;
theta.signal_freq{channel} = freqlist(index);
theta.signal_power{channel} = max(wt);
theta.signal_time = wt_t;
end

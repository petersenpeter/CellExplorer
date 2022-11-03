function peakFrequency = getRipplePeakFrequency(filtered,timestamps)

filtered = filtered(:)';
timestamps = timestamps(:)';
% Compute instantaneous phase and amplitude
h = hilbert(double(filtered));
phase = angle(h);
amplitude = abs(h);
unwrapped = unwrap(phase);

% Compute instantaneous frequency
frequency = diff(medfilt1(unwrapped,12*16))./diff(timestamps);
frequency = frequency/(2*pi);

% Compute ripple map
% [r,i] = Sync([timestamps filtered],ripples.peaks,'durations',durations);
% maps.ripples = SyncMap(r,i,'durations',durations,'nbins',nBins,'smooth',0);

% Compute frequency Map
% [f,i] = Sync([timestamps frequency],ripples.peaks,'durations',durations);
% frequency = SyncMap(f,i,'durations',durations,'nbins',nBins,'smooth',0);

centerBin = find(timestamps==0,1);
peakFrequency = frequency(:,centerBin);

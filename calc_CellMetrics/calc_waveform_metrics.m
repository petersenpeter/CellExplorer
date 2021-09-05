function waveform_metrics = calc_waveform_metrics(waveforms,sr_in)
% Extracts waveform metrics
%
% INPUT:
% waveforms structure
%
% OUTPUT:
% waveform_metrics
% Metrics for the waveforms: peaktoTrough, troughtoPeak,
% derivative_TroughtoPeak, peakA, peakB, ab_ratio, trough

% By Peter Petersen
% petersen.peter@gmail.com

filtWaveform = waveforms.filtWaveform;
timeWaveform = waveforms.timeWaveform{1};
timeWaveform_span = length(timeWaveform) * mean(diff(timeWaveform));
% sr = 1/mean(diff(timeWaveform))*1000;
oversampling = ceil(100000/sr_in);
sr = oversampling * sr_in;
timeWaveform = interp1(timeWaveform,timeWaveform,timeWaveform(1):mean(diff(timeWaveform))/oversampling:timeWaveform(end),'spline');
zero_idx = find(timeWaveform>=0,1);
trough_interval = [find(timeWaveform>=-0.25,1),find(timeWaveform>=0.25,1)]; % -10/40:10/40 =>
trough_interval_1stDerivative = [find(timeWaveform>=-0.50,1),find(timeWaveform>=0.25,1)]; % -20/40:10/40 =>
trough_interval_2stDerivative = [find(timeWaveform>=-0.625,1),find(timeWaveform>=-0.125,1)]; % 7:27 => -25/40:-5/40 => -0.625:-0.125
idx_45 = find(timeWaveform>=0.325,1);
idx_49 = find(timeWaveform>=0.425,1);
idx_3 = find(timeWaveform>= -0.725,1);
idx_6 = find(timeWaveform>= -0.650,1);
idx_9 = find(timeWaveform>= -0.575,1);
idx_end4 = find(timeWaveform>= 0.700,1);
idx_end2 = find(timeWaveform>= 0.750,1);
waveform_metrics = [];
m = 0;
n = 0;
wave = [];
wave_diff = [];
wave_diff2 = [];
wave_cut = [];
wave_align = [];
wave_diff_cut = [];

t_before = [];
t_after = [];
peakA = [];
peakB = [];
trough = [];
width1 = [];
t_after_diff = [];
Itest = [];
Itest2 = [];
figure
subplot(2,2,[1,3]), hold on


for m = 1:length(filtWaveform)
    if ~any(isnan(filtWaveform{m}))
        wave = interp1(waveforms.timeWaveform{1},zscore(filtWaveform{m}),timeWaveform(1):mean(diff(timeWaveform)):timeWaveform(end),'spline');
        waveform_metrics.polarity(m) = mean(wave(trough_interval(1):trough_interval(2))) - mean(wave([1:trough_interval(1),trough_interval(2):end]));
        if waveform_metrics.polarity(m) > 0
            wave = -wave;
        end
        wave_diff{m} = diff(wave);
        wave_diff2{m} = diff(wave,2);
        [MIN2,I2] = min(wave(trough_interval(1):trough_interval(2))); % trough_interval
        [MIN2_diff,I2_diff] = min(wave_diff{m}(trough_interval_1stDerivative(1):trough_interval_1stDerivative(2))); % 1st deriv
        [MIN2_diff2,I2_diff2] = min(wave_diff2{m}(trough_interval_2stDerivative(1):trough_interval_2stDerivative(2))); % 2nd deriv, trough_interval_2stDerivative
        [MAX3,I3] = max(wave(1:I2+trough_interval(1)-1));
        [MAX4,I4] = max(wave(I2+trough_interval(1):end));
        [MAX4_diff,I4_diff] = max(wave_diff{m}(I2_diff+trough_interval_1stDerivative(1):end));
        t_before(m) = I2+trough_interval(1)-1-I3;
        t_after(m) = I4;
        t_after_diff(m) = I4_diff;
        peakA(m) = MAX3;
        peakB(m) = MAX4;
        trough(m) = MIN2;
        Itest(m) = I2;
        Itest2(m) = length(wave)-(idx_45+I2);
        subplot(3,2,1), hold on
        plot([-(I2+trough_interval(1)-1)+1:1:0,1:1:(length(wave)-(I2+trough_interval(1)-1))]/sr*1000,wave,'Color',[0,0,0,0.1],'linewidth',2), axis tight
        plot(0,MIN2,'.b') % Min
        plot((-(I2+trough_interval(1)-1)+I3)/sr*1000,MAX3,'.r') % Max
        plot(I4/sr*1000,MAX4,'.g') % Max
        title('Waveforms'),xlabel('Time (ms)'),ylabel('Z-scored')
        indexes = I3:I2+I4+trough_interval(1)-1;
        
        subplot(3,2,3), hold on
        plot([-(I2_diff+trough_interval_1stDerivative(1)-1)+1:1:0,1:1:(length(wave_diff{m})-(I2_diff+trough_interval_1stDerivative(1)-1))]/sr*1000,wave_diff{m},'Color',[0,0,0,0.05],'linewidth',2), axis tight
        plot(I4_diff/sr*1000,MAX4_diff,'.m') % Max
        title('Waveforms (1st derivative)'),xlabel('Time (ms)'),ylabel('Z-scored')
        
        subplot(3,2,5), hold on
        plot([-(I2_diff2+idx_6)+1:1:0,1:1:(length(wave_diff2{m})-(I2_diff2+idx_6))]/sr*1000,wave_diff2{m},'Color',[0,0,0,0.05],'linewidth',2), axis tight
        title('Waveforms (2nd derivative'),xlabel('Time (ms)'),ylabel('Z-scored')
    else
        t_before(m) = nan;
        t_after(m) = nan;
        t_after_diff(m) = nan;
        peakA(m) = nan;
        peakB(m) = nan;
        trough(m) = nan;
        waveform_metrics.polarity(m) = nan;
    end
end
waveform_metrics.peaktoTrough = t_before/sr*1000;
waveform_metrics.troughtoPeak = t_after/sr*1000;
waveform_metrics.derivative_TroughtoPeak = t_after_diff/sr*1000;
waveform_metrics.peakA = peakA;
waveform_metrics.peakB = peakB;
waveform_metrics.ab_ratio = (peakB-peakA)./(peakA+peakB);
waveform_metrics.trough = trough;

axis tight
subplot(6,2,2)
hist(waveform_metrics.peaktoTrough,0:0.0250:0.90);
h = findobj(gca, 'Type','patch');
set(h(1), 'FaceColor','r')
title('Peak-to-Trough'), axis tight

subplot(6,2,4)
hist(waveform_metrics.troughtoPeak,0:0.0250:1);
h = findobj(gca, 'Type','patch');
set(h(1), 'FaceColor','g')
title('Trough-to-Peak'), axis tight

subplot(6,2,6)
hist((t_before+t_after)/sr*1000,0:0.0250:1.25);
h = findobj(gca, 'Type','patch');
set(h(1), 'FaceColor','y')
title('Peak-to-Peak (red + green)'), axis tight

subplot(6,2,8)
hist(waveform_metrics.derivative_TroughtoPeak,0:0.0250:0.8);
h = findobj(gca, 'Type','patch');
set(h(1), 'FaceColor','m')
title('Trough-to-Peak (1st derivative)'), axis tight

subplot(6,2,10)
hist(abs(peakA./trough),[0:0.04:2]);
title('peak/trough (markers: red/blue))'), axis tight

subplot(6,2,12)
hist(waveform_metrics.ab_ratio,30);
title('AB ratio (markers: red/green))'), axis tight
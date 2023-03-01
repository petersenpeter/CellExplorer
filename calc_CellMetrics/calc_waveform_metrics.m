function waveform_metrics = calc_waveform_metrics(spikes,sr_in,varargin)
    % Extracts waveform metrics
    %
    % INPUT:
    % spikes structure
    %   .filtWaveform : Waveforms (in µV; cell-array [1x nCells])
    % 	.timeWaveform : Time axis (in ms; cell-array [1x nCells])
    %
    % OUTPUT:
    % waveform_metrics
    % Metrics for the waveforms: peaktoTrough, troughtoPeak,
    % derivative_TroughtoPeak, peakA, peakB, ab_ratio, trough
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    
    p = inputParser;
    addParameter(p,'showFigures',true,@islogical);
    parse(p,varargin{:})
    
    filtWaveform = spikes.filtWaveform;
    timeWaveform = spikes.timeWaveform{1};
    timeWaveform_span = length(timeWaveform) * mean(diff(timeWaveform));
    % sr = 1/mean(diff(timeWaveform))*1000;
    oversampling = ceil(100000/sr_in);
    sr = oversampling * sr_in;
    timeWaveform = timeWaveform(1):mean(diff(timeWaveform))/oversampling:timeWaveform(end);
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
    
    peaktoTrough = [];
    troughtoPeak = [];
    peakA = [];
    peakB = [];
    trough = [];
    width1 = [];
    derivative_TroughtoPeak = [];
    Itest = [];
    Itest2 = [];
    
    if p.Results.showFigures
        fig = figure('Name','Waveform metrics','pos',[50, 50, 1000, 700],'visible','off');
        movegui(fig,'center')
        subplot(2,2,[1,3]), hold on
    end
    
    
    for m = 1:length(filtWaveform)
        if ~any(isnan(filtWaveform{m}))
            wave = interp1(spikes.timeWaveform{1},zscore(filtWaveform{m}),timeWaveform,'spline');
            waveform_metrics.polarity(m) = mean(wave(trough_interval(1):trough_interval(2))) - mean(wave([1:trough_interval(1),trough_interval(2):end]));
            if waveform_metrics.polarity(m) > 0
                wave = -wave;
            end
            
            % Trough
            [MIN2,I2] = min(wave(trough_interval(1):trough_interval(2))); % trough_interval
            trough_idx = I2+trough_interval(1);
            
            % Trough to peak (I4)
            [MAX4,troughtoPeak_idx] = max(wave(trough_idx:end));
            troughtoPeak(m) = troughtoPeak_idx/sr*1000;
            
            % Peak to Trough
            [MAX3,I3] = max(wave(1:trough_idx-1));
            peaktoTrough(m) = (trough_idx-1-I3)/sr*1000;
            
            % Waveform derivative
            wave_diff{m} = diff(wave);
            wave_diff2{m} = diff(wave,2);            
            [MIN2_diff,I2_diff] = min(wave_diff{m}(trough_interval_1stDerivative(1):trough_interval_1stDerivative(2))); % 1st deriv
            [MIN2_diff2,I2_diff2] = min(wave_diff2{m}(trough_interval_2stDerivative(1):trough_interval_2stDerivative(2))); % 2nd deriv, trough_interval_2stDerivative
            
            % derivative_TroughtoPeak
            [MAX4_diff,I4_diff] = max(wave_diff{m}(I2_diff+trough_interval_1stDerivative(1):end));
            derivative_TroughtoPeak(m) = I4_diff/sr*1000;
            
            % Peak values
            peakA(m) = MAX3;
            peakB(m) = MAX4;
            trough(m) = MIN2;
            Itest(m) = I2;
            Itest2(m) = length(wave)-(idx_45+I2);
            
            indexes = I3:I2+troughtoPeak_idx+trough_interval(1)-1;
            if p.Results.showFigures
                subplot(3,2,1), hold on
                plot([-(trough_idx-1)+1:1:0,1:1:(length(wave)-(trough_idx-1))]/sr*1000,wave,'Color',[0,0,0,0.1],'linewidth',2), axis tight
                plot(0,MIN2,'.b') % Min
                plot((-(trough_idx-1)+I3)/sr*1000,MAX3,'.r') % Max
                plot(troughtoPeak_idx/sr*1000,MAX4,'.g') % Max
                title('Waveforms'),xlabel('Time (ms)'),ylabel('Z-scored')
                
                subplot(3,2,3), hold on
                plot([-(I2_diff+trough_interval_1stDerivative(1)-1)+1:1:0,1:1:(length(wave_diff{m})-(I2_diff+trough_interval_1stDerivative(1)-1))]/sr*1000,wave_diff{m},'Color',[0,0,0,0.05],'linewidth',2), axis tight
                plot(I4_diff/sr*1000,MAX4_diff,'.m') % Max
                title('1st derivative waveforms'),xlabel('Time (ms)'),ylabel('Z-scored')
                
                subplot(3,2,5), hold on
                plot([-(I2_diff2+idx_6)+1:1:0,1:1:(length(wave_diff2{m})-(I2_diff2+idx_6))]/sr*1000,wave_diff2{m},'Color',[0,0,0,0.05],'linewidth',2), axis tight
                title('2nd derivative waveforms'),xlabel('Time (ms)'),ylabel('Z-scored')
            end
        else
            peaktoTrough(m) = nan;
            troughtoPeak(m) = nan;
            derivative_TroughtoPeak(m) = nan;
            peakA(m) = nan;
            peakB(m) = nan;
            trough(m) = nan;
        end
    end
    waveform_metrics.peaktoTrough = peaktoTrough;
    waveform_metrics.troughtoPeak = troughtoPeak;
    waveform_metrics.derivative_TroughtoPeak = derivative_TroughtoPeak;
    waveform_metrics.peakA = peakA;
    waveform_metrics.peakB = peakB;
    waveform_metrics.ab_ratio = (peakB-peakA)./(peakA+peakB);
    waveform_metrics.trough = trough;
    
    if p.Results.showFigures
        axis tight
        subplot(6,2,2)
        hist(waveform_metrics.peaktoTrough,0:0.0250:max(waveform_metrics.peaktoTrough));
        h = findobj(gca, 'Type','patch');
        set(h(1), 'FaceColor','r')
        title('Peak-to-Trough'), axis tight
        
        subplot(6,2,4)
        hist(waveform_metrics.troughtoPeak,0:0.0250:max(waveform_metrics.troughtoPeak));
        h = findobj(gca, 'Type','patch');
        set(h(1), 'FaceColor','g')
        title('Trough-to-Peak'), axis tight
        
        subplot(6,2,6)
        hist(peaktoTrough+troughtoPeak,0:0.0250:max(peaktoTrough+troughtoPeak));
        h = findobj(gca, 'Type','patch');
        set(h(1), 'FaceColor','y')
        title('Peak-to-Peak'), axis tight
        
        subplot(6,2,8)
        hist(waveform_metrics.derivative_TroughtoPeak,0:0.01:max(waveform_metrics.derivative_TroughtoPeak));
        h = findobj(gca, 'Type','patch');
        set(h(1), 'FaceColor','m')
        title('Trough-to-Peak (1st derivative)'), axis tight
        
        subplot(6,2,10)
        hist(abs(peakA./trough),[0:0.04:2]);
        title('Peak/Trough'), axis tight
        
        subplot(6,2,12)
        hist(waveform_metrics.ab_ratio,40);
        title('AB-ratio'), axis tight
        
        set(fig,'visible','on')
    end
end
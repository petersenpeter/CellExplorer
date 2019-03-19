function waveform_metrics = calc_waveform_metrics(SpikeWaveforms,sr_in)
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
sr = 40000;

for m = 1:length(SpikeWaveforms)
    if sr_in < sr
        wave = interp1([1:length(SpikeWaveforms{m})],zscore(SpikeWaveforms{m}),[1:0.5:32,32],'spline');
    else
        wave = SpikeWaveforms{m};
    end
    wave_diff{m} = diff(wave);
    wave_diff2{m} = diff(wave,2);
    [MIN2,I2] = min(wave(22:42));
    [MIN2_diff,I2_diff] = min(wave_diff{m}(12:42));
    [MIN2_diff2,I2_diff2] = min(wave_diff2{m}(7:27));
    [MAX3,I3] = max(wave(1:I2+21));
    [MAX4,I4] = max(wave(I2+22:end));
    [MAX4_diff,I4_diff] = max(wave_diff{m}(I2_diff+12:end));
    t_before(m) = I2+21-I3;
    t_after(m) = I4;
    t_after_diff(m) = I4_diff;
    peakA(m) = MAX3;
    peakB(m) = MAX4;
    trough(m) = MIN2;
    Itest(m) = I2;
    Itest2(m) = length(wave)-(45+I2);
    subplot(3,2,1), hold on
    plot([-(I2+21)+1:1:0,1:1:(length(wave)-(I2+21))]/sr*1000,wave,'Color',[0,0,0,0.1],'linewidth',2), axis tight
    plot(0,MIN2,'.b') % Min
    plot((-(I2+21)+I3)/sr*1000,MAX3,'.r') % Max
    plot(I4/sr*1000,MAX4,'.g') % Max
    title('Waveforms'),xlabel('Time (ms)'),ylabel('Z-scored')
    indexes = I3:I2+21+I4;

    subplot(3,2,3), hold on
    plot([-(I2_diff+11)+1:1:0,1:1:(length(wave_diff{m})-(I2_diff+11))]/sr*1000,wave_diff{m},'Color',[0,0,0,0.05],'linewidth',2), axis tight
    plot(I4_diff/sr*1000,MAX4_diff,'.m') % Max
    title('Waveforms (1st derivative)'),xlabel('Time (ms)'),ylabel('Z-scored')

    subplot(3,2,5), hold on
    plot([-(I2_diff2+6)+1:1:0,1:1:(length(wave_diff2{m})-(I2_diff2+6))]/sr*1000,wave_diff2{m},'Color',[0,0,0,0.05],'linewidth',2), axis tight
    title('Waveforms (2nd derivative'),xlabel('Time (ms)'),ylabel('Z-scored')
    
    switch length(wave)
        case 64
            n = n+1;
            wave_cut(n,:) = wave(3:end-2);
            wave_diff_cut(n,:) = wave_diff{m}(3:end-2);
            if I2+45-length(wave)>=0
                temp = I2+45-length(wave)
                wave_align(n,:) = wave(I2-temp:I2+45-temp);
            else
                wave_align(n,:) = wave(I2:I2+45);
            end
        case 72
            n = n+1;
            wave_cut(n,:) = wave(9:end-4);
            wave_diff_cut(n,:) = wave_diff{m}(9:end-4);
            wave_align(n,:) = wave(I2:I2+49);
        case 60
            n = n+1;
            wave_cut(n,:) = wave;
            wave_diff_cut(n,:) = wave_diff{m};
            wave_align(n,:) = wave(I2:I2+49);
            % disp('Lenght of waveform is too short (60)')
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
hist(t_before/sr*1000,[1:25]/sr*1000);
h = findobj(gca, 'Type','patch');
set(h(1), 'FaceColor','r')
title('Peak-to-Trough'), axis tight

subplot(6,2,4)
hist(t_after/sr*1000,[1:40]/sr*1000);
h = findobj(gca, 'Type','patch');
set(h(1), 'FaceColor','g')
title('Trough-to-Peak'), axis tight

subplot(6,2,6)
hist((t_before+t_after)/sr*1000,[1:50]/sr*1000);
h = findobj(gca, 'Type','patch');
set(h(1), 'FaceColor','y')
title('Peak-to-Peak (red + green)'), axis tight

subplot(6,2,8)
hist(t_after_diff/sr*1000,[1:25]/sr*1000);
h = findobj(gca, 'Type','patch');
set(h(1), 'FaceColor','m')
title('Trough-to-Peak (1st derivative)'), axis tight

subplot(6,2,10)
hist(abs(peakA./trough),[0:0.04:2]);
title('peak/trough (markers: red/blue))'), axis tight

subplot(6,2,12)
hist((peakB-peakA)./(peakA+peakB),30);
title('AB ratio (markers: red/green))'), axis tight


[pc,score,latent,tsquare] = pca(wave_align);

% figure
% scatter3(score(:,1),score(:,2),score(:,3),10,[0,0,0])
% xlabel('X'),ylabel('Y'),zlabel('Z')

% K-mean clustering
opts = statset('Display','final');
klusters = 3;
colors = {'r','b','g'};
colors2 = [1,0,0,0.1;0,1,0,0.1;0,0,1,0.1]';
[idx,C] = kmeans(score(:,1:3),klusters,'Distance','cityblock',...
    'Replicates',5,'Options',opts);
waveform_metrics.klusters = idx';

figure
subplot(2,2,1:2)
for i = 1:klusters
    plot(([1:size(wave_align,2)]-22)/sr*1000,wave_align(idx==i,:)','Color',colors2(:,i),'linewidth',2), hold on
end
xlabel('Time (ms)'),ylabel('Amplitude (mu V)'),title 'Average Waveforms', axis tight

subplot(2,2,3)
for i = 1:klusters
scatter3(score(idx==i,1)',score(idx==i,2)',score(idx==i,3)',20,colors{i}), hold on
end
plot3(C(:,1),C(:,2),C(:,3),'kx','MarkerSize',15,'LineWidth',3), title 'PCA Analysis', hold off
xlabel('PC1'),ylabel('PC2'),zlabel('PC3'),axis tight

subplot(2,2,4)
for i = 1:klusters
    scatter3(t_after(idx==i),t_after_diff(idx==i),abs(peakA(idx==i)./trough(idx==i)),20,colors{i}), hold on
end
title 'Waveform feature space', xlabel('t_{after}'),ylabel('t_{after diff}'),zlabel('peak/trough'),axis tight

plots_datasets = [t_before;t_after;(t_before+t_after);t_after_diff;10*abs(peakA./trough)];
plot_labels = {'t before';'t after';'t before + t after';'t_{after diff}';'peak/trough'};
plots_sets = [1,2;2,3;2,4;2,5];
figure
for i = 1:4
    X1 = plots_datasets(plots_sets(i,1),:);
    Y1 = plots_datasets(plots_sets(i,2),:);
    Bx = [min(X1):1:max(X1)+1]-0.5;
    By = [min(Y1):1:max(Y1)+1]-0.5;
    N = hist2d([X1;Y1]',Bx,By);
    subplot(2,2,i)
    surf(Bx(1:end-1)/sr*1000,By(1:end-1)/sr*1000,N','EdgeColor','None'), hold on
    view(0,90)
    axis tight
    caxis([0 max(max(N))])
    xlabel([plot_labels{plots_sets(i,1)} ' (ms)'])
    ylabel([plot_labels{plots_sets(i,2)} ' (ms)'])
end

% Waveforms
[pc,score1,latent,tsquare] = pca(wave_align);
figure
subplot(2,3,1)
plot(wave_align','Color',[0,0,0,0.1],'linewidth',2), title('Waveforms'), axis tight
subplot(2,3,4)
scatter3(score1(:,1),score1(:,2),score1(:,3),10,[0,0,0])
xlabel('X'),ylabel('Y'),zlabel('Z')

% 1. derivative
[pc,score2,latent,tsquare] = pca(diff(wave_align')');
subplot(2,3,2)
plot(diff(wave_align'),'Color',[0,0,0,0.1],'linewidth',2), title('First derivative'), axis tight
subplot(2,3,5)
scatter3(score2(:,1),score2(:,2),score2(:,3),10,[0,0,0])
xlabel('X'),ylabel('Y'),zlabel('Z')

% 2. derivative
[pc,score3,latent,tsquare] = pca(diff(wave_align',2)');
subplot(2,3,3)
plot(diff(wave_align',2),'Color',[0,0,0,0.1],'linewidth',2), title('Second derivative'), axis tight
subplot(2,3,6)
scatter3(score3(:,1),score3(:,2),score3(:,3),10,[0,0,0])
xlabel('X'),ylabel('Y'),zlabel('Z')

waveform_metrics.score1 = score1(:,1:3)';
waveform_metrics.score2 = score2(:,1:3)';
waveform_metrics.score3 = score3(:,1:3)';

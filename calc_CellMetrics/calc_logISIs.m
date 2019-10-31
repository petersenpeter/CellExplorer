function isi = calc_logISIs(spikes)
% Calculates the log distributed ISI of the spikes and displays them.

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 10-08-2019

figure, hold on, set(gca,'xscale','log')
xlabel('Time (s)'), ylabel('Rate (Hz)'), title('Log ISI distribution')
intervals = -3:0.04:1;
intervals2 = intervals(1:end-1)+.02;
isi = {};
isi.log10 = zeros(length(intervals2),size(spikes.times,2));
isi.log10_bins = 10.^intervals2';
for j = 1:size(spikes.times,2)
    ISIs = log10(diff(spikes.times{j}));
    [ISIlog,~] = histcounts(ISIs,intervals);
    isi.log10(:,j) = ISIlog./(diff(10.^intervals))/length(spikes.times{j});
    plot(isi.log10_bins,isi.log10(:,j))
    drawnow
end

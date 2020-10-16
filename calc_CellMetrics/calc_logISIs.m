function isi = calc_logISIs(times)
% Calculates the log distributed ISI of the spikes and displays them.
% 
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 16-06-2020

intervals = -3:0.04:1;
intervals2 = intervals(1:end-1)+.02;
isi = {};
isi.log10 = zeros(length(intervals2),size(times,2));
isi.log10_bins = 10.^intervals2';
for j = 1:size(times,2)
    ISIs = log10(diff(times{j}));
    [ISIlog,~] = histcounts(ISIs,intervals);
    isi.log10(:,j) = ISIlog./(diff(10.^intervals))/length(times{j});
end
fig = figure; hold on, set(gca,'xscale','log');
ax1 = gca;
xlabel(ax1,'Time (s)'), ylabel(ax1,'Occurrence'), title(ax1,'Log ISI distribution')
plot(ax1,isi.log10_bins,isi.log10.*(10.^intervals2)')

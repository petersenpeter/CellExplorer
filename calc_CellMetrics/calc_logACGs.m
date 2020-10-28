function acg = calc_logACGs(times)
% Calculates the log distributed ACG of the spikes and displays them.

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 09-08-2019

gcp;
intervals = -3:0.04:1;
intervals2 = intervals(1:end-1)+.02;
acg = {};
acg.log10 = zeros(length(intervals2),size(times,2));
acg.log10_bins = 10.^intervals2';
acg_log10 = zeros(size(times,2),length(intervals2));
parfor j = 1:size(times,2)
    ACGlog = zeros(1,length(intervals)-1);
    i = 1;
    test = 1;
    while test > 0
        ISIs = log10(times{j}(i+1:end)-times{j}(1:end-i));
        [N,~] = histcounts(ISIs,intervals);
        ACGlog = ACGlog+N;
        i = i+1;
        test = any(ISIs<intervals(end));
    end
    acg_log10(j,:) = ACGlog./(diff(10.^intervals))/length(times{j});
end
acg.log10 =  acg_log10';

fig = figure; hold on, set(gca,'xscale','log');
ax1 = gca;
xlabel(ax1,'Time (s)'), ylabel(ax1,'Rate (Hz)'), title(ax1,'log ACG distribution')
plot(ax1,acg.log10_bins,acg.log10)
title(ax1,'log ACG distribution')

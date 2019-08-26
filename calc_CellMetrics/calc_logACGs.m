function acg = calc_logACGs(spikes)
% Calculates the log distributed ACG of the spikes and displays them.

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 09-08-2019

figure, hold on, set(gca,'xscale','log')
xlabel('Time (s)'), ylabel('Rate (Hz)'), title('log ACG distribution')
intervals = -3:0.04:1;
intervals2 = intervals(1:end-1)+.02;
acg = {};
acg.log10 = zeros(length(intervals2),size(spikes.times,2));
acg.log10_bins = 10.^intervals2';
for j = 1:size(spikes.times,2)
    spikes_times = spikes.times{j};
    
    ACGlog = zeros(1,length(intervals)-1);
    i = 1;
    test = 1;
    while test > 0
        ISIs = log10(spikes_times(i+1:end)-spikes_times(1:end-i));
        [N,~] = histcounts(ISIs,intervals);
        ACGlog = ACGlog+N;
        i = i+1;
        test = any(ISIs<intervals(end));
    end
    acg.log10(:,j) = ACGlog./(diff(10.^intervals))/length(spikes.times{j});
    plot(acg.log10_bins,acg.log10(:,j))
    drawnow
end

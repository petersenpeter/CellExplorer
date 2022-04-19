% % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% CCG tutorial
%
% Show how to calculate the cross correlogram between two cells, in a user defined time intervals
% % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% Load spikes struct
% cd('your/basepath/')
spikes = loadSpikes;
spikes_restrict = {};

% Limit spike struct within a defined interval:
intervals = [0,10000; 11000,20000; 31000,80000]; % Three intervals

% Restricting spikes to intervals via cellfun
spikes_indices = cellfun(@(X) ce_InIntervals(X,intervals),spikes.times,'UniformOutput',false);
spikes_restrict.times =cellfun(@(X,Y) X(Y),spikes.times,spikes_indices,'UniformOutput',false);

% Generating spike indices matrix (input format of the CCG function below)
spikes_restrict.spindices = generateSpinDices(spikes_restrict.times);

% Calculate the CCG across all cells
binSize = 0.001; % 1ms bin size
duration = 0.1; % -50ms:50ms window
sr = spikes.sr; % Sampling rate of your recording
[ccg,t] = CCG(spikes_restrict.spindices(:,1),spikes_restrict.spindices(:,2),'binSize',binSize,'duration',duration,'Fs',1/sr);

figure, 
% Plotting the autocorrelogram (ACG) of the eight cell
subplot(2,1,1)
plot(t,ccg(:,8,8)), title('ASCG'), xlabel('Time (seconds)'), ylabel('Count')

% Plotting the cross correlogram (CCG) between a pair of cells
subplot(2,1,2)
plot(t,ccg(:,1,3)), title('CCG'), xlabel('Time (seconds)'), ylabel('Count')

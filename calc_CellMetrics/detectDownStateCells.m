function [meanCCG,tR,population_modIndex] = detectDownStateCells(spikes)
% Calculates the average CCG for each cell and determines their population modulation
% index by the ration of the CCG from t=-500ms to -450ms and +450ms to
% +500ms to the interval arounnd +-50ms

% By Peter Petersen
% Last edited: 07-07-2020

binSize = 0.01;  % in seconds (default: 5ms interval)
duration = 0.5; % in seconds (default: +-2500ms)

if ~isfield(spikes,'spindices')
    disp('Generating spindices')
    spikes.spindices = generateSpinDices(spikes.times);
end
[spiketimes,b] = sort(spikes.spindices(:,1));
spikeIDs = double(spikes.spindices(b,2));

% Generating CCG matrix
[ccgR1,tR] = CCG(spiketimes,spikeIDs,'binSize',binSize,'duration',duration);
meanCCG = mean(ccgR1,3);

disp('Detecting down-state cells')
if isfield(spikes,'sessionName') 
    figure('name',spikes.sessionName)
else
    figure
end
subplot(1,2,1)
plot(tR,meanCCG./mean(meanCCG)), title('Average CCG'),xlabel('Time (seconds)'), axis tight
subplot(1,2,2)
population_modIndex  = mean(meanCCG([21:31],:))./mean(meanCCG([1:5,47:51],:));
histogram(population_modIndex), title('Population modulation index'), xlabel('Modulation strength')

function calc_Burstiness_Mizuseki2012(units)
% Burstiness calculated by definition in Mizuseki et al., Hippocampus 2012
%
% By Peter Petersen
% petersen.peter@gmail.com

load('units.mat')
sr = 20000;
spikes = units(1).ts/sr;
ISI = diff(spikes);
bursts = find(ISI<0.006);
figure, plot(ISI(1:end-1),ISI(2:end),'.')

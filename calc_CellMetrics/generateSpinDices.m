function spindices = generateSpinDices(spike_times)
% Generates spindices matrics
% By Peter Petersen
% petersen.peter@gmail.com
% 18-06-2020

numcells = numel(spike_times);
for cc = 1:numcells
    groups{cc}=cc*ones(size(spike_times{cc}));
end

if numcells>0
    groups = cat(1,groups{:}); % from cell to array
    [alltimes,sortidx] = sort(cat(1,spike_times{:})); % Sorting spikes
    spindices = [alltimes groups(sortidx)]; % Combining spikes and sorted group ids
end

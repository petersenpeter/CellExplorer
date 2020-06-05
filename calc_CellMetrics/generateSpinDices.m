function spindices = generateSpinDices(spike_times)
% Generates spindices matrics
% By Peter Petersen
% petersen.peter@gmail.com
% 28-05-2020

numcells = numel(spike_times);
for cc = 1:numcells
    groups{cc}=cc*ones(size(spike_times{cc}));
end

if numcells>0
    alltimes = cat(1,spike_times{:}); 
    groups = cat(1,groups{:}); % from cell to array
    [alltimes,sortidx] = sort(alltimes); 
    groups = groups(sortidx); % sort both
    spindices = [alltimes groups];
end

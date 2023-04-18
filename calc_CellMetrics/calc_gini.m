function gini = calc_gini(bined_data)
% Calculates the gini coefficient
%
% bined_data = ones(1,100);     % Perfect equality: gini=0
% bined_data = [zeros(1,99) 1]; % Perfect inequality: gini~=1 (0.98 due to binning)

cum_firing1 = cumsum(sort(bined_data(:)));
cum_firing2 = cum_firing1/max(cum_firing1);
gini = 1-2*sum(cum_firing2)./(length(cum_firing2)+1);
function gini = calc_gini(bined_data)
% Calculates the gini coefficient
%
% bined_data = ones(1,100);     % Perfect equality: gini=0
% bined_data = [zeros(1,99) 1]; % Perfect inequality: gini~=1 (0.98 due to binning)

% Compatibility entry point; implementation: ce.metrics.calc_gini.
gini = ce.metrics.calc_gini(bined_data);
end

function y = nanUnique(x)
% Unique values exluding nans
y = unique(x);
y(isnan(y)) = [];
end
function varargout = withRandomSeed(seed, operation)
%WITHRANDOMSEED Isolate a stochastic operation from the caller's random stream.
previous = rng;
cleanup = onCleanup(@() rng(previous));
rng(seed,'twister');
[varargout{1:nargout}] = operation();
end

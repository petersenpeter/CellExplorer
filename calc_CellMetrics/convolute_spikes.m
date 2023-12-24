function [spikes_convolved,time_bins] = convolute_spikes(spikes, stepsize, convolution_points)
% Gaussian convolution of the spikes raster into continue rates 
% Inputs
%   spikes              % Spikes struct as defined by CellExplorer
%   stepsize            % step size of continues traces (in seconds)
%   convolution_points  % points of gaussian convolution (gausswin)
%
% Output
%   spikes_convolved : n x m matrix, n = number of time_bins, m = number of units

if nargin < 2
    % Setting default convolution points (steps, units of seconds)
    stepsize = 0.002; % Default: 2 ms
end
if nargin < 3
    % Setting default convolution points (steps)
    convolution_points = 50; % 50 bin steps
end
if ~isfield(spikes,'spindices')
    spikes.spindices = generateSpinDices(spikes.times);
end

% Generating continues representation of the raster actvity
time_bins = 0:stepsize:ceil(max(spikes.spindices(:,1)));
spikes_convolved = zeros(numel(time_bins),spikes.numcells);

for i = 1:spikes.numcells
    idx = round(spikes.times{i}/stepsize);
    spikes_convolved(idx,i) = 1;
    
    % Convoluting the spike times with a n points gaussian convolution
    spikes_convolved(:,i) = nanconv(spikes_convolved(:,i),gausswin(convolution_points)/sum(gausswin(convolution_points)),'edge');
end

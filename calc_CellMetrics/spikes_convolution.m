function [spikes_presentation,time_bins] = spikes_convolution(spikes, stepsize, convolution_points)
% Gaussian convolution of the spikes raster into continue rates 
% Inputs
%   spikes              % Spikes struct
%   stepsize            % step size of continues traces
%   convolution_points  % points of gaussian convolution (gausswin)
%
% Output
%   spikes_presentation_all : 

if nargin < 2
    % Setting default convolution points (steps)
    stepsize = 0.002;
end
if nargin < 3
    % Setting default convolution points (steps)
    convolution_points = 50;
end
if isfield(spikes,'spindices')
    spikes.spindices = generateSpinDices(spikes.times);
end

% Generating continues representation of the raster actvity
time_bins = 0:stepsize:ceil(max(spikes.spindices(:,1)));
spikes_presentation = zeros(numel(time_bins),spikes.numcells);

for i = 1:spikes.numcells
    idx = round(spikes.times{i}/stepsize);
    spikes_presentation(idx,i) = 1;
    
    % Convoluting the spike times with a n points gaussian convolution
    spikes_presentation(:,i) = nanconv(spikes_presentation(:,i),gausswin(convolution_points)/sum(gausswin(convolution_points)),'edge');
end

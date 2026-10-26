function output = loadStruct(dataName,datatype,varargin)
% Load event, manipulation, behavior data to appropiate .mat files
%
% Example calls
% trials = loadStruct('trials','behavior','session',session);
% spikes = loadStruct('spikes','cellinfo','session',session);
% cell_metrics = loadStruct('cell_metrics','cellinfo','session',session);
% ripples = loadStruct('ripples','events','session',session);

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated: 24-02-2020

% Compatibility entry point; implementation: ce.io.loadStruct.
output = ce.io.loadStruct(dataName, datatype, varargin{:});
end

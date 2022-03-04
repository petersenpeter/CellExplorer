function out = correlation_between_channels(varargin)
% This function is called from NeuroScope2 via the menu Analysis 

p = inputParser;

% The inputs are NeuroScope2 variables:
addParameter(p,'ephys',[],@isstruct); % UI: struct with UI elements and settings of NeuroScope2
addParameter(p,'UI',[],@isstruct); % ephys: Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
addParameter(p,'data',[],@isstruct); % data: contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
parse(p,varargin{:})

ephys = p.Results.ephys;
UI = p.Results.UI;

out = [];

% % % % % % % % % % % % % % % %
% Function below
% % % % % % % % % % % % % % % % 

% Correlation between channels
R = corrcoef(ephys.traces(:,UI.channelOrder));

figure
imagesc(R)
title('Correlation between channels')
xlabel('Displayed channel order'), ylabel('Displayed channel order')

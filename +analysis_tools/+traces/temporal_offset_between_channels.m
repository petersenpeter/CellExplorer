function out = temporal_offset_between_channels(varargin)
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

% Temporal offset between channels
delay_matrix = nan(numel(UI.channelOrder),numel(UI.channelOrder));
f_waitbar = waitbar(0,'Please wait...','Name','Temporal offset between channels');
for i = 1:numel(UI.channelOrder)
    if ~ishandle(f_waitbar)
        return
    end
    waitbar(i/numel(UI.channelOrder),f_waitbar,'Calculating the temporal offset between channels');
    for j = i:numel(UI.channelOrder)
        d = finddelay(ephys.traces(:,UI.channelOrder(i)),ephys.traces(:,UI.channelOrder(j)),size(ephys.traces,1)/2);
        delay_matrix(i,j) = d;
        delay_matrix(j,i) = -d;
    end
end
if ishandle(f_waitbar)
    close(f_waitbar)
end

figure
imagesc(delay_matrix)
title('Temporal offset between channels')
xlabel('Displayed channel order'), ylabel('Displayed channel order')

function out = RMS_noise_across_channels(varargin)
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

% Plots a figure with the RMS noise across channels

rms1 = rms(ephys.traces/(UI.settings.scalingFactor/1000000));
k_channels = 0;
fig1 = figure('name',['RMS across channels. Session: ', UI.data.basename],'Position',[50 50 1200 900],'visible','off');
ax1 = axes(fig1,'Color','k'); hold on, xlabel(ax1,'Sorted and filtered channels'), ylabel(ax1,['RMS (',char(181),'V)']), title(ax1,[' Session: ', UI.data.basename], 'interpreter','none')
for iShanks = UI.settings.electrodeGroupsToPlot
    channels = UI.channels{iShanks};
    [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
    channels = UI.channelOrder(ia);
    markerColor = UI.colors(iShanks,:);
    line(ax1,(1:numel(channels))+k_channels,rms1(channels), 'HitTest','off','Color', markerColor,'Marker','o','LineStyle','-','linewidth',1,'MarkerFaceColor',markerColor,'MarkerEdgeColor',markerColor)
    k_channels = k_channels + numel(channels);
end
axis tight
text(ax1,1,1,['Start time: ', num2str(UI.t0), ' sec, Duration: ', num2str(UI.settings.windowDuration), ' sec '],'FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','right','color',UI.settings.primaryColor,'Units','normalized')
movegui(fig1,'center'), set(fig1,'visible','on')

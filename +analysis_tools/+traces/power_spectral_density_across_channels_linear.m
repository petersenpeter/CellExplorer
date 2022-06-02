function out = power_spectral_density_across_channels_linear(varargin)
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

% Power spectral density across channels with linear bins

fig2 = figure('name',['Power spectral density. Session: ', UI.data.basename],'Position',[50 50 1200 900],'visible','off');
ax2 = axes(fig2,'YScale', 'log', 'XScale', 'log'); hold on, xlabel(ax2,'Frequency (Hz)'), ylabel(ax2,'Power spectral density'), title(ax2,[' Session: ', UI.data.basename], 'interpreter','none'), grid on

sr = ephys.sr; % Sampling rate
nfft = 2^nextpow2(size(ephys.traces,1));
psd1 = abs(fft(ephys.traces/(UI.settings.scalingFactor/1000000),nfft)).^2/size(ephys.traces,1)/sr; % compute the PSD and normalize
for iShanks = UI.settings.electrodeGroupsToPlot
    channels = UI.channels{iShanks};
    [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
    channels = UI.channelOrder(ia);
    markerColor = UI.colors(iShanks,:);
    line(ax2,[0:sr/(size(psd1,1)/2)/2:sr/2],psd1(1:size(psd1,1)/2+1,channels), 'HitTest','off','Color', markerColor*0.95,'Marker','none','LineStyle','-','linewidth',1)
end
axis tight
text(ax2,1,1,['Start time: ', num2str(UI.t0), ' sec, Duration: ', num2str(UI.settings.windowDuration), ' sec '],'FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','right','color','k','Units','normalized')
movegui(fig2,'center'), set(fig2,'visible','on')
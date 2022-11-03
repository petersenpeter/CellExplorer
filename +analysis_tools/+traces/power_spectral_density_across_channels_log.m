function out = power_spectral_density_across_channels_log(varargin)
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

% Power spectral density across channels with log bins
% Implementation: https://github.com/tobin/lpsd

N = size(ephys.traces,1);   % number of data points in the timeseries
sr = ephys.sr;              % sampling rate

fmin = sr/N;                % lowest frequency of interest
fmax = sr/2;                % highest frequency of interest
Jdes = 500;                 % desired number of points in the spectrum

Kdes = 50;                  % desired number of averages
Kmin = 2;                   % minimum number of averages

xi = 0.5;                   % fractional overlap

f_waitbar = waitbar(0,'Please wait...','Name','Power spectral density');
i_channel = 0;
X_all = [];
channels = [UI.channels{:}];

% Validating that Parallel Computing Toolbox is installed
parallel_toolbox_installed = isToolboxInstalled('Parallel Computing Toolbox');

% Will calculate the power spectral density in parallel if toolbox is installed (which is much faster), otherwise in a regular for loop.
if parallel_toolbox_installed
    waitbar(0,f_waitbar,'Please wait... Starting parallel pool...');
    gcp;
    waitbar(0.01,f_waitbar,'Calculating power spectral density across channels in parallel');
    ephys_traces = ephys.traces(:,channels)/(UI.settings.scalingFactor/1000000);
    parfor i = 1:numel(channels)
        [X, f, C] = lpsd(ephys_traces(:,i), @hanning, fmin, fmax, Jdes, Kdes, Kmin, sr, xi);
        X_all(:,i) = X .* C.PSD;
    end
    X_all(:,channels) = X_all;
    f = logspace(log10(fmin),log10(fmax),Jdes);
else
    for i = 1:numel(channels)
        i_channel = i_channel+1;
        if ~ishandle(f_waitbar)
            return
        end
        waitbar(i_channel/numel(channels),f_waitbar,'Generating power spectral density across channels');
        [X, f, C] = lpsd(ephys.traces(:,channels(i))/(UI.settings.scalingFactor/1000000), @hanning, fmin, fmax, Jdes, Kdes, Kmin, sr, xi);
        X_all(:,channels(i)) = X .* C.PSD;
    end
end
fig2 = figure('name',['Power spectral density. Session: ', UI.data.basename],'Position',[50 50 1200 900],'visible','off');
ax2 = axes(fig2, 'YScale', 'log', 'XScale', 'log'); hold on, xlabel(ax2,'Frequency (Hz)'), ylabel(ax2,'Power spectral density'), title(ax2,[' Session: ', UI.data.basename], 'interpreter','none'), grid on
for iShanks = UI.settings.electrodeGroupsToPlot
    channels = UI.channels{iShanks};
    [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
    channels = UI.channelOrder(ia);
    for i = 1:numel(channels)
        line(ax2,f, X_all(:,channels(i)), 'color', UI.colors(iShanks,:)*0.95, 'linewidth', 1, 'HitTest','off');
    end
end
if ishandle(f_waitbar)
    close(f_waitbar)
end
axis tight
text(ax2,1,1,['Start time: ', num2str(UI.t0), ' sec, Duration: ', num2str(UI.settings.windowDuration), ' sec '],'FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','right','color','k','Units','normalized')
movegui(fig2,'center'), set(fig2,'visible','on')

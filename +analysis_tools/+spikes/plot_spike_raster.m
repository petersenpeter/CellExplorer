function out = plot_spike_raster(varargin)
% This is a wrapper example file for NeuroScope2. 
% Use this wrapper example to make calls from NeuroScope to any other analysis that can be applied to the traces, raw data or any derived data types.
% This function can be called from NeuroScope2 via the menu Analysis 

p = inputParser;

% The inputs are NeuroScope2 variables:
addParameter(p,'ephys',[],@isstruct); % UI: struct with UI elements and settings of NeuroScope2
addParameter(p,'UI',[],@isstruct); % ephys: Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
addParameter(p,'data',[],@isstruct); % data: contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
parse(p,varargin{:})

UI = p.Results.UI;  
data = p.Results.data;

out = [];

% % % % % % % % % % % % % % % %
% Function content below
% % % % % % % % % % % % % % % % 

% This function generates a spike raster plot

if isfield(data,'spikes') && isfield(data.spikes,'spindices')
    figure, 
    line(data.spikes.spindices(:,1), data.spikes.spindices(:,2),'Marker',UI.settings.rasterMarker,'LineStyle','none','color','k', 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
    axis tight, xlabel('Time (sec)'), ylabel('Units'), title('Spike raster')
else
    msgbox('Load spikes data before plotting the raster.','NeuroScope2','help')
end
